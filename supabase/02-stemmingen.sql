-- Stemmingen (al uitgevoerd in Supabase op 11 oktober 2026; alleen ter documentatie)
-- Eén stem per appartement, openbaar na de sluitingsdatum, stemmen alleen via de functie stem().
alter table public.profiles add column if not exists appartement text;
-- Zie de migratie 'stemmingen' in Supabase voor: mijn_appartement(), stemmingen, stemmen, stem(), stem_opkomst()
