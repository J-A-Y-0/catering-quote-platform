# Public release scope

What this repository publishes, and what stays out of version control.

## Included

- Application code: `web/`, `assistant/`, `quote_engine/`, `menu/`, `billing/`
- Datasets used by the app and tests: `data/demo/`, `data/sample/`, the source menu and rules in `data/`, with validators and provenance notes
- Database schema: `supabase/migrations/`
- Evaluation set, scoring code and the reported model runs: `evaluation/`
- Tests: `tests/` (integration tests are opt-in and need a disposable Postgres)
- Deployment and CI configuration: `render.yaml`, `.github/workflows/ci.yml`, `.env.example` (variable names only)
- Documentation and screenshots: `README.md`, `docs/`

## Excluded

- Secrets: `.env`, `.env.*` (API keys, database URLs, Stripe keys never enter the repository)
- Local databases and demo state: `var/`, `*.sqlite3`
- Third-party web page captures used only to transcribe the menu: `data/raw/`
- Editor and tool configuration, caches and virtual environments

## Notes

- The demo business is shown as "Sample Catering Co."; the real source caterer, URLs and capture date are recorded in `data/source-log.md` for provenance.
- Customer data in tests and screenshots is synthetic; the demo accounts use `example.com` addresses.
- Stripe integration runs in test mode only; live keys are refused by the application.
