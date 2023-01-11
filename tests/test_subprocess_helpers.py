from unittest.mock import AsyncMock, patch

import pytest

from dbt_serverless.lib.subprocess_helpers import escape_ansi, execute_and_log_command


def test_escape_ansi() -> None:
    assert (
        escape_ansi("[0m15:40:07  Running with dbt=1.3.2") == "15:40:07  Running with dbt=1.3.2"
    )


@patch("dbt_serverless.lib.subprocess_helpers.asyncio.create_subprocess_shell")
@pytest.mark.asyncio
async def test_execute_and_log_command(create_subprocess_shell_mock: AsyncMock) -> None:
    fake_process = AsyncMock()
    attrs = {"communicate.return_value": (b"output", b"error")}
    fake_process.configure_mock(**attrs)
    create_subprocess_shell_mock.return_value = fake_process
    await execute_and_log_command("")
    create_subprocess_shell_mock.assert_awaited_once()
    create_subprocess_shell_mock.assert_called_once()
