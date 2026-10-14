# KisanMart

KisanMart is a mobile-first Indian farm-input marketplace foundation, starting with a responsive storefront and secure farmer accounts.

## Run & Operate

- `pnpm --filter @workspace/kisanmart run dev` — run the KisanMart Next.js app
- `pnpm --filter @workspace/kisanmart run typecheck` — type-check the app
- `pnpm --filter @workspace/kisanmart run lint` — run ESLint
- `pnpm --filter @workspace/kisanmart run format:check` — check formatting
- `pnpm --filter @workspace/kisanmart run build` — build the Next.js app
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck and build all workspace packages
- Required app env: `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (legacy anon key name is accepted)

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- Web: Next.js App Router, React, strict TypeScript, Tailwind CSS
- Identity and database: user-selected Supabase Auth, PostgreSQL, RLS, and Storage
- Validation: Zod
- Localization foundation: next-intl
- No separate Express API is used for KisanMart storefront/auth.

## Where things live

- `artifacts/kisanmart/src/app/` — App Router routes and server actions
- `artifacts/kisanmart/src/components/kisanmart/` — storefront UI
- `artifacts/kisanmart/src/lib/supabase/` — browser/server Supabase clients
- `artifacts/kisanmart/supabase/migrations/` — versioned schema, RLS, storage policies, and admin functions
- `artifacts/kisanmart/supabase/RLS.md` — data-access matrix
- `artifacts/kisanmart/README.md` — setup, environment, and validation
- `artifacts/api-server/` — separate workspace API artifact; not used for KisanMart Phase 1

## Architecture decisions

- Supabase is the chosen auth/database platform for this product; do not replace it with Replit Auth or the workspace API without an explicit product decision.
- Keep Supabase service-role credentials out of the browser and out of Phase 1; use publishable/anon access with RLS.
- Keep order, stock, coupon, and payment mutations server-controlled and transactional; do not grant direct browser writes.
- Treat starter products and crop-stage labels as illustrative only, never as live availability, prices, or agronomic advice.
- Keep the initial scope to the storefront/auth/schema foundation until the user approves a later phase.

## Product

The current phase provides a responsive storefront shell, account sign-in/sign-up, and a secure Supabase schema foundation. Catalog search, cart, checkout, seller tools, and admin UI are not implemented yet.

## User preferences

- Follow the attached KisanMart Phase 1 specification and stop before later phases unless asked.
- Keep the storefront mobile-first and usable on narrow screens.

## Gotchas

- The Supabase migration is not automatically applied. Review and apply it to a dedicated project, then generate `src/types/database.ts` from the applied schema.
- Sign-in remains disabled until public Supabase URL/key environment values are configured.
- The web artifact must run as a Next.js Node server; do not restore the Vite static production serve configuration.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
