alter table public.categories
  enable row level security;

drop policy if exists "Users can read own categories"
on public.categories;

create policy "Users can read own categories"
on public.categories
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own categories"
on public.categories;

create policy "Users can insert own categories"
on public.categories
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own categories"
on public.categories;

create policy "Users can update own categories"
on public.categories
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own categories"
on public.categories;

create policy "Users can delete own categories"
on public.categories
for delete
to authenticated
using (auth.uid() = user_id);
