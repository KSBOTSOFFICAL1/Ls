# 2 GB Telegram Local Bot API setup

This version bundles the Telegram Local Bot API server into the bot Docker image.
When `API_ID` and `API_HASH` are set, `bot.py` permanently starts the bundled Local Bot API and switches python-telegram-bot to it. Cloud Bot API fallback is disabled.

Telegram Local Bot API mode supports downloads without the normal cloud download
size limit and uploads up to 2000 MB. The bot itself still enforces a 2 GB safety
limit so a larger file is rejected cleanly.

## Required `.env`

```env
TELEGRAM_BOT_TOKEN=your_bot_token
API_ID=your_telegram_api_id
API_HASH=your_telegram_api_hash
TELEGRAM_LOCAL_API_AUTOSTART=1
TELEGRAM_LOCAL_API_PORT=8081
TELEGRAM_LOCAL_API_DIR=/tmp/telegram-bot-api
TELEGRAM_LOCAL_API_TEMP_DIR=/tmp/telegram-bot-api-tmp
```

`API_ID` and `API_HASH` are Telegram application credentials, not the bot token.

## Docker

Build the image and run it with the same environment/volume setup used by the bot.
The Local Bot API stores its downloaded Telegram files in `TELEGRAM_LOCAL_API_DIR`,
so make sure the host/container has enough free disk space for large videos.

If you use a persistent Docker volume, map it to `/tmp/telegram-bot-api` and, if
desired, `/tmp/telegram-bot-api-tmp` as well.

## Important

The bot must use the Local Bot API endpoint rather than `https://api.telegram.org`.
`bot.py` does this automatically after the local server starts.

If `API_ID`/`API_HASH` are missing or the local server cannot start, the bot **stops** instead of falling back to the cloud Bot API. This prevents the 20 MB download limitation from returning silently.


### Important migration note

Before switching a live bot from the cloud Bot API to a Local Bot API server, Telegram recommends deregistering the bot from the cloud server with `logOut`, then pointing the bot client at the local `/bot` and `/file/bot` endpoints. The application now starts the bundled Local Bot API on port 8081 and passes API_ID/API_HASH explicitly.
