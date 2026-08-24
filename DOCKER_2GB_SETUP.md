# Permanent Telegram Local Bot API / 2 GB setup

This package runs the Telegram Local Bot API inside the same container as the bot.

## Why the previous Docker build failed

The previous Dockerfile compiled `telegram-bot-api` from source during every deployment.
The deployment log showed the builder dying during `apt-get` with:

`runc run failed: container process is already dead`

The new Dockerfile does **not** compile TDLib. It uses a prebuilt Debian-compatible
Telegram Bot API image as a build stage and copies its binary into the Python runtime.

## Runtime behavior

- Local Bot API is mandatory.
- The bot never silently falls back to `https://api.telegram.org`.
- `API_ID` and `API_HASH` are passed to the Local Bot API process.
- Local API listens on `127.0.0.1:8081` by default.
- Bot API endpoint: `http://127.0.0.1:8081/bot`
- File endpoint: `http://127.0.0.1:8081/file/bot`
- Local mode supports downloads without the cloud download-size limit and uploads up to 2000 MB.

## Environment variables

Set these in the deployment platform:

```text
TELEGRAM_BOT_TOKEN=your_bot_token
API_ID=your_api_id
API_HASH=your_api_hash
```

Optional:

```text
LOCAL_BOT_API=http://127.0.0.1:8081
LOCAL_BOT_API_ENABLED=true
LOCAL_BOT_API_REQUIRED=true
TELEGRAM_LOCAL_API_PORT=8081
TELEGRAM_LOCAL_API_DIR=/tmp/telegram-bot-api
TELEGRAM_LOCAL_API_TEMP_DIR=/tmp/telegram-bot-api-tmp
```

Do not set `TELEGRAM_LOCAL_API_URL` to `https://api.telegram.org`.

## Important Telegram migration note

Telegram's Local Bot API documentation says a bot being moved from the cloud Bot API
should be deregistered from the cloud server with `logOut`, then pointed at the local
server. This is a Telegram-side migration step, not a Python dependency setting.
