# すくう DB設計 v2

## 1. 方針

- PostgreSQL / Supabase を前提とする
- 自分専用アプリとして開始するが、認証・RLSを使えるよう主要テーブルに `user_id` を持たせる
- カテゴリ・項目・症状・その他の記録項目は、後から追加・削除・名称変更できる構造にする
- Googleカレンダーのタイトル文字列ではなく、カレンダーID・イベントID・イベントラベルIDで連携する
- 削除済みのカテゴリや項目を過去記録から消さないため、原則として物理削除ではなく `is_active` を使う
- 分析用の集計テーブルはMVPでは持たず、まずは通常テーブルから集計する
- UIでは「できごと」と表現するが、DB・コード上では一般的な `event` / `events` を使う

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

### 制約
- `unique(user_id, record_date)`
- `condition_score between 0 and 10`

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

---

## 6. daily_record_symptoms

日次記録と症状の多対多。

| カラム | 型 | 内容 |
|---|---|---|
| daily_record_id | uuid FK | 日次記録 |
| symptom_id | uuid FK | 症状 |

### 主キー
- `(daily_record_id, symptom_id)`

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

### 制約
- `unique(daily_record_id, field_definition_id)`

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
| status | text | `scheduled` / `completed` / `cancelled` / `skipped` |
| source | text | `manual` / `google_calendar` |
| google_calendar_id | text | GoogleカレンダーID |
| google_event_id | text | GoogleイベントID |
| google_event_label_id | text | GoogleイベントラベルID |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

### 制約・補足
- Google由来の場合:
  `unique(user_id, google_calendar_id, google_event_id)`
- `duration_minutes` は実績として手入力可能
- 未入力時は `start_at` と `end_at` から算出可能
- Googleカレンダー側で予定時刻やタイトルを変更しても、`google_event_id` で同一予定として追従する

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

### 制約
- `unique(user_id, google_calendar_id, google_event_label_id)`

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

### 制約
- `unique(user_id, google_calendar_id)`

---

## 14. settings

アプリ設定。

| カラム | 型 | 内容 |
|---|---|---|
| user_id | uuid PK/FK | ユーザー |
| timezone | text | 初期値 `Asia/Tokyo` |
| day_start_hour | smallint | 1日の切り替え時刻。初期値 0 |
| created_at | timestamptz | 作成日時 |
| updated_at | timestamptz | 更新日時 |

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

## 17. MVP時点での考え方

- DBは拡張可能にするが、UIでは必要な項目だけ見せる
- 1人利用でも `user_id` を持たせ、Supabase Auth / RLSの土台にする
- Googleカレンダー由来のできごとも `events` に統合する
- 手動追加とGoogle連携で、履歴・分析ロジックを分けない
- 集計テーブルはMVPでは作らない
- データ量が増えたら Materialized View や集計テーブルを追加する
