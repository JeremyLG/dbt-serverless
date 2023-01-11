import asyncio
import logging
import re
from typing import Optional

logger = logging.getLogger(__name__)


def escape_ansi(line: str) -> str:
    ansi_escape = re.compile(r"(?:\x1B[@-_]|[\x80-\x9F])[0-?]*[ -/]*[@-~]")
    return ansi_escape.sub("", line)


async def execute_and_log_command(command: str) -> tuple[Optional[int], str]:
    proc = await asyncio.create_subprocess_shell(
        command, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT
    )
    stdout, stderr = await proc.communicate()
    if stdout:
        line = stdout.decode("ascii").rstrip()
        logger.info(line)
    if stderr:
        line = stdout.decode("ascii").rstrip()
        logger.error(line)
    await proc.wait()
    return proc.returncode, escape_ansi(line)
