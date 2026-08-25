# Use a prebuilt Debian-compatible Telegram Local Bot API binary.
# This avoids compiling TDLib during the app build, which was causing the
# Render/Metal builder to fail with: "container process is already dead".
FROM raylabpro/telegram-bot-api:9.4-debian AS telegram-local-api

FROM python:3.13-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TELEGRAM_LOCAL_API_AUTOSTART=1 \
    TELEGRAM_LOCAL_API_PORT=8081 \
    TELEGRAM_LOCAL_API_DIR=/tmp/telegram-bot-api \
    TELEGRAM_LOCAL_API_TEMP_DIR=/tmp/telegram-bot-api-tmp

WORKDIR /app

# FFmpeg is required by the existing media-processing features.
RUN apt-get update -o Acquire::Retries=3 \
    && apt-get install -y --no-install-recommends \
       ffmpeg ca-certificates libssl3 zlib1g libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Copy the Debian/glibc-compatible Local Bot API binary from the prebuilt image.
COPY --from=telegram-local-api /usr/local/bin/telegram-bot-api /usr/local/bin/telegram-bot-api
RUN chmod +x /usr/local/bin/telegram-bot-api

COPY requirements.txt .
RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir -r requirements.txt

COPY bot.py bot.py .env

# The Python bot starts the Local Bot API first and then points python-telegram-bot
# at the local /bot and /file/bot endpoints. There is intentionally no cloud fallback.
CMD ["python", "bot.py"]
