--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activities (
    id integer NOT NULL,
    trackable_id integer,
    trackable_type character varying,
    owner_id integer,
    owner_type character varying,
    key character varying,
    parameters text,
    recipient_id integer,
    recipient_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activities_id_seq OWNED BY activities.id;


--
-- Name: concerto_configs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE concerto_configs (
    id integer NOT NULL,
    key character varying,
    value character varying,
    value_type character varying,
    value_default character varying,
    name character varying,
    category character varying,
    description text,
    plugin_config boolean,
    plugin_id integer,
    hidden boolean DEFAULT false,
    can_cache boolean DEFAULT true,
    seq_no integer,
    select_values character varying
);


--
-- Name: concerto_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE concerto_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: concerto_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE concerto_configs_id_seq OWNED BY concerto_configs.id;


--
-- Name: concerto_hardware_players; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE concerto_hardware_players (
    id integer NOT NULL,
    ip_address character varying,
    screen_id integer,
    activated boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    screen_on_off character varying
);


--
-- Name: concerto_hardware_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE concerto_hardware_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: concerto_hardware_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE concerto_hardware_players_id_seq OWNED BY concerto_hardware_players.id;


--
-- Name: concerto_plugins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE concerto_plugins (
    id integer NOT NULL,
    enabled boolean,
    gem_name character varying,
    gem_version character varying,
    source character varying,
    source_url character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: concerto_plugins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE concerto_plugins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: concerto_plugins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE concerto_plugins_id_seq OWNED BY concerto_plugins.id;


--
-- Name: contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents (
    id integer NOT NULL,
    name character varying,
    duration integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    data text,
    user_id integer,
    kind_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying,
    parent_id integer,
    children_count integer DEFAULT 0
);


--
-- Name: contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_id_seq OWNED BY contents.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: feeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feeds (
    id integer NOT NULL,
    name character varying,
    description text,
    parent_id integer,
    group_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_viewable boolean DEFAULT true,
    is_submittable boolean DEFAULT true,
    content_types text
);


--
-- Name: feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feeds_id_seq OWNED BY feeds.id;


--
-- Name: field_configs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE field_configs (
    id integer NOT NULL,
    field_id integer,
    key character varying,
    value character varying,
    screen_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: field_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE field_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: field_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE field_configs_id_seq OWNED BY field_configs.id;


--
-- Name: fields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE fields (
    id integer NOT NULL,
    name character varying,
    kind_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fields_id_seq OWNED BY fields.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    narrative text
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: kinds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE kinds (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: kinds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE kinds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: kinds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE kinds_id_seq OWNED BY kinds.id;


--
-- Name: media; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE media (
    id integer NOT NULL,
    attachable_id integer,
    attachable_type character varying,
    key character varying,
    file_name character varying,
    file_type character varying,
    file_size integer,
    file_data bytea,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE media_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE media_id_seq OWNED BY media.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE memberships (
    id integer NOT NULL,
    user_id integer,
    group_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    level integer DEFAULT 1,
    permissions integer,
    receive_emails boolean
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE memberships_id_seq OWNED BY memberships.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pages (
    id integer NOT NULL,
    category character varying,
    title character varying,
    language character varying,
    body text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    slug character varying
);


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pages_id_seq OWNED BY pages.id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE positions (
    id integer NOT NULL,
    style text,
    top numeric(6,5) DEFAULT 0,
    "left" numeric(6,5) DEFAULT 0,
    bottom numeric(6,5) DEFAULT 0,
    "right" numeric(6,5) DEFAULT 0,
    field_id integer,
    template_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE positions_id_seq OWNED BY positions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: screens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE screens (
    id integer NOT NULL,
    name character varying,
    location character varying,
    is_public boolean,
    owner_id integer,
    owner_type character varying,
    template_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    width integer,
    height integer,
    frontend_updated_at timestamp without time zone,
    authentication_token character varying,
    time_zone character varying
);


--
-- Name: screens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE screens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: screens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE screens_id_seq OWNED BY screens.id;


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE submissions (
    id integer NOT NULL,
    content_id integer,
    feed_id integer,
    moderation_flag boolean,
    moderator_id integer,
    duration integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    moderation_reason text
);


--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submissions_id_seq OWNED BY submissions.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscriptions (
    id integer NOT NULL,
    feed_id integer,
    field_id integer,
    screen_id integer,
    weight integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscriptions_id_seq OWNED BY subscriptions.id;


--
-- Name: templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE templates (
    id integer NOT NULL,
    name character varying,
    author character varying,
    is_hidden boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    original_width integer,
    original_height integer,
    owner_id integer,
    owner_type character varying
);


--
-- Name: templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE templates_id_seq OWNED BY templates.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    locale character varying,
    is_admin boolean DEFAULT false,
    receive_moderation_notifications boolean,
    time_zone character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities ALTER COLUMN id SET DEFAULT nextval('activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY concerto_configs ALTER COLUMN id SET DEFAULT nextval('concerto_configs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY concerto_hardware_players ALTER COLUMN id SET DEFAULT nextval('concerto_hardware_players_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY concerto_plugins ALTER COLUMN id SET DEFAULT nextval('concerto_plugins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents ALTER COLUMN id SET DEFAULT nextval('contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feeds ALTER COLUMN id SET DEFAULT nextval('feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY field_configs ALTER COLUMN id SET DEFAULT nextval('field_configs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fields ALTER COLUMN id SET DEFAULT nextval('fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY kinds ALTER COLUMN id SET DEFAULT nextval('kinds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY media ALTER COLUMN id SET DEFAULT nextval('media_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships ALTER COLUMN id SET DEFAULT nextval('memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pages ALTER COLUMN id SET DEFAULT nextval('pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY positions ALTER COLUMN id SET DEFAULT nextval('positions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY screens ALTER COLUMN id SET DEFAULT nextval('screens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions ALTER COLUMN id SET DEFAULT nextval('submissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions ALTER COLUMN id SET DEFAULT nextval('subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY templates ALTER COLUMN id SET DEFAULT nextval('templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: concerto_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY concerto_configs
    ADD CONSTRAINT concerto_configs_pkey PRIMARY KEY (id);


--
-- Name: concerto_hardware_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY concerto_hardware_players
    ADD CONSTRAINT concerto_hardware_players_pkey PRIMARY KEY (id);


--
-- Name: concerto_plugins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY concerto_plugins
    ADD CONSTRAINT concerto_plugins_pkey PRIMARY KEY (id);


--
-- Name: contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (id);


--
-- Name: field_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY field_configs
    ADD CONSTRAINT field_configs_pkey PRIMARY KEY (id);


--
-- Name: fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: kinds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY kinds
    ADD CONSTRAINT kinds_pkey PRIMARY KEY (id);


--
-- Name: media_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: screens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY screens
    ADD CONSTRAINT screens_pkey PRIMARY KEY (id);


--
-- Name: submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_activities_on_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_owner_id_and_owner_type ON activities USING btree (owner_id, owner_type);


--
-- Name: index_activities_on_recipient_id_and_recipient_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_recipient_id_and_recipient_type ON activities USING btree (recipient_id, recipient_type);


--
-- Name: index_activities_on_trackable_id_and_trackable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_trackable_id_and_trackable_type ON activities USING btree (trackable_id, trackable_type);


--
-- Name: index_concerto_configs_on_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_concerto_configs_on_key ON concerto_configs USING btree (key);


--
-- Name: index_feeds_on_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_parent_id ON feeds USING btree (parent_id);


--
-- Name: index_media_on_attachable_id_and_attachable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_media_on_attachable_id_and_attachable_type ON media USING btree (attachable_id, attachable_type);


--
-- Name: index_memberships_on_receive_emails; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_receive_emails ON memberships USING btree (receive_emails);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20100220021335');

INSERT INTO schema_migrations (version) VALUES ('20100220035351');

INSERT INTO schema_migrations (version) VALUES ('20100220041201');

INSERT INTO schema_migrations (version) VALUES ('20100227013802');

INSERT INTO schema_migrations (version) VALUES ('20100302031943');

INSERT INTO schema_migrations (version) VALUES ('20100302034247');

INSERT INTO schema_migrations (version) VALUES ('20100302214519');

INSERT INTO schema_migrations (version) VALUES ('20100302232800');

INSERT INTO schema_migrations (version) VALUES ('20100308222105');

INSERT INTO schema_migrations (version) VALUES ('20100309201437');

INSERT INTO schema_migrations (version) VALUES ('20100310184837');

INSERT INTO schema_migrations (version) VALUES ('20100311213738');

INSERT INTO schema_migrations (version) VALUES ('20100312005134');

INSERT INTO schema_migrations (version) VALUES ('20100312040437');

INSERT INTO schema_migrations (version) VALUES ('20100629152134');

INSERT INTO schema_migrations (version) VALUES ('20100629160714');

INSERT INTO schema_migrations (version) VALUES ('20110317033903');

INSERT INTO schema_migrations (version) VALUES ('20110317045358');

INSERT INTO schema_migrations (version) VALUES ('20110530231721');

INSERT INTO schema_migrations (version) VALUES ('20110530231844');

INSERT INTO schema_migrations (version) VALUES ('20110530234417');

INSERT INTO schema_migrations (version) VALUES ('20110614201821');

INSERT INTO schema_migrations (version) VALUES ('20110801000503');

INSERT INTO schema_migrations (version) VALUES ('20110802060439');

INSERT INTO schema_migrations (version) VALUES ('20110803054805');

INSERT INTO schema_migrations (version) VALUES ('20110809043113');

INSERT INTO schema_migrations (version) VALUES ('20120129214235');

INSERT INTO schema_migrations (version) VALUES ('20120305021107');

INSERT INTO schema_migrations (version) VALUES ('20120318110613');

INSERT INTO schema_migrations (version) VALUES ('20120423022536');

INSERT INTO schema_migrations (version) VALUES ('20120531055810');

INSERT INTO schema_migrations (version) VALUES ('20120612053133');

INSERT INTO schema_migrations (version) VALUES ('20120709002802');

INSERT INTO schema_migrations (version) VALUES ('20120715023358');

INSERT INTO schema_migrations (version) VALUES ('20120719025622');

INSERT INTO schema_migrations (version) VALUES ('20120719032933');

INSERT INTO schema_migrations (version) VALUES ('20120724043853');

INSERT INTO schema_migrations (version) VALUES ('20120914043532');

INSERT INTO schema_migrations (version) VALUES ('20120930023945');

INSERT INTO schema_migrations (version) VALUES ('20121003041206');

INSERT INTO schema_migrations (version) VALUES ('20121102035608');

INSERT INTO schema_migrations (version) VALUES ('20121218004820');

INSERT INTO schema_migrations (version) VALUES ('20130111213722');

INSERT INTO schema_migrations (version) VALUES ('20130225214830');

INSERT INTO schema_migrations (version) VALUES ('20130306065329');

INSERT INTO schema_migrations (version) VALUES ('20130312041530');

INSERT INTO schema_migrations (version) VALUES ('20130321184532');

INSERT INTO schema_migrations (version) VALUES ('20130322031345');

INSERT INTO schema_migrations (version) VALUES ('20130603021923');

INSERT INTO schema_migrations (version) VALUES ('20130603073427');

INSERT INTO schema_migrations (version) VALUES ('20130607054346');

INSERT INTO schema_migrations (version) VALUES ('20130612030753');

INSERT INTO schema_migrations (version) VALUES ('20130701235059');

INSERT INTO schema_migrations (version) VALUES ('20130708004128');

INSERT INTO schema_migrations (version) VALUES ('20130804204252');

INSERT INTO schema_migrations (version) VALUES ('20130817222533');

INSERT INTO schema_migrations (version) VALUES ('20130823053346');

INSERT INTO schema_migrations (version) VALUES ('20130826025935');

INSERT INTO schema_migrations (version) VALUES ('20131221173425');

INSERT INTO schema_migrations (version) VALUES ('20140219024717');

INSERT INTO schema_migrations (version) VALUES ('20140219024718');

INSERT INTO schema_migrations (version) VALUES ('20140515164704');

INSERT INTO schema_migrations (version) VALUES ('20140523152217');

INSERT INTO schema_migrations (version) VALUES ('20140801202550');

INSERT INTO schema_migrations (version) VALUES ('20140804171558');

INSERT INTO schema_migrations (version) VALUES ('20150508231646');

INSERT INTO schema_migrations (version) VALUES ('20150512235521');

INSERT INTO schema_migrations (version) VALUES ('20150821230410');

