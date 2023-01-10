import logging
import logging.config
from os import environ
from subprocess import PIPE, STDOUT, Popen
from typing import IO

from fastapi import FastAPI
import yaml

from .lib.docs_helper import main as docs_helper_main

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
    try:
        with open("../config/logging.yml") as f:
            config = yaml.load(f, Loader=yaml.FullLoader)
            logging.config.dictConfig(config)
    except FileNotFoundError:
        logging.warning("Logging config file not found, dbt logs will not be displayed")


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
    docs_helper_main()
    return "https://storage.cloud.google.com/dbt-static-docs-bucket/index_merged.html"


def log_subprocess_output(pipe: IO[bytes]) -> None:
    count = 0
    for line in iter(pipe.readline, b""):  # b'\n'-separated lines
        if count > 200:
            break
        logging.info(line)
        print(line)
        count += 1


def execute_and_log_command(command: str) -> int:
    process = Popen(command, stdout=PIPE, stderr=STDOUT, shell=True)
    assert process.stdout is not None
    with process.stdout:
        log_subprocess_output(process.stdout)
    return process.wait()
