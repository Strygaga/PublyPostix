\[🇷🇺 Русский](README.md) | \[🇬🇧 English]



\# PublyPostix



A Telegram bot for automated cross-posting of videos and media across social networks from a single dashboard.



\## Core Features

Receives media and captions via Telegram, then automatically routes and publishes content to:

\- Telegram Channels

\- Instagram Reels

\- VK (Clips / Wall Posts)

\- YouTube Shorts



\## Tech Stack

\- \*\*Workflow Engine:\*\* n8n (Self-hosted)

\- \*\*Database:\*\* SQLite (Stores users, OAuth access tokens, and delivery logs)

\- \*\*APIs \& Protocols:\*\* Telegram Bot API, Meta Graph API, VK API, YouTube Data API v3



\## Current Status

MVP working prototype: OAuth authorization flow and Instagram Reels video publishing are functional. Migrating in-memory state to persistent SQLite tables for multi-user token isolation.

