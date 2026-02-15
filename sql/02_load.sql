--staging table creation
SET search_path TO itsm;

CREATE TABLE staging_ticket_raw (
    status TEXT,
    ticket_id TEXT,
    priority TEXT,
    source TEXT,
    topic TEXT,
    agent_group TEXT,
    agent_name TEXT,
    created_time TEXT,
    expected_sla_to_resolve TEXT,
    expected_sla_to_first_response TEXT,
    first_response_time TEXT,
    sla_for_first_response TEXT,

    resolution_time TEXT,
    sla_for_resolution TEXT,
    close_time TEXT,
    agent_interactions TEXT,
    survey_results TEXT,
    product_group TEXT,
    support_level TEXT,
    country TEXT,
    latitude TEXT,
    longitude TEXT,
    first_response_minutes TEXT,
    resolution_minutes TEXT,
    response_sla_met_recalc TEXT,
    resolution_sla_met_recalc TEXT,
    response_sla_flag_bool TEXT,
    resolution_sla_flag_bool TEXT,
    backlog_flag TEXT,
    satisfaction_score TEXT
);


--import the clean csv before next step
--Populate dimensions using TRIM + ON CONFLICT
INSERT INTO dim_priority (priority_name)
SELECT DISTINCT TRIM(priority)
FROM staging_ticket_raw
ON CONFLICT (priority_name) DO NOTHING;

INSERT INTO dim_status (status_name)
SELECT DISTINCT TRIM(status)
FROM staging_ticket_raw
ON CONFLICT (status_name) DO NOTHING;

INSERT INTO dim_agent_group (agent_group_name)
SELECT DISTINCT TRIM(agent_group)
FROM staging_ticket_raw
ON CONFLICT (agent_group_name) DO NOTHING;

INSERT INTO dim_topic (topic_name)
SELECT DISTINCT TRIM(topic)
FROM staging_ticket_raw
ON CONFLICT (topic_name) DO NOTHING;

INSERT INTO dim_country (country_name)
SELECT DISTINCT TRIM(country)
FROM staging_ticket_raw
ON CONFLICT (country_name) DO NOTHING;

INSERT INTO dim_support_level (support_level_name)
SELECT DISTINCT TRIM(support_level)
FROM staging_ticket_raw
ON CONFLICT (support_level_name) DO NOTHING;



--Insert into fact table (typed)


SET search_path TO itsm;

-- Optional: load clean each time
TRUNCATE TABLE fact_ticket;

INSERT INTO fact_ticket (
    ticket_id,
    priority_id,
    status_id,
    agent_group_id,
    topic_id,
    country_id,
    support_level_id,
    source,
    agent_name,
    product_group,
    created_time,
    first_response_time,
    resolution_time,
    close_time,
    expected_sla_first_response,
    expected_sla_resolution,
    first_response_minutes,
    resolution_minutes,
    response_sla_flag_bool,
    resolution_sla_flag_bool,
    backlog_flag,
    satisfaction_score,
    agent_interactions,
    survey_results,
    latitude,
    longitude
)
SELECT
    TRIM(s.ticket_id),

    p.priority_id,
    st.status_id,
    ag.agent_group_id,
    t.topic_id,
    c.country_id,
    sl.support_level_id,

    TRIM(s.source),
    TRIM(s.agent_name),
    TRIM(s.product_group),

    NULLIF(TRIM(s.created_time), '')::timestamp,
    NULLIF(TRIM(s.first_response_time), '')::timestamp,
    NULLIF(TRIM(s.resolution_time), '')::timestamp,
    NULLIF(TRIM(s.close_time), '')::timestamp,

    NULLIF(TRIM(s.expected_sla_to_first_response), '')::timestamp,
    NULLIF(TRIM(s.expected_sla_to_resolve), '')::timestamp,

    NULLIF(TRIM(s.first_response_minutes), '')::numeric,
    NULLIF(TRIM(s.resolution_minutes), '')::numeric,

    NULLIF(TRIM(s.response_sla_flag_bool), '')::boolean,
    NULLIF(TRIM(s.resolution_sla_flag_bool), '')::boolean,
    NULLIF(TRIM(s.backlog_flag), '')::boolean,

    NULLIF(TRIM(s.satisfaction_score), '')::int,
    NULLIF(TRIM(s.agent_interactions), '')::int,

    TRIM(s.survey_results),

    NULLIF(TRIM(s.latitude), '')::numeric,
    NULLIF(TRIM(s.longitude), '')::numeric
FROM staging_ticket_raw s
JOIN dim_priority p ON TRIM(s.priority) = p.priority_name
JOIN dim_status st ON TRIM(s.status) = st.status_name
JOIN dim_agent_group ag ON TRIM(s.agent_group) = ag.agent_group_name
JOIN dim_topic t ON TRIM(s.topic) = t.topic_name
JOIN dim_country c ON TRIM(s.country) = c.country_name
JOIN dim_support_level sl ON TRIM(s.support_level) = sl.support_level_name;