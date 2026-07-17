create extension if not exists pgcrypto;

create table if not exists public.admin_users (
 user_id uuid primary key references auth.users(id) on delete cascade,
 full_name text, created_at timestamptz default now()
);

create table if not exists public.rsvps (
 id uuid primary key default gen_random_uuid(),
 qr_token uuid not null unique default gen_random_uuid(),
 full_name text not null check(char_length(trim(full_name)) between 2 and 120),
 email text not null,
 phone text not null,
 attendance text not null check(attendance in ('attending','not_attending')),
 food_choice text,
 dietary_requirements text,
 drink_choice text,
 wine_preference text,
 plus_one boolean not null default false,
 plus_one_name text,
 message text,
 amount_due numeric(10,2) not null default 380.00,
 payment_status text not null default 'unpaid' check(payment_status in ('unpaid','part_paid','paid','waived')),
 payment_reference text,
 email_sent boolean not null default false,
 checked_in boolean not null default false,
 checked_in_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(attendance='not_attending' or nullif(trim(food_choice),'') is not null),
 check(attendance='not_attending' or nullif(trim(drink_choice),'') is not null)
);

create unique index if not exists rsvps_unique_email on public.rsvps(lower(email));
create index if not exists rsvps_created_idx on public.rsvps(created_at desc);

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path=public as $$begin new.updated_at=now(); return new; end$$;
drop trigger if exists rsvps_updated_at on public.rsvps;
create trigger rsvps_updated_at before update on public.rsvps for each row execute function public.set_updated_at();

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.admin_users where user_id=auth.uid())$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create or replace function public.verify_rsvp(p_token uuid)
returns table(full_name text,attendance text,food_choice text,dietary_requirements text,drink_choice text,wine_preference text,plus_one boolean,plus_one_name text,payment_status text,checked_in boolean,checked_in_at timestamptz,created_at timestamptz)
language sql stable security definer set search_path=public as $$
 select r.full_name,r.attendance,r.food_choice,r.dietary_requirements,r.drink_choice,r.wine_preference,r.plus_one,r.plus_one_name,r.payment_status,r.checked_in,r.checked_in_at,r.created_at from public.rsvps r where r.qr_token=p_token limit 1
$$;
revoke all on function public.verify_rsvp(uuid) from public;
grant execute on function public.verify_rsvp(uuid) to anon,authenticated;

create or replace function public.admin_check_in(p_rsvp_id uuid) returns void language plpgsql security definer set search_path=public as $$
begin if not public.is_admin() then raise exception 'Not authorised'; end if; update public.rsvps set checked_in=true,checked_in_at=now() where id=p_rsvp_id; end$$;
revoke all on function public.admin_check_in(uuid) from public;
grant execute on function public.admin_check_in(uuid) to authenticated;

alter table public.admin_users enable row level security;
alter table public.rsvps enable row level security;

drop policy if exists "admin self" on public.admin_users;
create policy "admin self" on public.admin_users for select to authenticated using(user_id=auth.uid());
drop policy if exists "public submit rsvp" on public.rsvps;
create policy "public submit rsvp" on public.rsvps for insert to anon,authenticated with check(amount_due=380 and payment_status='unpaid' and checked_in=false and email_sent=false);
drop policy if exists "admins read rsvps" on public.rsvps;
create policy "admins read rsvps" on public.rsvps for select to authenticated using(public.is_admin());
drop policy if exists "admins update rsvps" on public.rsvps;
create policy "admins update rsvps" on public.rsvps for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "admins delete rsvps" on public.rsvps;
create policy "admins delete rsvps" on public.rsvps for delete to authenticated using(public.is_admin());

grant insert on public.rsvps to anon,authenticated;
grant select,update,delete on public.rsvps to authenticated;
grant select on public.admin_users to authenticated;

-- After creating an admin user in Authentication, run:
-- insert into public.admin_users(user_id,full_name) values('AUTH-USER-UUID','Nico Event Admin');
