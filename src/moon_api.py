from fastapi import FastAPI
import time
from datetime import date

app = FastAPI()
max_time_stamp = 32508218892 # year 3000


def create_progress_bar(prefix: str, percentage: int, progress_length: int = 20,  suffix: str = "") -> str:
    """Create a progress bar string with surround text and percentage."""
    loading_blocks = int(percentage * progress_length / 100)
    loading_progress = "█" * loading_blocks + "." * (progress_length - loading_blocks)
    return f"{prefix} {loading_progress} ({percentage}%) {suffix}"


def determine_cycle_status_message() -> str:
    """Determine the status message for the moon cycle.
    Timestamp are epoch unix timestamp expressed in seconds.
    Other durations are also expressed in seconds."""

    current_date_timestamp = time.time()
    if current_date_timestamp >= max_time_stamp:
        return "Date not supported (are you from the future ?)"
    initial_previous_full_moon = float(1767434655) # Sat Jan 03 2026 10:04:15 GMT+0000
    lunar_cycle_duration = float(2557209)
    next_full_moon = initial_previous_full_moon
    while next_full_moon < current_date_timestamp:
        next_full_moon += lunar_cycle_duration
    print(f"Next full moon : {date.fromtimestamp(next_full_moon)}")
    real_previous_full_moon = next_full_moon - lunar_cycle_duration
    new_moon = real_previous_full_moon + (lunar_cycle_duration / 2) # New moon between the 2 closest full moons
    print(f"Previous full moon : {date.fromtimestamp(real_previous_full_moon)}")
    print(f"Current time : {date.fromtimestamp(time.time())}")
    if new_moon < current_date_timestamp:
        # The moon is loading
        loading_ratio = (current_date_timestamp - new_moon) / (lunar_cycle_duration / 2)
        loading_percentage = round(loading_ratio * 100)
        print(f"Moon loading (->) : {loading_percentage} %")
        
        # Simplify when close to 100%
        if loading_percentage >= 95:
            loading_percentage = 100
            return create_progress_bar("Moon is loaded !!!", loading_percentage)
        elif loading_percentage <=5:
            loading_percentage = 0
            return create_progress_bar("Moon started loading", loading_percentage, suffix="It's a brand new moon")
        else:
            return create_progress_bar("Loading (->) :", loading_percentage)
    else:
        # The moon unloads
        unloading_ratio = (new_moon - current_date_timestamp) / (lunar_cycle_duration / 2)
        unloading_percentage = round(unloading_ratio * 100)
        print(f"Moon unloads (<-) : {unloading_percentage} %")

        # Simplify when close to 0%
        if unloading_percentage <= 5:
            unloading_percentage = 0
            return create_progress_bar("Moon is unloaded :", unloading_percentage, suffix="Don't worry, a new moon is on its way !")
        elif unloading_percentage >= 95:
            unloading_percentage = 0
            return create_progress_bar("Moon is loaded !!!", unloading_percentage)
        else:
            return create_progress_bar("Unloading (<-) :", unloading_percentage)

# TODO : eventually version the api (/api/v1/moon/status ? /api/moon/status ?)
@app.get("/moon/status")
def get_moon_status():
    """Endpoint to get the moon status message."""
    return {"message": determine_cycle_status_message()}


@app.get("/ready")
def get_ready():
    """Endpoint to check if the service is ready."""
    return {"status": "ok"}
