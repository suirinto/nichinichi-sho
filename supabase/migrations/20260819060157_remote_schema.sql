alter default privileges for role "postgres" in schema "public" revoke all on sequences from "anon";

alter default privileges for role "postgres" in schema "public" revoke all on sequences from "authenticated";

alter default privileges for role "postgres" in schema "public" revoke all on sequences from "service_role";

alter default privileges for role "postgres" in schema "public" revoke all on tables from "anon";

alter default privileges for role "postgres" in schema "public" revoke all on tables from "authenticated";

alter default privileges for role "postgres" in schema "public" revoke all on tables from "service_role";

create table "public"."categories" (
  "id"         uuid                     not null default gen_random_uuid(),
  "user_id"    uuid                     not null,
  "name"       text                     not null,
  "sort_order" integer                  not null default 0,
  "is_active"  boolean                  not null default true,
  "created_at" timestamp with time zone not null default now(),
  "updated_at" timestamp with time zone not null default now(),
  constraint "categories_pkey" primary key (id)
);

create table "public"."daily_extra_values" (
  "id"                  uuid                     not null default gen_random_uuid(),
  "daily_record_id"     uuid                     not null,
  "field_definition_id" uuid                     not null,
  "value"               jsonb,
  "created_at"          timestamp with time zone not null default now(),
  "updated_at"          timestamp with time zone not null default now(),
  constraint "daily_extra_values_pkey" primary key (id),
  constraint "daily_extra_values_record_field_unique" unique (daily_record_id, field_definition_id)
);

create table "public"."daily_record_symptoms" (
  "daily_record_id" uuid not null,
  "symptom_id"      uuid not null,
  constraint "daily_record_symptoms_pkey" primary key (daily_record_id, symptom_id)
);

create table "public"."daily_records" (
  "id"              uuid                     not null default gen_random_uuid(),
  "user_id"         uuid                     not null,
  "record_date"     date                     not null,
  "temperature"     numeric(4,2),
  "condition_score" smallint,
  "sleep_minutes"   integer,
  "memo"            text,
  "created_at"      timestamp with time zone not null default now(),
  "updated_at"      timestamp with time zone not null default now(),
  constraint "daily_records_condition_score_check" check (((condition_score >= 0) AND (condition_score <= 10))),
  constraint "daily_records_pkey" primary key (id),
  constraint "daily_records_user_date_unique" unique (user_id, record_date)
);

create table "public"."events" (
  "id"                    uuid                     not null default gen_random_uuid(),
  "user_id"               uuid                     not null,
  "item_id"               uuid                     not null,
  "happened_on"           date                     not null,
  "start_at"              timestamp with time zone,
  "end_at"                timestamp with time zone,
  "duration_minutes"      integer,
  "pre_memo"              text,
  "post_memo"             text,
  "status"                text                     not null default 'scheduled'::text,
  "source"                text                     not null default 'manual'::text,
  "google_calendar_id"    text,
  "google_event_id"       text,
  "google_event_label_id" text,
  "created_at"            timestamp with time zone not null default now(),
  "updated_at"            timestamp with time zone not null default now(),
  constraint "events_google_event_unique" unique (user_id, google_calendar_id, google_event_id),
  constraint "events_pkey" primary key (id),
  constraint "events_source_check" check ((source = ANY (ARRAY['manual'::text, 'google_calendar'::text]))),
  constraint "events_status_check" check ((status = ANY (ARRAY['scheduled'::text, 'completed'::text, 'cancelled'::text, 'skipped'::text])))
);

create table "public"."extra_field_definitions" (
  "id"         uuid                     not null default gen_random_uuid(),
  "user_id"    uuid                     not null,
  "name"       text                     not null,
  "field_type" text                     not null,
  "unit"       text,
  "options"    jsonb,
  "sort_order" integer                  not null default 0,
  "is_active"  boolean                  not null default true,
  "created_at" timestamp with time zone not null default now(),
  "updated_at" timestamp with time zone not null default now(),
  constraint "extra_field_definitions_pkey" primary key (id)
);

create table "public"."google_label_mappings" (
  "id"                      uuid                     not null default gen_random_uuid(),
  "user_id"                 uuid                     not null,
  "google_calendar_id"      text                     not null,
  "google_event_label_id"   text                     not null,
  "google_event_label_name" text,
  "item_id"                 uuid                     not null,
  "is_active"               boolean                  not null default true,
  "created_at"              timestamp with time zone not null default now(),
  "updated_at"              timestamp with time zone not null default now(),
  constraint "google_label_mappings_pkey" primary key (id),
  constraint "google_label_mappings_unique" unique (user_id, google_calendar_id, google_event_label_id)
);

create table "public"."google_sync_state" (
  "id"                 uuid                     not null default gen_random_uuid(),
  "user_id"            uuid                     not null,
  "google_calendar_id" text                     not null,
  "sync_token"         text,
  "last_synced_at"     timestamp with time zone,
  "created_at"         timestamp with time zone not null default now(),
  "updated_at"         timestamp with time zone not null default now(),
  constraint "google_sync_state_pkey" primary key (id),
  constraint "google_sync_state_unique" unique (user_id, google_calendar_id)
);

create table "public"."items" (
  "id"          uuid                     not null default gen_random_uuid(),
  "user_id"     uuid                     not null,
  "category_id" uuid                     not null,
  "name"        text                     not null,
  "sort_order"  integer                  not null default 0,
  "is_active"   boolean                  not null default true,
  "created_at"  timestamp with time zone not null default now(),
  "updated_at"  timestamp with time zone not null default now(),
  constraint "items_pkey" primary key (id)
);

create table "public"."settings" (
  "user_id"        uuid                     not null,
  "timezone"       text                     not null default 'Asia/Tokyo'::text,
  "day_start_hour" smallint                 not null default 0,
  "created_at"     timestamp with time zone not null default now(),
  "updated_at"     timestamp with time zone not null default now(),
  constraint "settings_day_start_hour_check" check (((day_start_hour >= 0) AND (day_start_hour <= 23))),
  constraint "settings_pkey" primary key (user_id)
);

create table "public"."symptom_definitions" (
  "id"         uuid                     not null default gen_random_uuid(),
  "user_id"    uuid                     not null,
  "name"       text                     not null,
  "sort_order" integer                  not null default 0,
  "is_active"  boolean                  not null default true,
  "created_at" timestamp with time zone not null default now(),
  "updated_at" timestamp with time zone not null default now(),
  constraint "symptom_definitions_pkey" primary key (id)
);

create table "public"."users" (
  "id"           uuid                     not null,
  "display_name" text,
  "created_at"   timestamp with time zone not null default now(),
  "updated_at"   timestamp with time zone not null default now(),
  constraint "users_pkey" primary key (id)
);

alter table "public"."daily_extra_values"
  add constraint "daily_extra_values_daily_record_id_fkey" foreign key (daily_record_id) references public.daily_records(id) on delete cascade;

alter table "public"."daily_record_symptoms"
  add constraint "daily_record_symptoms_daily_record_id_fkey" foreign key (daily_record_id) references public.daily_records(id) on delete cascade;

alter table "public"."daily_extra_values"
  add constraint "daily_extra_values_field_definition_id_fkey" foreign key (field_definition_id) references public.extra_field_definitions(id) on delete cascade;

alter table "public"."items"
  add constraint "items_category_id_fkey" foreign key (category_id) references public.categories(id) on delete restrict;

alter table "public"."events"
  add constraint "events_item_id_fkey" foreign key (item_id) references public.items(id) on delete restrict;

alter table "public"."google_label_mappings"
  add constraint "google_label_mappings_item_id_fkey" foreign key (item_id) references public.items(id) on delete cascade;

alter table "public"."daily_record_symptoms"
  add constraint "daily_record_symptoms_symptom_id_fkey" foreign key (symptom_id) references public.symptom_definitions(id) on delete cascade;

alter table "public"."users"
  add constraint "users_id_fkey" foreign key (id) references auth.users(id) on delete cascade;

alter table "public"."categories"
  add constraint "categories_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."daily_records"
  add constraint "daily_records_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."events"
  add constraint "events_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."extra_field_definitions"
  add constraint "extra_field_definitions_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."google_label_mappings"
  add constraint "google_label_mappings_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."google_sync_state"
  add constraint "google_sync_state_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."items"
  add constraint "items_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."settings"
  add constraint "settings_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

alter table "public"."symptom_definitions"
  add constraint "symptom_definitions_user_id_fkey" foreign key (user_id) references public.users(id) on delete cascade;

create index daily_records_user_date_idx on public.daily_records using btree (user_id, record_date desc);

create index events_user_happened_on_idx on public.events using btree (user_id, happened_on desc);

create index events_user_item_happened_on_idx on public.events using btree (user_id, item_id, happened_on desc);

create index events_user_status_happened_on_idx on public.events using btree (user_id, status, happened_on);

create index google_label_mappings_lookup_idx on public.google_label_mappings using btree (user_id, google_calendar_id, google_event_label_id);

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."categories" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."daily_extra_values" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."daily_record_symptoms" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."daily_records" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."events" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."extra_field_definitions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."google_label_mappings" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."google_sync_state" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."items" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."settings" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."symptom_definitions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."users" to "anon", "authenticated", "postgres", "service_role";

alter default privileges for role "postgres" in schema "public" grant select, update, usage on sequences to "anon";

alter default privileges for role "postgres" in schema "public" grant select, update, usage on sequences to "authenticated";

alter default privileges for role "postgres" in schema "public" grant select, update, usage on sequences to "service_role";

alter default privileges for role "postgres" in schema "public" grant execute on FUNCTIONS to "anon";

alter default privileges for role "postgres" in schema "public" grant execute on FUNCTIONS to "authenticated";

alter default privileges for role "postgres" in schema "public" grant execute on FUNCTIONS to "service_role";

alter default privileges for role "postgres" in schema "public" grant delete, insert, maintain, references, select, trigger, truncate, update on tables to "anon";

alter default privileges for role "postgres" in schema "public" grant delete, insert, maintain, references, select, trigger, truncate, update on tables to "authenticated";

alter default privileges for role "postgres" in schema "public" grant delete, insert, maintain, references, select, trigger, truncate, update on tables to "service_role";

