import json
import logging
import logging.config
from os import environ

from fastapi import FastAPI
import yaml

from .lib.file_helpers import read_file, read_json_file, upload_blob, write_file
from .lib.subprocess_helpers import execute_and_log_command

app = FastAPI()

DBT_PROJECT = environ.get("DBT_PROJECT")
DBT_PROFILES_DIR = environ.get("DBT_PROFILES_DIR")

DBT_COMMAND_SUFFIX = f" --project-dir {DBT_PROJECT}/ --profiles-dir {DBT_PROFILES_DIR}"
DEBUG_COMMAND = "dbt debug" + DBT_COMMAND_SUFFIX
RUN_COMMAND = "dbt run -t {ENV}" + DBT_COMMAND_SUFFIX
DEPS_COMMAND = "dbt deps" + DBT_COMMAND_SUFFIX
DOCS_COMMAND = "dbt docs generate" + DBT_COMMAND_SUFFIX


@app.on_event("startup")
async def startup_event() -> None:
    content = read_file("../config.logging.yml")
    config = yaml.load(content, Loader=yaml.FullLoader)
    logging.config.dictConfig(config)


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "Hello World"}


@app.get("/deps")
async def deps() -> int:
    return execute_and_log_command(DEPS_COMMAND)


@app.get("/debug")
async def debug() -> int:
    return execute_and_log_command(DEBUG_COMMAND)


@app.get("/run")
async def run(env: str = "dev") -> int:
    return execute_and_log_command(RUN_COMMAND.format(ENV=env))


@app.get("/docs_serve")
async def docs() -> str:
    execute_and_log_command(DOCS_COMMAND)

    logging.info("Merging files into a single one for gcs static serving")

    content_index = read_file(f"{DBT_PROJECT}/target/index.html")
    json_manifest = read_json_file(f"{DBT_PROJECT}/target/manifest.json")
    json_catalog = read_json_file(f"{DBT_PROJECT}/target/catalog.json")
    search_str = 'o=[i("manifest","manifest.json"+t),i("catalog","catalog.json"+t)]'
    data = (
        "o=[{label: 'manifest', data: "
        + json.dumps(json_manifest)
        + "},{label: 'catalog', data: "
        + json.dumps(json_catalog)
        + "}]"
    )

    data = content_index.replace(search_str, data)
    write_file(f"{DBT_PROJECT}/target/index_merged.html", data)

    logging.info("Uploading the file to GCS for static website serving")

    upload_blob("dbt-static-docs-bucket", "target/index_merged.html", "index_merged.html")

    return "https://storage.cloud.google.com/dbt-static-docs-bucket/index_merged.html"
