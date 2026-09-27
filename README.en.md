[🇷🇺 Русский](README.md) | [🇬🇧 English]

# PublyPostix

> **A distributed gateway and workflow orchestrator for cross-posting content to social networks — right from Telegram.**

Built on System Design principles and the **12-Factor App** methodology: the orchestration engine runs as a **Stateless** service, while PostgreSQL serves as the **Single Source of Truth** for the state machine (FSM) and the publication audit trail.

---

## 🏗 System Topology

The system is split into three clean layers following the **Gateway — Core — Adapters** pattern:

```text
               ┌────────────────────────────────────────────────────────┐
               │             Incoming Telegram API Webhooks             │
               └───────────────────────────┬────────────────────────────┘
                                           │
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│ [INGESTION GATEWAY & CORE ENGINE] (publypostix_core)                                  │
│                                                                                       │
│  • Event Ingestion Gateway: routes commands (/start), RPC callback signals & payloads │
│  • Distributed FSM: state management (IDLE, WAITING_*) backed by PostgreSQL           │
│  • Contract Validation: declarative media filtering via JSONB contracts               │
│  • Batch Leader Election: webhook race-condition guard for Telegram albums            │
│  • Ephemeral UI Sink: dynamic status rendering & automated message garbage collection │
└──────────────────┬────────────────────────────────────────────────┬───────────────────┘
                   │ (Data Contract)                                │ (Data Contract)
                   ▼                                                ▼
┌──────────────────────────────────────┐         ┌──────────────────────────────────────┐
│ [INSTAGRAM SERVICE ADAPTER]          │         │ [VKONTAKTE SERVICE ADAPTER]          │
│ (Sub-workflow: Instagram Publisher)  │         │ (Pipeline: VK ID & VK API)           │
│                                      │         │                                      │
│  • Reels: Init ➔ Polling ➔ Publish │         │  • OAuth 2.1: dynamic PKCE flow      │
│  • Feed Posts: Single container flow │         │    (SHA-256 + base64url, RFC 7636)   │
│  • Stories: 9:16 transcode lifecycle │         │  • Device Binding: session handshake │
│  • Carousels: Parent-Child API flow  │         │  • In progress: Upload Server API    │
└──────────────────────────────────────┘         └──────────────────────────────────────┘
```

---

## 💡 Engineering Highlights

### 1. Distributed FSM on top of PostgreSQL

n8n workers don't hold user context in memory. The current state (`current_state`) and the session buffer (`draft_data` JSONB) live entirely in the `users` table. Navigation resets, cancellations, and transitions all run atomically inside a single transaction via SQL CTEs — so there are simply no zombie sessions.

### 2. Album Race Condition Guard (Batch Leader Election)

When a user sends an album, Telegram fires parallel webhooks for every media item — all sharing the same `media_group_id`. To avoid race conditions, a leader-election mechanism kicks in:

* Items accumulate in a JSONB array while a monotonic counter (`received_count`) increments.
* A short time barrier selects the deterministic leader via `current_max_seq`.
* Exactly one worker renders the carousel UI — no duplicate messages in the chat.

### 3. Two-Tier Meta Graph API Carousel Engine

Publishing a carousel to Instagram is a three-step process: create child items (`is_carousel_item=true`), bind them into a parent container (`media_type=CAROUSEL`), and trigger the release:

* Each slide's aspect ratio is validated independently — if one slide fails, the rest still publish (graceful degradation).
* Video slides are transcoded asynchronously — a non-blocking `Polling Loop` watches the status, guarded by a `Circuit Breaker` on timeout.

### 4. VK ID OAuth 2.1 Integration (RFC 7636 PKCE)

The VK ID integration follows the modern OAuth 2.1 standard, protecting the authorization code from interception:

* A cryptographic `code_verifier` is generated, and its SHA-256 hash (`code_challenge`) is computed on the fly in Base64URL.
* The session is passed through `draft_data` and bound to a specific device (`device_id`).
* Code exchange for `access_token` and `refresh_token` comes with automatic pre-emptive invalidation.

### 5. Idempotency & Honest Audit Trail

Every publication lands in the `publications` table with a unique `idempotency_key` and a detailed JSONB `media_payload`. The user only gets the success notification **after** the record has safely hit the database — never before.

---

## 🛠 Tech Stack

* **Orchestration:** n8n (Self-hosted on Docker, Sub-workflow architecture).
* **Data layer:** PostgreSQL 16 (JSONB, atomic CTEs, triggers, B-Tree indexes).
* **Infrastructure:** Docker, Docker Compose, 12-Factor App (`.env`).
* **External APIs & Protocols:**
  * Telegram Bot API (RPC-dispatched routing `domain:action:param`)
  * Meta Graph API v21.0 (Instagram Reels, Feed Posts, Stories, Carousels)
  * VK ID API (OAuth 2.1, PKCE, Device Session Binding)
  * REST API, Webhooks, Postman.

---

## 📊 Database Schema (Schema Overview)

The schema is versioned in `docs/schema.sql` (Single Source DDL):

* **`users`:** Telegram user profiles, roles, status, current FSM state (`current_state`) and session buffer (`draft_data` JSONB).
* **`connected_platforms`:** active connections, masked accounts, OAuth tokens, expiry timestamps (`expires_at`) and granted scopes (JSONB).
* **`publications`:** the full release log — platform, content type, JSONB `media_payload` and status (`published`, `failed`).

---

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/PublyPostix.git
   cd PublyPostix
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   # Fill in TELEGRAM_BOT_TOKEN, META_*, and VK_* credentials in .env
   ```

3. **Spin up the stack:**
   ```bash
   docker compose up -d
   ```

4. **Import workflows into n8n:**
   * Open n8n at `http://localhost:5678`.
   * Import the main workflow `workflows/publypostix_core.json` and the adapter `workflows/[Adapter] Instagram Publisher.json`.
   * Enable the workflows.

---

## 📈 Development Status

* [x] Docker Compose foundation (PostgreSQL 16 + n8n) with isolated data volumes.
* [x] Multi-tenant isolation and atomic user Upserts by `telegram_id`.
* [x] RPC-based interface routing architecture (`nav:`, `platform:`, `format:`, `connect:`).
* [x] FSM with declarative contract validation via `draft_data`.
* [x] Meta Graph API module: Reels, single posts, Stories, and async carousels.
* [x] VK ID auth pipeline (OAuth 2.1 + PKCE SHA-256 + Device ID) with tokens stored in DB.
* [ ] **In progress:** VKontakte publishing adapter (Upload Server ➔ Save ➔ Wall Post).
* [ ] **Planned:** YouTube Data API v3 integration (Shorts and long-form videos).