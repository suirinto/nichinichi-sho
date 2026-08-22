alter table public.items
  add constraint items_user_category_name_unique
  unique (user_id, category_id, name);
