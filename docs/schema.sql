-- Включение поддержки внешних ключей
PRAGMA foreign_keys = ON;

-- 1. Пользователи Telegram
CREATE TABLE IF NOT EXISTS users (
    telegram_id   INTEGER PRIMARY KEY,
    username      TEXT,
    first_name    TEXT NOT NULL,
    last_name     TEXT,
    language_code TEXT,
    is_premium    INTEGER DEFAULT 0,
    role          TEXT DEFAULT 'user',
    status        TEXT DEFAULT 'active',
    created_at    TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at    TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 2. Подключенные социальные сети и токены
CREATE TABLE IF NOT EXISTS connected_platforms (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          INTEGER NOT NULL,
    platform         TEXT NOT NULL,
    platform_user_id TEXT NOT NULL,
    account_name     TEXT,
    access_token     TEXT NOT NULL,
    refresh_token    TEXT,
    expires_at       TEXT,
    scopes           TEXT,
    status           TEXT DEFAULT 'active',
    last_error       TEXT,
    created_at       TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at       TEXT DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(telegram_id) ON DELETE CASCADE,
    UNIQUE (user_id, platform, platform_user_id)
);

CREATE INDEX IF NOT EXISTS idx_platforms_user_active 
ON connected_platforms (user_id, status);

-- 3. Журнал публикаций и идемпотентность
CREATE TABLE IF NOT EXISTS publications (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL,
    platform_account_id INTEGER,
    platform            TEXT NOT NULL,
    media_type          TEXT DEFAULT 'video',
    media_file_id       TEXT,
    caption             TEXT,
    status              TEXT DEFAULT 'pending',
    platform_post_id    TEXT,
    idempotency_key     TEXT UNIQUE,
    retry_count         INTEGER DEFAULT 0,
    error_message       TEXT,
    published_at        TEXT,
    created_at          TEXT DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(telegram_id) ON DELETE CASCADE,
    FOREIGN KEY (platform_account_id) REFERENCES connected_platforms(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_publications_user_status 
ON publications (user_id, status);

CREATE INDEX IF NOT EXISTS idx_publications_idempotency 
ON publications (idempotency_key);