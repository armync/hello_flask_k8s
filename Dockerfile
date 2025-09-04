# syntax=docker/dockerfile:1
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# create non-root user

RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app

# install dep first for better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copy source
COPY . .

USER appuser
EXPOSE 8000

# use gunicorn for a production-grade HTTP server
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]