-- public.users definition

-- Drop table

-- DROP TABLE public.users;

CREATE TABLE public.users (
	telegram_id int8 NOT NULL,
	username varchar(255) NULL,
	first_name varchar(255) NOT NULL,
	last_name varchar(255) NULL,
	language_code varchar(10) NULL,
	is_premium bool DEFAULT false NULL,
	"role" varchar(50) DEFAULT 'user'::character varying NULL,
	status varchar(50) DEFAULT 'active'::character varying NULL,
	created_at timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	current_state varchar(64) DEFAULT 'IDLE'::character varying NULL,
	draft_data jsonb DEFAULT '{}'::jsonb NULL,
	CONSTRAINT users_pkey PRIMARY KEY (telegram_id)
);

-- Permissions

ALTER TABLE public.users OWNER TO publy_admin;
GRANT ALL ON TABLE public.users TO publy_admin;


-- public.connected_platforms definition

-- Drop table

-- DROP TABLE public.connected_platforms;

CREATE TABLE public.connected_platforms (
	id serial4 NOT NULL,
	user_id int8 NOT NULL,
	platform varchar(50) NOT NULL,
	platform_user_id varchar(255) NOT NULL,
	account_name varchar(255) NULL,
	access_token text NOT NULL,
	refresh_token text NULL,
	expires_at timestamptz NULL,
	scopes jsonb NULL,
	status varchar(50) DEFAULT 'active'::character varying NULL,
	last_error text NULL,
	created_at timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT connected_platforms_pkey PRIMARY KEY (id),
	CONSTRAINT uk_user_platform UNIQUE (user_id, platform, platform_user_id),
	CONSTRAINT connected_platforms_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(telegram_id) ON DELETE CASCADE
);
CREATE INDEX idx_platforms_user_active ON public.connected_platforms USING btree (user_id, status);

-- Permissions

ALTER TABLE public.connected_platforms OWNER TO publy_admin;
GRANT ALL ON TABLE public.connected_platforms TO publy_admin;


-- public.publications definition

-- Drop table

-- DROP TABLE public.publications;

CREATE TABLE public.publications (
	id serial4 NOT NULL,
	user_id int8 NOT NULL,
	platform_account_id int4 NULL,
	platform varchar(50) NOT NULL,
	media_type varchar(50) DEFAULT 'video'::character varying NULL,
	media_file_id varchar(255) NULL,
	caption text NULL,
	status varchar(50) DEFAULT 'pending'::character varying NULL,
	platform_post_id varchar(255) NULL,
	idempotency_key varchar(255) NULL,
	retry_count int4 DEFAULT 0 NULL,
	error_message text NULL,
	published_at timestamptz NULL,
	created_at timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	media_payload jsonb DEFAULT '[]'::jsonb NULL,
	CONSTRAINT publications_idempotency_key_key UNIQUE (idempotency_key),
	CONSTRAINT publications_pkey PRIMARY KEY (id),
	CONSTRAINT publications_platform_account_id_fkey FOREIGN KEY (platform_account_id) REFERENCES public.connected_platforms(id) ON DELETE SET NULL,
	CONSTRAINT publications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(telegram_id) ON DELETE CASCADE
);
CREATE INDEX idx_publications_idempotency ON public.publications USING btree (idempotency_key);
CREATE INDEX idx_publications_user_status ON public.publications USING btree (user_id, status);

-- Permissions

ALTER TABLE public.publications OWNER TO publy_admin;
GRANT ALL ON TABLE public.publications TO publy_admin;