from starlette.testclient import TestClient

from dbt_serverless.main import app

client = TestClient(app)


def test_read_main() -> None:
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
