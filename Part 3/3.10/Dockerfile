FROM python:3.12.7-slim AS builder

WORKDIR /app

RUN python -m venv /venv

ENV PATH="/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12.7-slim-bookworm

WORKDIR /app

COPY --from=builder /venv /venv

ENV PATH="/venv/bin:$PATH"

COPY temp_server.py .
COPY fake_server_data.json .

EXPOSE 8000

RUN groupadd --system appgroup && useradd --system --no-create-home -g appgroup appuser
USER appuser

CMD ["uvicorn", "temp_server:app", "--host", "0.0.0.0", "--port", "8000"]