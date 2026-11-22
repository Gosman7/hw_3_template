FROM python:3.13-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /srv

COPY app/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

RUN mkdir -p /data

ENV PORT=8000 \
    GREETING="Hello, Docker!" \
    STORAGE=sqlite \
    DATA_FILE=/data/counter.db

EXPOSE 8000

CMD ["python", "app/app.py"]
