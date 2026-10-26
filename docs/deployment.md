# Deployment

Production runs as one Render web service backed by Supabase (Postgres and Auth), an LLM provider, and Stripe in test mode. Setup takes about 30 minutes.

## 1. Supabase

1. Create a project. Under **Authentication → Sign In / Providers → Email**, turn **Confirm email** off (the app has no email-confirmation callback).
2. In the **SQL editor**, run the migrations in order:
   1. `supabase/migrations/202610190001_quote_storage.sql`
   2. `supabase/migrations/202610190002_menu_storage.sql`
   3. `supabase/migrations/202610200001_conversations.sql`
   4. `supabase/migrations/202610200002_owner_billing.sql`
   5. `supabase/migrations/202610210001_quote_archive.sql`

   Each creates server-only tables in the `catering_private` schema with row-level security on and no browser grants. They are transactional and refuse to overwrite an existing schema.
3. Copy the **session pooler** connection string (**Connect**) for `QUOTE_DATABASE_URL`, and the project URL and **publishable** key (**Settings → API Keys**) for `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. Never use the secret key.

## 2. Render

1. **New → Blueprint** and select this repository. `render.yaml` defines the service, start command, health check and every environment variable; secrets are `sync: false`, so Render asks for them.
2. Fill in the variables below. After the first deploy, set **Authentication → URL Configuration → Site URL** in Supabase to the Render URL.
3. Keep `--proxy-headers` in the start command; the cross-site check relies on the app seeing `https`. The service runs a single worker, which the per-customer locks assume.

## 3. Owner account

1. On the live site, sign up with the owner's email. Every sign-up creates a customer.
2. In Supabase, **Authentication → Users**, copy that user's UID.
3. In Render, set `OWNER_USER_IDS` to the UID and save. The service redeploys, and that account now lands on the quote inbox.

## 4. Stripe (test mode)

1. In the Stripe dashboard (Test mode), add a product with a **recurring monthly** price and copy its `price_…` ID.
2. Copy the test secret key (`sk_test_…`). Live keys are refused by the app.
3. **Developers → Webhooks → Add endpoint:** `https://<your-service>.onrender.com/stripe/webhook`, events `checkout.session.completed` and `checkout.session.async_payment_succeeded`. Copy the signing secret (`whsec_…`).
4. Set the three `STRIPE_*` variables in Render. Test with card `4242 4242 4242 4242`, any future date and any CVC.

Locally, `stripe listen --forward-to localhost:8000/stripe/webhook` forwards webhooks and prints a `whsec_` to use.

## Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `APP_ENV` | Yes | `production` on Render (set in `render.yaml`); hides API docs and enables secure cookies |
| `APP_DATASET` | Yes | `demo` (set in `render.yaml`): the 22-item menu in `data/demo/` |
| `QUOTE_DATABASE_URL` | Yes | Supabase session-pooler URI; server only |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Yes | Enable sign-in |
| `OWNER_USER_IDS` | Yes | Supabase user ID(s) of the owner, comma-separated |
| `LLM_PROVIDER` | Yes | `openai` or `anthropic` |
| `OPENAI_API_KEY`, `OPENAI_MODEL` | With OpenAI | e.g. `gpt-5.5` |
| `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL` | With Anthropic | Model defaults to `claude-sonnet-5-5` |
| `OPENAI_REASONING_EFFORT` | No | `none` for models that refuse tools with reasoning on |
| `STRIPE_SECRET_KEY`, `STRIPE_PRICE_ID`, `STRIPE_WEBHOOK_SECRET` | For billing | Test mode only; without them, checkout is turned off and the rest of the app works |
| `CHAT_DAILY_REQUESTS_PER_CUSTOMER`, `CHAT_DAILY_MESSAGES_PER_CUSTOMER`, `CHAT_DAILY_MESSAGES_TOTAL` | No | Optional daily caps (reset at 00:00 UTC); off when unset |

Also set a monthly spend limit in the LLM provider's console.

## Operations

- **Health:** `GET /healthz` returns `{"status": "ok"}`; `GET /healthz/db` reports whether the database is reachable and why not, without revealing secrets.
- **Free tiers:** the free Render service sleeps when idle (the first request takes about a minute), and a free Supabase project pauses after a week without activity.
- **Rate limits:** Supabase limits sign-ins per IP, and all traffic comes from Render's server IP. Check **Authentication → Rate Limits** before a busy demo.
