import logging
from subprocess import PIPE, STDOUT, Popen
from typing import IO

logger = logging.getLogger(__name__)


def log_subprocess_output(pipe: IO[bytes]) -> None:
    count = 0
    for line in iter(pipe.readline, b""):  # b'\n'-separated lines
        if count > 200:
            break
        logger.info(line.decode("utf-8"))
        count += 1


def execute_and_log_command(command: str) -> int:
    process = Popen(command, stdout=PIPE, stderr=STDOUT, shell=True)
    assert process.stdout is not None
    with process.stdout:
        log_subprocess_output(process.stdout)
    return process.wait()
