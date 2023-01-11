from unittest.mock import AsyncMock, MagicMock, mock_open, patch

import pytest
from starlette.testclient import TestClient

from dbt_serverless.main import app

client = TestClient(app)


def test_read_root() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello World"}


@pytest.mark.asyncio
async def test_read_deps() -> None:
    response = client.get("/deps")
    assert "Running with dbt=1.3.2" in response.text
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_read_debug() -> None:
    response = client.get("/debug")
    assert "Connection test: [OK connection ok]" in response.text
    assert response.status_code == 200


# We don't want to execute any run commands on our warehouse
@patch("dbt_serverless.lib.subprocess_helpers.asyncio.create_subprocess_shell")
@pytest.mark.asyncio
async def test_read_run(create_subprocess_shell_mock: AsyncMock) -> None:
    fake_process = AsyncMock()
    attrs = {"communicate.return_value": (b"output", b"error")}
    fake_process.configure_mock(**attrs)
    create_subprocess_shell_mock.return_value = fake_process
    response = client.get("/run")
    create_subprocess_shell_mock.assert_awaited_once()
    create_subprocess_shell_mock.assert_called_once()
    assert response.text == "output" and response.status_code == 200


@patch("google.cloud.storage.Client")
@patch("builtins.open", new_callable=mock_open, read_data="""{"data": "data"}""")
@pytest.mark.asyncio
async def test_read_docs(mock_file: MagicMock, mock_client: MagicMock) -> None:
    response = client.get("/docs_serve")
    mock_client.assert_called_once_with()
    mock_file.assert_called()
    assert response.status_code == 200
    assert (
        response.json()
        == "https://storage.cloud.google.com/dbt-static-docs-bucket/index_merged.html"
    )
