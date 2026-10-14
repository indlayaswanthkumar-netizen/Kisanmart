# KisanMart — Phase 1 foundation

KisanMart is a mobile-first starting point for an agriculture marketplace for
farmers in India. Phase 1 includes a responsive storefront shell, email/password
account foundation, Supabase SSR clients, versioned schema/RLS, and development
taxonomy seeds. Catalog search, live product listings, cart, checkout, seller
dashboard, payment processing, and crop advice are later phases.

All product tiles on the starter page are illustrative examples, not live offers,
prices, availability, certifications, or agronomic recommendations.

## Run locally

1. Install the workspace with `pnpm install`.
2. Copy `.env.example` to `.env.local`.
3. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` for
   a configured Supabase project. The legacy `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   name is accepted if that is what the project provides. Do not add a
   service-role key to the browser or commit real credentials.
4. Start the web app with:

   ```sh
   pnpm --filter @workspace/kisanmart run dev
   ```

   If Supabase is not configured, the starter pages still render and the sign-in
   forms explain that account access is not enabled.

## Supabase setup

1. Create a dedicated Supabase project for KisanMart; do not apply this
   migration to an unrelated or production database.
2. Set the Auth site URL to the local app URL and add the local callback/redirect
   URL in the Auth URL configuration.
3. Enable email/password sign-in. Confirm that the signup email flow works.
   Google OAuth and phone OTP remain unavailable until their providers and
   callbacks are configured and verified.
4. Apply the versioned SQL migration using the Supabase CLI (`supabase link`
   followed by `supabase db push`) or the SQL Editor after reviewing the SQL.
   The migration creates application tables, RLS, moderation functions, and
   private storage buckets. It does not run automatically at app startup.
5. Run `supabase/seed.sql` in a development project only. It is repeatable and
   contains category/crop taxonomy labels only.
6. Generate the complete TypeScript database types after the schema is applied:

   ```sh
   cd artifacts/kisanmart
   pnpm exec supabase gen types typescript --project-id <project-ref> --schema public > src/types/database.ts
   ```

   For a local Supabase stack, use `--local` instead of `--project-id`.

7. To bootstrap the first administrator, verify the Auth user's identity, then
   insert that user's UUID into `public.user_roles` as `admin` in the Supabase
   SQL Editor. Never add role selection to public signup. After bootstrap,
   role changes must use the protected `admin_grant_role` and `admin_remove_role`
   functions.

The application uses only the Supabase URL and publishable/anon key in its
Phase 1 browser/server clients. It does not require the service-role key.

## Checks

```sh
pnpm --filter @workspace/kisanmart run typecheck
pnpm --filter @workspace/kisanmart run lint
pnpm --filter @workspace/kisanmart run test
pnpm --filter @workspace/kisanmart run format:check
pnpm --filter @workspace/kisanmart run build
```

If a Supabase project is available, also verify RLS with separate anonymous,
farmer, approved-seller, pending-seller, and admin sessions. Confirm that a
signup creates only a farmer role, one user cannot read another user’s address
or order, a seller cannot approve their own store/product/assets, and private
seller documents cannot be read by another seller or an anonymous visitor.

## Database references

- `supabase/migrations/` — ordered schema and policy changes.
- `supabase/seed.sql` — repeatable development-only taxonomy data.
- `supabase/RLS.md` — per-table access matrix and storage boundaries.
- `src/lib/supabase/` — SSR-compatible browser/server clients and session
  refresh.
