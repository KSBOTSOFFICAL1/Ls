# Build the official Telegram Bot API server locally so the bot can use
# Telegram's local mode (2 GB upload / unlimited download).
FROM debian:bookworm-slim AS telegram-bot-api-build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates git cmake g++ make gperf zlib1g-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN git clone --recursive --depth 1 https://github.com/tdlib/telegram-bot-api.git
WORKDIR /usr/src/telegram-bot-api
RUN mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/telegram-bot-api .. \
    && cmake --build . --target install -j"$(nproc)"

FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TELEGRAM_LOCAL_API_AUTOSTART=1 \
    TELEGRAM_LOCAL_API_PORT=8090 \
    TELEGRAM_LOCAL_API_DIR=/tmp/telegram-bot-api \
    TELEGRAM_LOCAL_API_TEMP_DIR=/tmp/telegram-bot-api-tmp

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg ca-certificates libssl3 zlib1g libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=telegram-bot-api-build /opt/telegram-bot-api/bin/telegram-bot-api /usr/local/bin/telegram-bot-api
RUN chmod +x /usr/local/bin/telegram-bot-api

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY bot.py run.py .env.example ./

CMD ["python", "run.py"]
