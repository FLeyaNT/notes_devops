from fastapi.testclient import TestClient

from app.main import app


def test_health_responds():
    client = TestClient(app)
    r = client.get("/api/health")
    assert r.status_code in (200, 503)
    assert "db" in r.json()