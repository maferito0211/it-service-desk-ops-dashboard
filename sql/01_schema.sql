CREATE SCHEMA IF NOT EXISTS itsm;
SET search_path TO itsm;

CREATE TABLE dim_priority (
    priority_id SERIAL PRIMARY KEY,
    priority_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE dim_status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE dim_agent_group (
    agent_group_id SERIAL PRIMARY KEY,
    agent_group_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE dim_topic (
    topic_id SERIAL PRIMARY KEY,
    topic_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE dim_country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE dim_support_level (
    support_level_id SERIAL PRIMARY KEY,
    support_level_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE fact_ticket (
    ticket_id VARCHAR(50) PRIMARY KEY,

    priority_id INT REFERENCES dim_priority(priority_id),
    status_id INT REFERENCES dim_status(status_id),
    agent_group_id INT REFERENCES dim_agent_group(agent_group_id),
    topic_id INT REFERENCES dim_topic(topic_id),
    country_id INT REFERENCES dim_country(country_id),
    support_level_id INT REFERENCES dim_support_level(support_level_id),

    source VARCHAR(50),
    agent_name VARCHAR(100),
    product_group VARCHAR(100),

    created_time TIMESTAMP NOT NULL,
    first_response_time TIMESTAMP,
    resolution_time TIMESTAMP,
    close_time TIMESTAMP,

    expected_sla_first_response TIMESTAMP,
    expected_sla_resolution TIMESTAMP,

    first_response_minutes NUMERIC,
    resolution_minutes NUMERIC,

    response_sla_flag_bool BOOLEAN,
    resolution_sla_flag_bool BOOLEAN,
    backlog_flag BOOLEAN,

    satisfaction_score INT,
    agent_interactions INT,

    survey_results VARCHAR(50),

    latitude NUMERIC,
    longitude NUMERIC
);

CREATE INDEX idx_fact_created_time ON fact_ticket(created_time);
CREATE INDEX idx_fact_priority ON fact_ticket(priority_id);
CREATE INDEX idx_fact_status ON fact_ticket(status_id);
CREATE INDEX idx_fact_agent_group ON fact_ticket(agent_group_id);
CREATE INDEX idx_fact_topic ON fact_ticket(topic_id);
CREATE INDEX idx_fact_country ON fact_ticket(country_id);
