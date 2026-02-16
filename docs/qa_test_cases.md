# QA Test Cases — ITSM Analytics Warehouse (Day 5)

## Scope
Validate that:
1) Processed CSV → Postgres load is correct
2) Dimensions + fact table are consistent
3) Core KPIs match CSV (reconciliation)

## Expected Source Artifacts
- data/processed/itsm_clean.csv
- Postgres DB: itsm_analytics
- Schema: itsm
- Tables: fact_ticket, dim_priority, dim_status, dim_agent_group, dim_topic, dim_country, dim_support_level

---

## A) Row counts

### A1 — Fact row count
**Test:** `SELECT COUNT(*) FROM itsm.fact_ticket;`  
**Expected:** `100000`

### A2 — Ticket ID uniqueness
**Test:** Group and count duplicates on ticket_id  
**Expected:** `0 duplicate ticket_id`

---

## B) Dimension counts (from data dictionary)

### B1 — dim_priority
**Expected:** 4 values (Low, Medium, High, Critical)

### B2 — dim_status
**Expected:** 5 values (Closed, In Progress, New, Open, Resolved)

### B3 — dim_agent_group
**Expected:** 5 values (Customer Service, Development, IT Support, Network Ops, Security)

### B4 — dim_topic
**Expected:** 5 values (Access Request, General Inquiry, Hardware Failure, Network Issue, Software Bug)

### B5 — dim_country
**Expected:** 6 values (Bahrain, Kuwait, Oman, Qatar, Saudi Arabia, UAE)

### B6 — dim_support_level
**Expected:** 3 values (L1, L2, L3)

---

## C) Integrity

### C1 — No orphan foreign keys
**Test:** left join fact → dim and count NULLs  
**Expected:** 0 orphaned rows for each dim key

### C2 — Timestamp chronology
**Rule:** Created <= First Response <= Resolution <= Close  
**Expected:** 0 violations

### C3 — Non-negative durations
**Rule:** first_response_minutes >= 0 and resolution_minutes >= 0  
**Expected:** 0 violations

---

## D) Business rule validation

### D1 — Backlog flag logic
**Rule:** backlog_flag is TRUE iff Status in (New, Open, In Progress)  
**Expected:** 0 mismatches

---

## E) KPI reconciliation (CSV vs SQL)

### E1 — Total tickets
**Expected:** exact match (100000)

### E2 — SLA compliance
Using response_sla_flag_bool and resolution_sla_flag_bool.  
**Expected:** SQL % == CSV % (exact match)

### E3 — Median resolution time
**Expected:** SQL median == CSV median (within tiny tolerance)

### E4 — Satisfaction rate
Satisfied = satisfaction_score 3  
**Expected:** SQL % == CSV % (exact match)

---

## Run Instructions
From project root:
`pytest -q`
Expected: all tests PASS.
