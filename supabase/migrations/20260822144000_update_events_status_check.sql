alter table public.events
  drop constraint events_status_check;

alter table public.events
  add constraint events_status_check
  check (
    status = any (
      array[
        'scheduled'::text,
        'in_progress'::text,
        'completed'::text,
        'cancelled'::text,
        'skipped'::text
      ]
    )
  );
