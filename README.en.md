[🇷🇺 Русский](README.md) | [🇬🇧 English]

# PublyPostix

An automated multi-platform cross-posting bot for publishing videos and posts across social media networks directly from a single Telegram interface.

## Overview
PublyPostix enables creators to upload media and captions to Telegram, automatically dispatching content to connected platforms:
- Telegram Channels
- Instagram Reels
- VKontakte (Clips / Posts)
- YouTube Shorts

## Tech Stack
- **Orchestration & Workflow Engine:** n8n (Self-hosted via Docker)
- **Database:** PostgreSQL 16 (stores users, OAuth tokens, platform permissions via JSONB, and publication logs)
- **Infrastructure:** Docker Compose, container networking, 12-Factor App secret management (`.env`)
- **APIs & Protocols:** Telegram Bot API, Meta Graph API, VK API, YouTube Data API v3

## Current Development Status
- [x] Deployed containerized infrastructure via Docker Compose (PostgreSQL 16 + n8n) with persistent volumes.
- [x] Implemented multi-tenant user isolation via atomic Upserts on `telegram_id`.
- [x] Integrated Meta OAuth 2.0 authorization flow with persistence of access tokens and scopes in `connected_platforms`.
- [x] Sanitized application configuration and decoupled infrastructure secrets (`.env`, `.env.example`).
- [ ] In progress: State-Driven Telegram UI (dynamic connection status from PostgreSQL) and end-to-end Reels publishing pipeline.