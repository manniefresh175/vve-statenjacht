# VVE Statenjacht

Website van VVE Statenjacht, live op https://vve-statenjacht.nl

- **Hosting:** Netlify (publiceert automatisch bij elke push naar `main`)
- **Login en database:** Supabase (project `vve-statenjacht`, EU)
- **Rollen:** iedereen met een uitnodiging kan lezen; beheerders kunnen wijzigen.
  Opslaan gaat altijd via de databasefunctie `opslaan`, die de rechten controleert en een regel in de historie schrijft.

## Bestanden

- `index.html` – de app (MJOP-planning, kapitalisatie, instellingen, historie)
- `netlify.toml` – Netlify-instellingen
- `supabase/01-schema.sql` – tabellen, beveiligingsregels en de opslaan-functie (al uitgevoerd)

## Nieuwe bewoner toegang geven

Supabase → Authentication → Users → Add user → Send invitation.
Nieuwe accounts krijgen automatisch de rol "lezer".
