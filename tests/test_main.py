from unittest.mock import MagicMock, mock_open, patch

from starlette.testclient import TestClient

from dbt_serverless.main import app

client = TestClient(app)


def test_read_root() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello World"}


def test_read_deps() -> None:
    response = client.get("/deps")
    assert response.status_code == 200
    assert response.json() == 0


def test_read_debug() -> None:
    response = client.get("/debug")
    assert response.status_code == 200
    assert response.json() == 0


@patch("google.cloud.storage.Client")
@patch("builtins.open", new_callable=mock_open, read_data="""{"data": "data"}""")
def test_read_docs(mock_file: MagicMock, mock_client: MagicMock) -> None:
    response = client.get("/docs_serve")
    mock_client.assert_called_once_with()
    mock_file.assert_called()
    assert response.status_code == 200
    assert (
        response.json()
        == "https://storage.cloud.google.com/dbt-static-docs-bucket/index_merged.html"
    )
