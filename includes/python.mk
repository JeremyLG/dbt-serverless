check: poetry-lock clean-code clean-coverage quality test poetry-build docker-build
test: prepare-test poetry-test

quality: prepare-quality poetry-quality
run: prepare-run poetry-run
docker: docker-build docker-run

prepare-quality:
	@poetry install --only nox,fmt,lint,type_check,docs

poetry-quality:
	@poetry run nox -s fmt_check
	@poetry run nox -s lint
	@poetry run nox -s type_check
	@poetry run nox -s docs

poetry-lock:
	@poetry env use python3.9
	@poetry install
	@poetry lock --check

clean-coverage:
	@rm -f .coverage*
	@rm -f coverage.xml

prepare-test:
	@poetry install --only nox

poetry-test:
	@poetry run nox -s test-3.9
	@rm -f .coverage*
	@rm -f coverage.xml
	@poetry run nox -s test-3.10

clean-code:
	@poetry run isort .
	@poetry run black .

poetry-build:
	@poetry build

prepare-run:
	@poetry install --only main

poetry-run:
	@poetry run uvicorn dbt_serverless.main:app --host 0.0.0.0 --port 8080 --reload

poetry-pulumi:
	@poetry run python -m iac-pulumi.main
