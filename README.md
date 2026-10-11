# VVE Statenjacht

Website van VVE Statenjacht, live op https://vve-statenjacht.nl

- **Hosting:** GitHub Pages (gratis, publiceert automatisch bij elke push naar `main`)
- **Login en database:** Supabase (project `vve-statenjacht`, EU)
- **Rollen:** iedereen met een uitnodiging kan lezen; beheerders kunnen wijzigen.
  Opslaan gaat altijd via de databasefunctie `opslaan`, die de rechten controleert en een regel in de historie schrijft.

## Bestanden

- `index.html` – inloggen en dashboard (mededelingen, agenda, samenvatting MJOP)
- `mjop.html` – de MJOP Planner (planning, kapitalisatie, instellingen, historie)
- `assets/` – foto van het gebouw
- `CNAME` – de domeinnaam voor GitHub Pages
- `supabase/01-schema.sql` – tabellen, beveiligingsregels en de opslaan-functie (al uitgevoerd)

## Nieuwe bewoner toegang geven

Supabase → Authentication → Users → Add user → Send invitation.
Nieuwe accounts krijgen automatisch de rol "lezer".
