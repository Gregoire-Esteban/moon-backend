from fastapi.testclient import TestClient
import time_machine
from src.moon_api import app

client = TestClient(app, base_url="http://127.0.0.1:8000")


def test_moon_unloading_just_after_full_moon_2026_02_02():
    """Test moon unloading just after full moon (2026-02-02) - should be ~100% loaded"""
    with time_machine.travel("2026-02-02 10:04:15", tick=False):
        response = client.get("/moon/status")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        # Should be close to full moon (100% loaded)
        assert "Moon is loaded" in data["message"]

def test_moon_unloading_50_percent_2026_02_09():
    """Test moon unloading at 50% (about 7 days after full moon)"""
    with time_machine.travel("2026-02-09 10:04:15", tick=False):
        response = client.get("/moon/status")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        # Should be unloading with around 50% remaining
        assert "Unloading" in data["message"]

def test_new_moon_2026_02_17():
    """Test moon unloading at 100% (new moon, also the new lunar year!) - should show 0%"""
    with time_machine.travel("2026-02-17 12:10:05", tick=False):
        response = client.get("/moon/status")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        # Should be close to new moon (0% loaded)
        assert "Moon started loading" in data["message"]
        assert "a brand new moon" in data["message"]


def test_moon_loading_50_percent_2026_02_24():
    """Test moon loading at 50% (about 7 days after new moon)"""
    with time_machine.travel("2026-02-24 10:04:15", tick=False):
        response = client.get("/moon/status")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        # Should be loading with around 50% progress
        assert "Loading" in data["message"]


def test_moon_loading_full_moon_2026_03_03():
    """Test moon loading at full moon (2026-03-04) - should be 100% loaded"""
    with time_machine.travel("2026-03-03 11:39:12", tick=False):
        response = client.get("/moon/status")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        # Should be at full moon (100% loaded)
        assert "Moon is loaded" in data["message"]
        assert "100%" in data["message"]

def test_moon_loading_full_moon_3000():
    """Test moon loading at 3000-03-03 - should be no longer work"""
    with time_machine.travel("3000-03-03 11:39:12", tick=False):
        response = client.get("/moon/status")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Date not supported" in data["message"]
