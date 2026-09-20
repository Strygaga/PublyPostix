-- 1. Таблица пользователей Telegram
CREATE TABLE IF NOT EXISTS users (
    telegram_id   BIGINT PRIMARY KEY,
    username      VARCHAR(255),
    first_name    VARCHAR(255) NOT NULL,
    last_name     VARCHAR(255),
    language_code VARCHAR(10),
    is_premium    BOOLEAN DEFAULT FALSE,
    role          VARCHAR(50) DEFAULT 'user',
    status        VARCHAR(50) DEFAULT 'active',
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Подключенные социальные сети и токены
CREATE TABLE IF NOT EXISTS connected_platforms (
    id               SERIAL PRIMARY KEY,
    user_id          BIGINT NOT NULL REFERENCES users(telegram_id) ON DELETE CASCADE,
    platform         VARCHAR(50) NOT NULL,
    platform_user_id VARCHAR(255) NOT NULL,
    account_name     VARCHAR(255),
    access_token     TEXT NOT NULL,
    refresh_token    TEXT,
    expires_at       TIMESTAMPTZ,
    scopes           JSONB,
    status           VARCHAR(50) DEFAULT 'active',
    last_error       TEXT,
    created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_user_platform UNIQUE (user_id, platform, platform_user_id)
);

CREATE INDEX IF NOT EXISTS idx_platforms_user_active ON connected_platforms (user_id, status);

-- 3. Журнал публикаций и идемпотентность
CREATE TABLE IF NOT EXISTS publications (
    id                  SERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(telegram_id) ON DELETE CASCADE,
    platform_account_id INT REFERENCES connected_platforms(id) ON DELETE SET NULL,
    platform            VARCHAR(50) NOT NULL,
    media_type          VARCHAR(50) DEFAULT 'video',
    media_file_id       VARCHAR(255),
    caption             TEXT,
    status              VARCHAR(50) DEFAULT 'pending',
    platform_post_id    VARCHAR(255),
    idempotency_key     VARCHAR(255) UNIQUE,
    retry_count         INT DEFAULT 0,
    error_message       TEXT,
    published_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_publications_user_status ON publications (user_id, status);
CREATE INDEX IF NOT EXISTS idx_publications_idempotency ON publications (idempotency_key);