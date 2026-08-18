import importlib
from pyrogram import filters
from pyrogram.handlers import MessageHandler


def register_jiotv_handlers(app):
    """Register lightweight Jiotv-related command wrappers.

    This module intentionally avoids importing `bot` at import time to prevent
    circular imports. Instead it imports the `bot` module when register_jiotv_handlers
    is called (bot will already have defined the functions we need).
    """
    bot = importlib.import_module("bot")

    AUTH = getattr(bot, "AUTH", filters.user([0]))

    async def _jiostatus(client, message):
        """/jiostatus — wrapper to call existing jiotv_status_cmd"""
        await bot.jiotv_status_cmd(client, message)

    app.add_handler(MessageHandler(_jiostatus, filters.command("jiostatus") & AUTH))

    async def _channels(client, message):
        """/channels [search] — wrapper to call existing jiotv_channels_cmd

        Accepts optional search term exactly like the original command.
        An alias `/Chnnels` is also registered.
        """
        await bot.jiotv_channels_cmd(client, message)

    # register common spellings/aliases (pyrogram handles case-insensitive command matching)
    app.add_handler(MessageHandler(_channels, filters.command(["channels", "Chnnels"]) & AUTH))

    async def _jiorec(client, message):
        """/jiorec — start JioTV record wizard (wrapper around jiotv_rec_cmd)"""
        await bot.jiotv_rec_cmd(client, message)

    app.add_handler(MessageHandler(_jiorec, filters.command("jiorec") & AUTH))

    async def _dl_wrapper(client, message):
        """/dl — detect -Jiotv usage and dispatch to existing dl_catchup_cmd.

        Users may invoke:
          /dl -Jiotv -c ChannelName -t 02:00 PM - 02:30 PM -n File
        or other variants. The existing bot._parse_dl_command + dl_catchup_cmd
        should handle the heavy lifting, so forward the message to it when
        the -Jiotv flag (case-insensitive) is present.
        """
        text = (message.text or "")
        if "-jiotv" in text.lower() or "-jiotv" in text or "-Jiotv" in text:
            # forward to the catchup downloader wrapper already present in bot.py
            # dl_catchup_cmd expects (client, message)
            await bot.dl_catchup_cmd(client, message)
        else:
            # fallback to general dl handler if present
            handler = getattr(bot, "handle_ott_download", None)
            if handler:
                await handler(client, message)
            else:
                # last resort: call dl_help_cmd if available
                help_fn = getattr(bot, "dl_help_cmd", None)
                if help_fn:
                    await help_fn(client, message)

    app.add_handler(MessageHandler(_dl_wrapper, filters.command("dl") & AUTH))

    # Optional convenience command to refresh local jiotv caches if bot exposes one
    async def _refreshjiotv(client, message):
        refresh_fn = getattr(bot, "jiotv_channels_cmd", None)
        if refresh_fn:
            # call with same message to trigger refresh/list behaviour
            await refresh_fn(client, message)

    app.add_handler(MessageHandler(_refreshjiotv, filters.command("refreshjiotv") & AUTH))
