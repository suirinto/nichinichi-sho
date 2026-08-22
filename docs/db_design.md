# すくう DB設計 v2

## 1. 方針

- PostgreSQL / Supabase を前提とする
- 自分専用アプリとして開始するが、認証・RLSを使えるよう主要テーブルに `user_id` を持たせる
- カテゴリ・項目・症状・その他の記録項目は、後から追加・削除・名称変更できる構造にする
- Googleカレンダーのタイトル文字列ではなく、カレンダーID・イベントID・イベントラベルIDで連携する
- 削除済みのカテゴリや項目を過去記録から消さないため、原則として物理削除ではなく `is_active` を使う
- 分析用の集計テーブルはMVPでは持たず、まずは通常テーブルから集計する
- UIでは「できごと」と表現するが、DB・コード上では一般的な `event` / `events` を使う
- DBスキーマの正本は `supabase/migrations/` とする

---

## 2. テーブル一覧

1. `users`
2. `daily_records`
3. `symptom_definitions`
4. `daily_record_symptoms`
5. `extra_field_definitions`
6. `daily_extra_values`
7. `categories`
8. `items`
9. `events`
10. `google_label_mappings`
11. `google_sync_state`
12. `settings`

---

## 3. users

Supabase Auth のユーザーと紐付ける。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | `auth.users.id` と同じID |
| display_name | text | 表示名 |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `auth.users(id)` を参照する
- Authユーザー削除時は `ON DELETE CASCADE`
- `created_at` / `updated_at` は `NOT NULL`
- `created_at` / `updated_at` の初期値は `now()`

---

## 4. daily_records

1日につき1件の基本体調記録。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | レコードID |
| user_id | uuid FK | ユーザー |
| record_date | date | 記録日 |
| temperature | numeric(4,2) | 体温 |
| condition_score | smallint | 体調点数 0〜10 |
| sleep_minutes | integer | 睡眠時間（分） |
| memo | text | 日次メモ |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `record_date` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `unique(user_id, record_date)`
- `condition_score between 0 and 10`
- `created_at` / `updated_at` の初期値は `now()`

---

## 5. symptom_definitions

症状マスタ。自由に追加・名称変更できる。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | 症状ID |
| user_id | uuid FK | ユーザー |
| name | text | 頭痛、熱っぽい、首・肩など |
| sort_order | integer | 表示順 |
| is_active | boolean | 使用中か |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `name` / `sort_order` / `is_active` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `sort_order` の初期値は `0`
- `is_active` の初期値は `true`
- `created_at` / `updated_at` の初期値は `now()`

---

## 6. daily_record_symptoms

日次記録と症状の多対多。

| カラム | 型 | 内容 |
|---|---|---|
| daily_record_id | uuid FK | 日次記録 |
| symptom_id | uuid FK | 症状 |

### 制約・補足

- 主キーは `(daily_record_id, symptom_id)`
- 両カラムとも `NOT NULL`
- `daily_record_id` は `daily_records(id)` を参照し、日次記録削除時は `ON DELETE CASCADE`
- `symptom_id` は `symptom_definitions(id)` を参照し、症状定義削除時は `ON DELETE CASCADE`

---

## 7. extra_field_definitions

「その他の記録」の項目定義。

例:
- お通じ
- 体重
- 血圧
- 将来追加する任意項目

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | 項目ID |
| user_id | uuid FK | ユーザー |
| name | text | 項目名 |
| field_type | text | `select` / `number` / `text` / `blood_pressure` 等 |
| unit | text | kg、mmHgなど |
| options | jsonb | 選択肢 |
| sort_order | integer | 表示順 |
| is_active | boolean | 使用中か |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `name` / `field_type` / `sort_order` / `is_active` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `sort_order` の初期値は `0`
- `is_active` の初期値は `true`
- `created_at` / `updated_at` の初期値は `now()`

### お通じの初期設定例

```json
["なし", "硬め", "普通", "軟らかめ", "下痢"]
```

---

## 8. daily_extra_values

「その他の記録」の実値。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | レコードID |
| daily_record_id | uuid FK | 日次記録 |
| field_definition_id | uuid FK | 項目定義 |
| value | jsonb | 実際の値 |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `daily_record_id` / `field_definition_id` / `created_at` / `updated_at` は `NOT NULL`
- `daily_record_id` は `daily_records(id)` を参照し、日次記録削除時は `ON DELETE CASCADE`
- `field_definition_id` は `extra_field_definitions(id)` を参照し、項目定義削除時は `ON DELETE CASCADE`
- `unique(daily_record_id, field_definition_id)`
- `created_at` / `updated_at` の初期値は `now()`

---

## 9. categories

「運動」「ケア」「活動」「美容」「医療」など。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | カテゴリID |
| user_id | uuid FK | ユーザー |
| name | text | カテゴリ名 |
| sort_order | integer | 表示順 |
| is_active | boolean | 使用中か |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `name` / `sort_order` / `is_active` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `sort_order` の初期値は `0`
- `is_active` の初期値は `true`
- `created_at` / `updated_at` の初期値は `now()`

---

## 10. items

カテゴリ配下の項目。

例:
- 運動 > ピラティス
- 活動 > チェロ
- ケア > 全身ケア（インディバ等）

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | 項目ID |
| user_id | uuid FK | ユーザー |
| category_id | uuid FK | カテゴリ |
| name | text | 項目名 |
| sort_order | integer | 表示順 |
| is_active | boolean | 使用中か |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `category_id` / `name` / `sort_order` / `is_active` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `category_id` は `categories(id)` を参照し、参照中カテゴリの削除は `ON DELETE RESTRICT`
- `sort_order` の初期値は `0`
- `is_active` の初期値は `true`
- `created_at` / `updated_at` の初期値は `now()`

---

## 11. events

UI上の「できごと」本体。

Googleカレンダー由来でも、アプリ内で直接追加したものでも、最終的にはこのテーブルで統一して扱う。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | できごとID |
| user_id | uuid FK | ユーザー |
| item_id | uuid FK | 項目 |
| happened_on | date | 日付 |
| start_at | timestamptz | 開始日時 |
| end_at | timestamptz | 終了日時 |
| duration_minutes | integer | 実施時間（分） |
| pre_memo | text | 事前メモ |
| post_memo | text | 実施メモ |
| status | text | ステータス |
| source | text | 登録元 |
| google_calendar_id | text | GoogleカレンダーID |
| google_event_id | text | GoogleイベントID |
| google_event_label_id | text | GoogleイベントラベルID |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `item_id` / `happened_on` / `status` / `source` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `item_id` は `items(id)` を参照し、参照中項目の削除は `ON DELETE RESTRICT`
- `status` は `scheduled` / `in_progress` / `completed` / `cancelled` / `skipped`
- `status` の初期値は `scheduled`
- `start_at` / `end_at` はイベントの現在の開始・終了日時を表す
- `duration_minutes` は実績時間として手入力可能
- `duration_minutes` 未入力時は `start_at` と `end_at` から算出可能
- `source` は `manual` / `google_calendar`
- Google由来の場合は `unique(user_id, google_calendar_id, google_event_id)`
- Googleカレンダー側で予定時刻やタイトルを変更しても、`google_event_id` で同一予定として追従する
- `created_at` / `updated_at` の初期値は `now()`

---

## 12. google_label_mappings

Googleカレンダーのイベントラベルと「すくう」の項目を紐付ける。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | マッピングID |
| user_id | uuid FK | ユーザー |
| google_calendar_id | text | GoogleカレンダーID |
| google_event_label_id | text | GoogleイベントラベルID |
| google_event_label_name | text | 表示確認用ラベル名 |
| item_id | uuid FK | 紐付く「すくう」の項目 |
| is_active | boolean | 使用中か |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `google_calendar_id` / `google_event_label_id` / `item_id` / `is_active` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `item_id` は `items(id)` を参照し、項目削除時は `ON DELETE CASCADE`
- `unique(user_id, google_calendar_id, google_event_label_id)`
- `is_active` の初期値は `true`
- `created_at` / `updated_at` の初期値は `now()`

### 方針

ラベル名は表示用。
判定には必ず `google_event_label_id` を使う。

---

## 13. google_sync_state

Googleカレンダーの差分同期状態を保持する。

| カラム | 型 | 内容 |
|---|---|---|
| id | uuid PK | レコードID |
| user_id | uuid FK | ユーザー |
| google_calendar_id | text | 対象カレンダーID |
| sync_token | text | 差分同期用トークン |
| last_synced_at | timestamptz | 最終同期日時 |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `id` は `gen_random_uuid()` で自動採番
- `user_id` / `google_calendar_id` / `created_at` / `updated_at` は `NOT NULL`
- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `unique(user_id, google_calendar_id)`
- `created_at` / `updated_at` の初期値は `now()`

---

## 14. settings

アプリ設定。

| カラム | 型 | 内容 |
|---|---|---|
| user_id | uuid PK/FK | ユーザー |
| timezone | text | タイムゾーン |
| day_start_hour | smallint | 1日の切り替え時刻 |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足

- `user_id` は `users(id)` を参照し、ユーザー削除時は `ON DELETE CASCADE`
- `timezone` / `day_start_hour` / `created_at` / `updated_at` は `NOT NULL`
- `timezone` の初期値は `Asia/Tokyo`
- `day_start_hour` の初期値は `0`
- `day_start_hour between 0 and 23`
- `created_at` / `updated_at` の初期値は `now()`

---

## 15. リレーション概要

```text
users
 ├─ daily_records
 │    ├─ daily_record_symptoms ─ symptom_definitions
 │    └─ daily_extra_values ─ extra_field_definitions
 │
 ├─ categories
 │    └─ items
 │         ├─ events
 │         └─ google_label_mappings
 │
 ├─ google_sync_state
 └─ settings
```

---

## 16. 主なインデックス

- `daily_records(user_id, record_date desc)`
- `events(user_id, happened_on desc)`
- `events(user_id, item_id, happened_on desc)`
- `events(user_id, status, happened_on)`
- `google_label_mappings(user_id, google_calendar_id, google_event_label_id)`

---

## 17. DB実装方針

実装時は、以下を原則とする。

- UUID主キーは `gen_random_uuid()` により自動採番する
- `users.id` は例外として `auth.users.id` と同じIDを使用する
- `created_at` / `updated_at` は `default now()` を設定する
- 必須項目には `NOT NULL` 制約を付与する
- `sort_order` は `default 0`
- `is_active` は `default true`
- 列挙値（例: `status`、`source`）は `CHECK` 制約で保証する
- 外部キーは用途に応じて `ON DELETE CASCADE` または `ON DELETE RESTRICT` を設定する
- インデックスはマイグレーションで管理する
- DBスキーマの正本は `supabase/migrations/` とする
- RLSは認証実装後に有効化し、基本ポリシーは `auth.uid() = user_id` とする

---

## 18. MVP時点での考え方

- DBは拡張可能にするが、UIでは必要な項目だけ見せる
- 1人利用でも `user_id` を持たせ、Supabase Auth / RLSの土台にする
- Googleカレンダー由来のできごとも `events` に統合する
- 手動追加とGoogle連携で、履歴・分析ロジックを分けない
- 集計テーブルはMVPでは作らない
- データ量が増えたら Materialized View や集計テーブルを追加する
