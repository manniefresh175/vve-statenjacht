-- =====================================================================
--  VVE Statenjacht – database-inrichting voor Supabase
--  Plak dit hele script in Supabase: SQL Editor → New query → Run.
--  Je kunt het één keer uitvoeren. (Nog een keer uitvoeren geeft fouten
--  omdat de tabellen dan al bestaan.)
-- =====================================================================

-- ---------- Gebruikers en rollen ----------
create table public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  email       text,
  naam        text,
  rol         text not null default 'lezer' check (rol in ('admin','lezer')),
  aangemaakt  timestamptz not null default now()
);

-- Is de ingelogde gebruiker beheerder?
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and rol = 'admin');
$$;

-- Elke nieuwe gebruiker krijgt automatisch een profiel met rol 'lezer'
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, naam) values (new.id, new.email, split_part(new.email, '@', 1));
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- MJOP ----------
create table public.onderdelen (
  id          text primary key,
  naam        text not null,
  categorie   text,
  element     text,
  locatie     text,
  code        text,
  hoeveelheid text,
  bedrag      numeric not null default 0,
  cyclus      integer not null default 0,      -- 0 = eenmalig
  eerste      integer,                         -- jaar van eerste uitvoering
  jaren       jsonb,                           -- vaste bedragen per jaar (optioneel)
  bron        text,
  bijgewerkt  timestamptz not null default now()
);

create table public.plan (
  id            integer primary key default 1 check (id = 1),   -- precies één rij
  startjaar     integer not null,
  looptijd      integer not null,
  indexatie     numeric not null default 0,
  beginsaldo    numeric not null default 0,
  reservering   numeric not null default 0,
  reserveringen jsonb not null default '{}'::jsonb
);

create table public.historie (
  id           bigint generated always as identity primary key,
  tijd         timestamptz not null default now(),
  wie          uuid references auth.users on delete set null,
  wie_naam     text,
  sectie       text,          -- 'planning' of 'kapitalisatie'
  notitie      text,
  wijzigingen  jsonb,
  aantal       integer
);

-- ---------- Beveiliging: iedereen met een account mag lezen, niemand mag direct schrijven ----------
alter table public.profiles   enable row level security;
alter table public.onderdelen enable row level security;
alter table public.plan       enable row level security;
alter table public.historie   enable row level security;

create policy "eigen profiel of beheerder" on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy "beheerder past profielen aan" on public.profiles for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "ingelogd mag lezen" on public.onderdelen for select to authenticated using (true);
create policy "ingelogd mag lezen" on public.plan       for select to authenticated using (true);
create policy "ingelogd mag lezen" on public.historie   for select to authenticated using (true);

-- ---------- Opslaan: alleen beheerders, alles-of-niets, altijd met historie ----------
create or replace function public.opslaan(
  p_upsert      jsonb,    -- onderdelen die nieuw of gewijzigd zijn
  p_delete      text[],   -- id's van verwijderde onderdelen
  p_plan        jsonb,    -- nieuwe kapitalisatie-instellingen (of null)
  p_sectie      text,
  p_notitie     text,
  p_wijzigingen jsonb
) returns bigint
language plpgsql security definer set search_path = public as $$
declare v_id bigint;
begin
  if not public.is_admin() then
    raise exception 'Alleen beheerders kunnen wijzigingen opslaan';
  end if;

  if p_upsert is not null and jsonb_array_length(p_upsert) > 0 then
    insert into public.onderdelen (id, naam, categorie, element, locatie, code, hoeveelheid, bedrag, cyclus, eerste, jaren, bron, bijgewerkt)
    select r.id, r.naam, r.categorie, r.element, r.locatie, r.code, r.hoeveelheid,
           coalesce(r.bedrag,0), coalesce(r.cyclus,0), r.eerste, r.jaren, r.bron, now()
    from jsonb_populate_recordset(null::public.onderdelen, p_upsert) r
    on conflict (id) do update set
      naam = excluded.naam, categorie = excluded.categorie, element = excluded.element,
      locatie = excluded.locatie, code = excluded.code, hoeveelheid = excluded.hoeveelheid,
      bedrag = excluded.bedrag, cyclus = excluded.cyclus, eerste = excluded.eerste,
      jaren = excluded.jaren, bron = excluded.bron, bijgewerkt = now();
  end if;

  if p_delete is not null and array_length(p_delete, 1) > 0 then
    delete from public.onderdelen where id = any(p_delete);
  end if;

  if p_plan is not null then
    update public.plan set
      startjaar     = (p_plan->>'startjaar')::int,
      looptijd      = (p_plan->>'looptijd')::int,
      indexatie     = (p_plan->>'indexatie')::numeric,
      beginsaldo    = (p_plan->>'beginsaldo')::numeric,
      reservering   = (p_plan->>'reservering')::numeric,
      reserveringen = coalesce(p_plan->'reserveringen', '{}'::jsonb)
    where id = 1;
  end if;

  insert into public.historie (wie, wie_naam, sectie, notitie, wijzigingen, aantal)
  values (auth.uid(), (select coalesce(naam, email) from public.profiles where id = auth.uid()),
          p_sectie, nullif(trim(p_notitie), ''), p_wijzigingen, jsonb_array_length(coalesce(p_wijzigingen, '[]'::jsonb)))
  returning id into v_id;
  return v_id;
end; $$;

revoke execute on function public.opslaan(jsonb, text[], jsonb, text, text, jsonb) from public, anon;
grant  execute on function public.opslaan(jsonb, text[], jsonb, text, text, jsonb) to authenticated;


-- Hulpfuncties niet aanroepbaar van buitenaf
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.is_admin() from public, anon;
grant  execute on function public.is_admin() to authenticated;

-- 11 oktober 2026, migratie 'laatste_beheerder_beschermen': trigger profiles_laatste_beheerder voorkomt dat de
-- laatste beheerder (rol 'admin') wordt teruggezet. Rol wijzigen gaat via het tabblad Bewoners (kolom Rol).
