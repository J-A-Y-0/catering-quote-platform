.PHONY: install demo run test test-postgres eval check

PY ?= python3

install:  ## Install app and test dependencies
	$(PY) -m pip install -r requirements-dev.txt

demo:  ## Run the full app offline: no accounts, no API keys, local SQLite
	AUTH_BACKEND=memory LLM_PROVIDER=scripted APP_DATASET=demo \
	$(PY) -m uvicorn web.main:app --reload --port 8000

run:  ## Run with the settings in your environment (.env)
	$(PY) -m uvicorn web.main:app --reload --port 8000

test:  ## Unit and web tests (no network)
	$(PY) -m pytest -q

test-postgres:  ## Integration tests against a real Postgres (needs QUOTE_TEST_DATABASE_URL)
	$(PY) -m pytest -q tests/integration

eval:  ## Run the 22-case evaluation against the configured model
	$(PY) -m evaluation.run_eval --provider $${LLM_PROVIDER:-openai}

check: test  ## Tests plus dataset validation
	$(PY) data/validate_dataset.py
	$(PY) data/demo/validate_demo.py
