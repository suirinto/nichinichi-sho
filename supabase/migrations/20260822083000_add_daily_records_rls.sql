alter table public.daily_records
  enable row level security;

drop policy if exists "Users can read own daily records"
on public.daily_records;

create policy "Users can read own daily records"
on public.daily_records
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own daily records"
on public.daily_records;

create policy "Users can insert own daily records"
on public.daily_records
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own daily records"
on public.daily_records;

create policy "Users can update own daily records"
on public.daily_records
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own daily records"
on public.daily_records;

create policy "Users can delete own daily records"
on public.daily_records
for delete
to authenticated
using (auth.uid() = user_id);
