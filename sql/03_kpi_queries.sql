-- =====================================================
-- 03_kpi_queries.sql
-- IT Service Desk & Support Ops - Core KPIs (PostgreSQL)
-- Schema: itsm
-- =====================================================

SET search_path TO itsm;

-- =====================================================
-- 0) Sanity checks
-- =====================================================

-- Row count (expect 100000)
SELECT COUNT(*) AS fact_ticket_rows
FROM fact_ticket;

-- Date range of dataset
SELECT
    MIN(created_time) AS min_created_time,
    MAX(created_time) AS max_created_time
FROM fact_ticket;

-- =====================================================
-- 1) Ticket volume
-- =====================================================

-- Total tickets
SELECT COUNT(*) AS total_tickets
FROM fact_ticket;

-- Ticket volume by day
SELECT
    DATE(created_time) AS created_date,
    COUNT(*) AS tickets
FROM fact_ticket
GROUP BY 1
ORDER BY 1;

-- Ticket volume by week
SELECT
    DATE_TRUNC('week', created_time) AS week_start,
    COUNT(*) AS tickets
FROM fact_ticket
GROUP BY 1
ORDER BY 1;

-- Ticket volume by month
SELECT
    DATE_TRUNC('month', created_time) AS month_start,
    COUNT(*) AS tickets
FROM fact_ticket
GROUP BY 1
ORDER BY 1;

-- Ticket volume by Source
SELECT
    source,
    COUNT(*) AS tickets
FROM fact_ticket
GROUP BY 1
ORDER BY tickets DESC;

-- Ticket volume by Priority
SELECT
    p.priority_name,
    COUNT(*) AS tickets
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
GROUP BY 1
ORDER BY tickets DESC;

-- Ticket volume by Topic
SELECT
    t.topic_name,
    COUNT(*) AS tickets
FROM fact_ticket f
JOIN dim_topic t ON f.topic_id = t.topic_id
GROUP BY 1
ORDER BY tickets DESC;

-- Ticket volume by Agent Group
SELECT
    ag.agent_group_name,
    COUNT(*) AS tickets
FROM fact_ticket f
JOIN dim_agent_group ag ON f.agent_group_id = ag.agent_group_id
GROUP BY 1
ORDER BY tickets DESC;

-- Ticket volume by Support Level
SELECT
    sl.support_level_name,
    COUNT(*) AS tickets
FROM fact_ticket f
JOIN dim_support_level sl ON f.support_level_id = sl.support_level_id
GROUP BY 1
ORDER BY tickets DESC;

-- Ticket volume by Country
SELECT
    c.country_name,
    COUNT(*) AS tickets
FROM fact_ticket f
JOIN dim_country c ON f.country_id = c.country_id
GROUP BY 1
ORDER BY tickets DESC;

-- =====================================================
-- 2) Backlog
-- =====================================================

-- Current backlog count (based on backlog_flag)
SELECT
    COUNT(*) AS backlog_tickets
FROM fact_ticket
WHERE backlog_flag = TRUE;

-- Backlog by Priority
SELECT
    p.priority_name,
    COUNT(*) AS backlog_tickets
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
WHERE f.backlog_flag = TRUE
GROUP BY 1
ORDER BY backlog_tickets DESC;

-- Backlog by Agent Group
SELECT
    ag.agent_group_name,
    COUNT(*) AS backlog_tickets
FROM fact_ticket f
JOIN dim_agent_group ag ON f.agent_group_id = ag.agent_group_id
WHERE f.backlog_flag = TRUE
GROUP BY 1
ORDER BY backlog_tickets DESC;

-- Backlog by Topic
SELECT
    t.topic_name,
    COUNT(*) AS backlog_tickets
FROM fact_ticket f
JOIN dim_topic t ON f.topic_id = t.topic_id
WHERE f.backlog_flag = TRUE
GROUP BY 1
ORDER BY backlog_tickets DESC;

-- Backlog trend (count of tickets created per day that are backlog now)
-- (This is "backlog composition by created date", not "backlog as of each day")
SELECT
    DATE(created_time) AS created_date,
    COUNT(*) AS backlog_tickets
FROM fact_ticket
WHERE backlog_flag = TRUE
GROUP BY 1
ORDER BY 1;

-- =====================================================
-- 3) SLA compliance
-- =====================================================

-- Response SLA compliance overall
SELECT
    ROUND(100.0 * AVG((response_sla_flag_bool)::int), 2) AS response_sla_compliance_pct
FROM fact_ticket;

-- Resolution SLA compliance overall
SELECT
    ROUND(100.0 * AVG((resolution_sla_flag_bool)::int), 2) AS resolution_sla_compliance_pct
FROM fact_ticket;

-- Response SLA compliance by Priority
SELECT
    p.priority_name,
    ROUND(100.0 * AVG((f.response_sla_flag_bool)::int), 2) AS response_sla_compliance_pct
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
GROUP BY 1
ORDER BY p.priority_name;

-- Resolution SLA compliance by Priority
SELECT
    p.priority_name,
    ROUND(100.0 * AVG((f.resolution_sla_flag_bool)::int), 2) AS resolution_sla_compliance_pct
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
GROUP BY 1
ORDER BY p.priority_name;

-- Response SLA compliance by Agent Group
SELECT
    ag.agent_group_name,
    ROUND(100.0 * AVG((f.response_sla_flag_bool)::int), 2) AS response_sla_compliance_pct
FROM fact_ticket f
JOIN dim_agent_group ag ON f.agent_group_id = ag.agent_group_id
GROUP BY 1
ORDER BY response_sla_compliance_pct;

-- Resolution SLA compliance by Agent Group
SELECT
    ag.agent_group_name,
    ROUND(100.0 * AVG((f.resolution_sla_flag_bool)::int), 2) AS resolution_sla_compliance_pct
FROM fact_ticket f
JOIN dim_agent_group ag ON f.agent_group_id = ag.agent_group_id
GROUP BY 1
ORDER BY resolution_sla_compliance_pct;

-- =====================================================
-- 4) Time to respond / resolve (median + p90)
-- =====================================================

-- Median first response minutes overall
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY first_response_minutes) AS median_first_response_minutes
FROM fact_ticket;

-- Median resolution minutes overall
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_minutes) AS median_resolution_minutes
FROM fact_ticket;

-- Median + p90 resolution minutes by Priority
SELECT
    p.priority_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.resolution_minutes) AS median_resolution_minutes,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY f.resolution_minutes) AS p90_resolution_minutes
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
GROUP BY 1
ORDER BY median_resolution_minutes;

-- Median + p90 first response minutes by Priority
SELECT
    p.priority_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.first_response_minutes) AS median_first_response_minutes,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY f.first_response_minutes) AS p90_first_response_minutes
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
GROUP BY 1
ORDER BY median_first_response_minutes;

-- Median resolution by Agent Group
SELECT
    ag.agent_group_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.resolution_minutes) AS median_resolution_minutes
FROM fact_ticket f
JOIN dim_agent_group ag ON f.agent_group_id = ag.agent_group_id
GROUP BY 1
ORDER BY median_resolution_minutes;

-- Median resolution by Topic
SELECT
    t.topic_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.resolution_minutes) AS median_resolution_minutes
FROM fact_ticket f
JOIN dim_topic t ON f.topic_id = t.topic_id
GROUP BY 1
ORDER BY median_resolution_minutes;

-- =====================================================
-- 5) Satisfaction KPIs
-- =====================================================

-- Satisfaction distribution (score 3/2/1)
SELECT
    satisfaction_score,
    COUNT(*) AS tickets,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM fact_ticket
GROUP BY 1
ORDER BY satisfaction_score DESC;

-- Satisfaction rate (Satisfied only)
SELECT
    ROUND(100.0 * AVG((satisfaction_score = 3)::int), 2) AS satisfaction_rate_pct
FROM fact_ticket;

-- Satisfaction rate by Priority
SELECT
    p.priority_name,
    ROUND(100.0 * AVG((f.satisfaction_score = 3)::int), 2) AS satisfaction_rate_pct
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
GROUP BY 1
ORDER BY satisfaction_rate_pct;

-- Satisfaction rate by Agent Group
SELECT
    ag.agent_group_name,
    ROUND(100.0 * AVG((f.satisfaction_score = 3)::int), 2) AS satisfaction_rate_pct
FROM fact_ticket f
JOIN dim_agent_group ag ON f.agent_group_id = ag.agent_group_id
GROUP BY 1
ORDER BY satisfaction_rate_pct;

-- Satisfaction rate by Topic
SELECT
    t.topic_name,
    ROUND(100.0 * AVG((f.satisfaction_score = 3)::int), 2) AS satisfaction_rate_pct
FROM fact_ticket f
JOIN dim_topic t ON f.topic_id = t.topic_id
GROUP BY 1
ORDER BY satisfaction_rate_pct;

-- =====================================================
-- 6) Workload proxy (agent interactions)
-- =====================================================

-- Avg interactions overall
SELECT
    ROUND(AVG(agent_interactions)::numeric, 2) AS avg_agent_interactions
FROM fact_ticket;

-- Avg interactions by Priority
SELECT
    p.priority_name,
    ROUND(AVG(f.agent_interactions)::numeric, 2) AS avg_agent_interactions
FROM fact_ticket f
JOIN dim_priority p ON f.priority_id = p.priority_id
GROUP BY 1
ORDER BY avg_agent_interactions DESC;

-- Interactions vs resolution (simple)
SELECT
    agent_interactions,
    COUNT(*) AS tickets,
    ROUND(AVG(resolution_minutes)::numeric, 2) AS avg_resolution_minutes
FROM fact_ticket
GROUP BY 1
ORDER BY agent_interactions;

-- =====================================================
-- 7) Optional: operational “top lists”
-- =====================================================

-- Top 10 topics by ticket volume
SELECT
    t.topic_name,
    COUNT(*) AS tickets
FROM fact_ticket f
JOIN dim_topic t ON f.topic_id = t.topic_id
GROUP BY 1
ORDER BY tickets DESC
LIMIT 10;

-- Top 10 agent groups by backlog
SELECT
    ag.agent_group_name,
    COUNT(*) AS backlog_tickets
FROM fact_ticket f
JOIN dim_agent_group ag ON f.agent_group_id = ag.agent_group_id
WHERE f.backlog_flag = TRUE
GROUP BY 1
ORDER BY backlog_tickets DESC
LIMIT 10;
