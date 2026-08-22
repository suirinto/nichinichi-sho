alter table public.categories
  add constraint categories_user_name_unique
  unique (user_id, name);
