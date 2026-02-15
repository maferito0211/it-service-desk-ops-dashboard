## KPI Definitions

This document defines all Key Performance Indicators (KPIs) used in the project.  
Each KPI is calculated using a clear and consistent rule so that results are easy to understand, verify, and reproduce.

---

## Ticket Volume KPIs

### Tickets Created

**Definition:**  
The total number of support tickets created during a selected time period.

**Purpose:**  
Shows incoming workload and demand on the service desk.

**Calculation:**  
Count of tickets where the creation date falls within the selected period.

---

### Tickets Resolved

**Definition:**  
The total number of support tickets that were resolved during a selected time period.

**Purpose:**  
Shows how many tickets the service desk was able to complete.

**Calculation:**  
Count of tickets where the resolution date falls within the selected period.

---

## Backlog KPIs

### Open Backlog

**Definition:**  
The number of tickets that are currently not resolved.

**Purpose:**  
Shows how much unfinished work the service desk is carrying.

**Logic:**  
Tickets with status equal to Open, In Progress, or Pending.

---

### Backlog Aging

**Definition:**  
The age of open tickets measured as the time between ticket creation and the current date.

**Purpose:**  
Helps identify old tickets that may be at risk of breaching SLA targets.

**Calculation:**  
Current date minus ticket creation date.

**Aging Buckets:**

- 0 to 2 days
- 3 to 7 days
- 8 to 14 days
- 15 to 30 days
- Over 30 days

---

## Timeliness KPIs

### First Response Time

**Definition:**  
The amount of time it takes for the service desk to first respond to a ticket after it is created.

**Purpose:**  
Measures how quickly users receive an initial response.

**Calculation:**  
First response timestamp minus ticket creation timestamp.

**Unit:**  
Minutes

---

### Resolution Time

**Definition:**  
The total amount of time it takes to fully resolve a ticket after it is created.

**Purpose:**  
Measures how efficiently tickets are handled from start to finish.

**Calculation:**  
Resolution timestamp minus ticket creation timestamp.

**Unit:**  
Minutes

---

## SLA Performance KPIs

### Response SLA Met

**Definition:**  
Indicates whether the first response time meets the defined SLA target for the ticket priority.

**Purpose:**  
Tracks compliance with response time commitments.

**Logic:**  
First response time is less than or equal to the response SLA target.

**Result Type:**  
True or False

---

### Resolution SLA Met

**Definition:**  
Indicates whether the resolution time meets the defined SLA target for the ticket priority.

**Purpose:**  
Tracks compliance with resolution time commitments.

**Logic:**  
Resolution time is less than or equal to the resolution SLA target.

**Result Type:**  
True or False

---

### SLA Compliance Percentage

**Definition:**  
The percentage of tickets that meet their SLA targets.

**Purpose:**  
Provides a high-level view of overall SLA performance.

**Calculation:**  
Number of tickets that meet SLA divided by the total number of tickets with a valid SLA target and completed measurement (for example, resolved tickets when measuring resolution SLA).

---

### SLA Breach Rate

**Definition:**  
The percentage of tickets that fail to meet their SLA targets.

**Purpose:**  
Highlights how often service commitments are not met.

**Calculation:**  
Number of tickets that failed SLA divided by total applicable tickets.  
This is equivalent to one minus the SLA compliance percentage.

---

## Quality KPIs

### Reopen Rate

**Definition:**  
The percentage of resolved tickets that are reopened at least once.

**Purpose:**  
Indicates potential quality issues in ticket resolution.

**Calculation:**  
Number of resolved tickets with one or more reopens divided by total resolved tickets.

---

## Performance by Driver

### Queue Performance

**Definition:**  
Core KPIs calculated separately for each support queue or team.

**Purpose:**  
Identifies workload distribution and performance differences between teams.

**Common Metrics:**

- Ticket volume
- Median resolution time
- SLA compliance percentage

---

### Category Performance

**Definition:**  
Ticket performance metrics grouped by ticket category.

**Purpose:**  
Identifies which types of issues drive ticket volume, delays, or SLA breaches.

**Common Metrics:**

- Ticket volume
- Median resolution time
- SLA compliance percentage

---

## Notes

- All KPIs are calculated using the same logic across Python, SQL, and the dashboard.
- SLA targets are defined by ticket priority and documented separately.
- All time-based KPIs are calculated in minutes and displayed in hours or days when appropriate.

---

## SLA Targets per Priority

| Priority | Response SLA | Resolution SLA                                 |
| -------- | ------------ | ---------------------------------------------- |
| P1       | 4 hours      | 24 hours                                       |
| P2       | 8 hours      | 72 hours                                       |
| P3       | 24 hours     | 5 business days (approximately 7200 minutes)   |
| P4       | 48 hours     | 10 business days (approximately 14400 minutes) |
