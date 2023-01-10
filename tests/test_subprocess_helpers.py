from unittest.mock import MagicMock, patch

from dbt_serverless.lib.subprocess_helpers import execute_and_log_command


@patch("dbt_serverless.lib.subprocess_helpers.Popen")
def test_execute_and_log_command(mock_subproc_popen: MagicMock) -> None:
    execute_and_log_command("ls")
    mock_subproc_popen.assert_called()
