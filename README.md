# Moon Backend

A tiny REST API to get information about the lunar cycle status and moon-related data.

## Overview

This project provides a simple REST API to retrieve information about the current lunar cycle and other moon-related data. The API is designed to be lightweight and easy to use, with potential for expansion to include more comprehensive moon information in the future.

## Technical Stack

- **Language**: Python
- **Framework**: FastAPI
- **Containerization**: Docker
- **Dependency/project Management**: UV
- **Testing**: pytest

## Features

### Main feature

Get current lunar cycle status as a progess bar. The more the progress it has, the closest to a full moon it is.
Handles the increase of the moon'reflected area toward earth as well as the decrease. I like to think of it as a battery that would
charge up to the max (full moon), then discharge to zero (just before a new moon) and reapeat the process again and again.

(!) The progress is an estimation based on simple calculus, so the exact value of progress may vary from a couple hours to a day.

### Other features

- Dockerized for easy deployment
- Lightweight and fast

## Getting Started

### Prerequisites

- Docker (for containerized deployment)
- Python 3.12+ (for local development)
- UV package manager (for dependency management)
- Check the various prerequisits in the subfolders of the **deployment** directory
- optional : install [mise](https://mise.jdx.dev/) for an easier set up

### Installation

#### Using Docker

```bash
# Build the Docker image
docker build -t moon-backend -f Dockerfile .

# Run the container
docker run -p 8000:8000 moon-backend
```

#### Local Development

```bash
# Install dependencies
uv sync

# Run the API
uv run fastapi dev src/moon_api.py
```

### Running Tests

```bash
# Run tests
uv run pytest test/
```

## API Documentation

Once the API is running locally, you can access the interactive API documentation at:

- **OpenAPI/Swagger UI**: http://localhost:8000/docs

## Project Structure

```
moon_backend/
├── src/
│   └── moon_api.py          # Main API implementation
├── test/
│   └── moon_api_test.py     # Test cases
├── compose.yml              # Docker Compose configuration
├── Dockerfile               # Docker configuration
├── pyproject.toml           # Python project configuration
├── uv.lock                  # Dependency lock file
└── README.md                # Project documentation
```

## Future Enhancements

- Add more detailed moon information
- Adjust status calculation based on the caller's timezone (currently the info is based on UTC) 
- Expand with astronomical data
- Add caching for better performance
- Add requests rate limitation for security

## Contact

For questions or issues, please open a GitHub issue.
