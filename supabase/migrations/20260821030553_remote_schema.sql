set local check_function_bodies = off;

alter table "public"."users"
  enable row level security;

create or replace function public.handle_new_user()
  returns trigger
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
begin
  insert into public.users (
    id,
    display_name,
    created_at,
    updated_at
  )
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    ),
    now(),
    now()
  )
  on conflict (id) do nothing;

  return new;
end;
$function$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

create policy "Users can read own profile" on "public"."users"
  for select
  to "authenticated"
  using ((auth.uid() = id));

grant execute on function "public"."handle_new_user"() to public, "anon", "authenticated", "postgres", "service_role";

