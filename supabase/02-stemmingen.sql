-- Stemmingen (al uitgevoerd in Supabase op 11 oktober 2026; alleen ter documentatie)
-- Eén stem per appartement, openbaar na de sluitingsdatum, stemmen alleen via de functie stem().
alter table public.profiles add column if not exists appartement text;
-- Zie de migratie 'stemmingen' in Supabase voor: mijn_appartement(), stemmingen, stemmen, stem(), stem_opkomst()

-- 11 oktober 2026, migratie 'stem_eenmalig': stemmen is eenmalig. stem() weigert als het appartement al gestemd heeft
-- ('Je appartement heeft al gestemd'). Beheerder mag een stem verwijderen (policy 'beheerder mag stem intrekken'),
-- waarna het appartement opnieuw kan stemmen.
