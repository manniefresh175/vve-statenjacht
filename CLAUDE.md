# VVE Statenjacht website – overdracht voor Claude

Lees dit eerst bij elke nieuwe sessie. De eigenaar (Manuel, manniefresh175@gmail.com) is beheerder van
VVE Statenjacht en schrijft meestal Nederlands. Antwoord in het Nederlands, kort en praktisch.

## Harde afspraken
- **Geen onverwachte kosten.** Controleer bij elke dienst of stap eerst of het gratis is en waarschuw vooraf.
  (Netlify-credits raakten op door deploys; daarom zijn we naar GitHub Pages verhuisd. Netlify niet meer gebruiken.)
- **Nooit geheime sleutels vragen of verwerken**: Supabase service_role/secret key, databasewachtwoord,
  Resend API-key, mailwachtwoorden. Die vult Manuel zelf in de dashboards in.
- Vraag eerst bij onomkeerbare of destructieve acties.
- Het gedeelde claude.ai-artifact van de oude MJOP (claude.ai/artifact/WYpkjiPNY9W5TqLm6hsB6M) niet wijzigen.
- Bij TransIP DNS moet de schakelaar "TransIP-instellingen" UIT blijven.

## Architectuur
- **Site**: statische HTML, gehost op **GitHub Pages** (gratis, publieke repo) vanaf branch `main`, map `/`.
  Repo: `manniefresh175/vve-statenjacht`. Domein `vve-statenjacht.nl` via bestand `CNAME`; `.nojekyll` aanwezig.
  Elke push naar `main` zet de site binnen ~1 minuut live (GitHub cachet tot 10 min; Cmd+Shift+R).
- **DNS (TransIP)**: A-records `@` → 185.199.108.153 / .109 / .110 / .111.153; `www` CNAME → `manniefresh175.github.io.`;
  Resend-records: `resend._domainkey` TXT, `rsend` CNAME, `send` CNAME (niet aankomen).
- **Database en inloggen**: Supabase, project `tnqjubjtsdwulwjbbhfp` (eu-west-1), gratis plan.
  E-mail + wachtwoord, alleen op uitnodiging (signups uit). Nieuwe bewoners: Supabase → Authentication → Users → Invite user.
  Site URL in Supabase: `https://vve-statenjacht.nl`. Publieke (publishable) sleutel staat in de HTML; dat is bedoeld.
- **E-mail**: Resend SMTP (gratis: 3000/maand, 100/dag), afzender noreply@vve-statenjacht.nl.
- Claude heeft toegang via de Supabase-connector (MCP) en de Claude GitHub App (alleen deze repo).

## Bestanden
- `index.html` – inlogscherm + portaal met tabbladen (hash-routing):
  `#overzicht` (foto, melding lopende stemming, laatste mededelingen, binnenkort),
  `#mededelingen`, `#agenda`, `#stemmingen`, `#bestuur` (Bestuur / Technische commissie / Kascommissie / Overige),
  `#contacten`, `#bewoners` (alleen beheerder), en de tab MJOP Planner → `mjop.html`.
- `mjop.html` – MJOP Planner (Overzicht, Planning, Kapitalisatie, Instellingen, Historie) met dezelfde kopbalk/tabs.
- `assets/statenjacht.jpg` (2000px) en `assets/statenjacht-900.jpg`.
- `supabase/01-schema.sql`, `supabase/02-stemmingen.sql` – documentatie van het schema.

## Database (public)
- `profiles` (id, email, naam, rol 'admin'|'lezer', appartement). Nieuwe gebruiker krijgt automatisch rol 'lezer'.
- `onderdelen`, `plan` (id=1), `historie` – MJOP; schrijven alleen via RPC `opslaan()` (alleen admin).
- `mededelingen`, `agenda`, `contacten` (groep 'bestuur'|'tc'|'contact', `commissie` = Technische commissie/Kascommissie/Overige).
- `stemmingen` (titel, toelichting, opties jsonb, sluit) en `stemmen` (pk stemming_id+appartement).
  Eén stem per appartement, openbaar na sluiting (RLS), stemmen alleen via RPC `stem()`; opkomst via `stem_opkomst()`.
- RLS: ingelogd mag lezen; schrijven alleen als `is_admin()`. Security-definer functies zijn bewust aanroepbaar.

## Werkwijze
- Wijzig lokaal, test met Playwright (Chromium staat klaar; nep-Supabase via route-interceptie), commit, push naar `main`.
- Commitberichten eindigen met de Co-Authored-By/Claude-Session-regels uit de sessie.
- Ontwerp: Archivo (koppen) + IBM Plex Sans; kleuren baksteen #7b3526, kozijnoranje #c4672f, lucht #255d9e, rivier #5d7775.

## Openstaande punten / ideeën
- Supabase "Leaked password protection" aanzetten als het gratis plan dat toelaat.
- Netlify-account wordt door Manuel opgeheven; de Netlify-connector in claude.ai kan weg.
- Online stemmen is een peiling; voor bindende besluiten splitsingsreglement/ALV raadplegen.
