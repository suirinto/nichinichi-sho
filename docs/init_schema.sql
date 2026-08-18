-- =========================================================
-- 日々抄 / 初期DB構築SQL
-- PostgreSQL / Supabase
-- =========================================================

-- ---------------------------------------------------------
-- 1. users
-- Supabase Auth のユーザーと紐付ける
-- ---------------------------------------------------------

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- 2. daily_records
-- 1日につき1件の基本体調記録
-- ---------------------------------------------------------

create table public.daily_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  record_date date not null,
  temperature numeric(4,2),
  condition_score smallint,
  sleep_minutes integer,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint daily_records_user_date_unique
    unique (user_id, record_date),

  constraint daily_records_condition_score_check
    check (condition_score between 0 and 10)
);

-- ---------------------------------------------------------
-- 3. symptom_definitions
-- 症状マスタ
-- ---------------------------------------------------------

create table public.symptom_definitions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- 4. daily_record_symptoms
-- 日次記録と症状の多対多
-- ---------------------------------------------------------

create table public.daily_record_symptoms (
  daily_record_id uuid not null
    references public.daily_records(id) on delete cascade,

  symptom_id uuid not null
    references public.symptom_definitions(id) on delete cascade,

  primary key (daily_record_id, symptom_id)
);

-- ---------------------------------------------------------
-- 5. extra_field_definitions
-- 「その他の記録」の項目定義
-- ---------------------------------------------------------

create table public.extra_field_definitions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  field_type text not null,
  unit text,
  options jsonb,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- 6. daily_extra_values
-- 「その他の記録」の実値
-- ---------------------------------------------------------

create table public.daily_extra_values (
  id uuid primary key default gen_random_uuid(),

  daily_record_id uuid not null
    references public.daily_records(id) on delete cascade,

  field_definition_id uuid not null
    references public.extra_field_definitions(id) on delete cascade,

  value jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint daily_extra_values_record_field_unique
    unique (daily_record_id, field_definition_id)
);

-- ---------------------------------------------------------
-- 7. categories
-- 運動 / ケア / 活動 / 美容 / 医療など
-- ---------------------------------------------------------

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- 8. items
-- カテゴリ配下の項目
-- ---------------------------------------------------------

create table public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,

  category_id uuid not null
    references public.categories(id) on delete restrict,

  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- 9. events
-- UI上の「できごと」本体
-- ---------------------------------------------------------

create table public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,

  item_id uuid not null
    references public.items(id) on delete restrict,

  happened_on date not null,
  start_at timestamptz,
  end_at timestamptz,
  duration_minutes integer,

  pre_memo text,
  post_memo text,

  status text not null default 'scheduled',
  source text not null default 'manual',

  google_calendar_id text,
  google_event_id text,
  google_event_label_id text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint events_status_check
    check (
      status in (
        'scheduled',
        'completed',
        'cancelled',
        'skipped'
      )
    ),

  constraint events_source_check
    check (
      source in (
        'manual',
        'google_calendar'
      )
    ),

  constraint events_google_event_unique
    unique (
      user_id,
      google_calendar_id,
      google_event_id
    )
);

-- ---------------------------------------------------------
-- 10. google_label_mappings
-- Googleカレンダーのイベントラベルと項目の対応
-- ---------------------------------------------------------

create table public.google_label_mappings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,

  google_calendar_id text not null,
  google_event_label_id text not null,
  google_event_label_name text,

  item_id uuid not null
    references public.items(id) on delete cascade,

  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint google_label_mappings_unique
    unique (
      user_id,
      google_calendar_id,
      google_event_label_id
    )
);

-- ---------------------------------------------------------
-- 11. google_sync_state
-- Googleカレンダー差分同期状態
-- ---------------------------------------------------------

create table public.google_sync_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,

  google_calendar_id text not null,
  sync_token text,
  last_synced_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint google_sync_state_unique
    unique (
      user_id,
      google_calendar_id
    )
);

-- ---------------------------------------------------------
-- 12. settings
-- アプリ設定
-- ---------------------------------------------------------

create table public.settings (
  user_id uuid primary key
    references public.users(id) on delete cascade,

  timezone text not null default 'Asia/Tokyo',
  day_start_hour smallint not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint settings_day_start_hour_check
    check (day_start_hour between 0 and 23)
);

-- ---------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------

create index daily_records_user_date_idx
  on public.daily_records (user_id, record_date desc);

create index events_user_happened_on_idx
  on public.events (user_id, happened_on desc);

create index events_user_item_happened_on_idx
  on public.events (user_id, item_id, happened_on desc);

create index events_user_status_happened_on_idx
  on public.events (user_id, status, happened_on);

create index google_label_mappings_lookup_idx
  on public.google_label_mappings (
    user_id,
    google_calendar_id,
    google_event_label_id
  );
