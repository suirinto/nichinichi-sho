alter table public.items
  enable row level security;

drop policy if exists "Users can read own items"
on public.items;

create policy "Users can read own items"
on public.items
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own items"
on public.items;

create policy "Users can insert own items"
on public.items
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own items"
on public.items;

create policy "Users can update own items"
on public.items
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own items"
on public.items;

create policy "Users can delete own items"
on public.items
for delete
to authenticated
using (auth.uid() = user_id);
