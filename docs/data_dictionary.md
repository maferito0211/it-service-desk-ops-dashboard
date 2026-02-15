## Data Dictionary

This document defines each column in the IT Service Management dataset and lists the observed allowed values (extracted from the dataset you provided).
Columns are grouped by purpose to make the dataset easier to understand.

## Ticket Identification

### Ticket ID
- Data type: str
- Nulls: 0
- Unique values: 100000
- Description: Unique identifier for each ticket.
- Used for: Primary key in the database, deduplication checks, joins.
- Notes: High-cardinality identifier; treat as unique per ticket.

## Ticket Classification and Ownership

### Source
- Data type: str
- Nulls: 0
- Unique values: 4
- Description: Channel where the ticket was created.
- Used for: Volume by channel; filter/slicer in dashboard.
- Allowed values (from dataset):
  - Chat
  - Email
  - Phone
  - Portal

### Topic
- Data type: str
- Nulls: 0
- Unique values: 5
- Description: Issue topic or request type.
- Used for: Driver analysis; volume and SLA performance by topic.
- Allowed values (from dataset):
  - Access Request
  - General Inquiry
  - Hardware Failure
  - Network Issue
  - Software Bug

### Product group
- Data type: str
- Nulls: 0
- Unique values: 4
- Description: Product/service area linked to the ticket.
- Used for: Driver analysis; performance by product area.
- Allowed values (from dataset):
  - Cloud
  - Hardware
  - Network
  - Software

### Support Level
- Data type: str
- Nulls: 0
- Unique values: 3
- Description: Support tier handling the ticket.
- Used for: Segmentation by tier (L1/L2/L3); compare SLA and resolution time.
- Allowed values (from dataset):
  - L1
  - L2
  - L3

### Agent Group
- Data type: str
- Nulls: 0
- Unique values: 5
- Description: Support team responsible for handling the ticket.
- Used for: Queue/team performance (volume, SLA, resolution time).
- Allowed values (from dataset):
  - Customer Service
  - Development
  - IT Support
  - Network Ops
  - Security

### Agent Name
- Data type: str
- Nulls: 0
- Unique values: 80
- Description: Assigned support agent name.
- Used for: Optional drill-down analysis by agent (not used for employee evaluation in MVP).
- Notes: High-cardinality column. Showing top values is acceptable for documentation. (Full list is large.)

## Ticket Status and Lifecycle

### Status
- Data type: str
- Nulls: 0
- Unique values: 5
- Description: Current ticket state in the lifecycle.
- Used for: Backlog logic and status reporting.
- Allowed values (from dataset):
  - Closed
  - In Progress
  - New
  - Open
  - Resolved
- Notes: Recommended backlog definition for this project is Status in (New, Open, In Progress). Completed tickets are Status in (Resolved, Closed).

## Time and SLA Fields

Note: In the raw CSV these columns are strings; parse to datetime during cleaning.

### Created time
- Data type: datetime64[us]
- Nulls: 0
- Unique values: 77880
- Description: Timestamp when the ticket was created.
- Used for: Ticket volume over time; start point for all duration calculations.
- Raw file note: In the raw CSV these columns are strings; parse to datetime during cleaning.
- Minimum observed: 2024-04-01 0:01
- Maximum observed: 2024-08-12 3:57

### First response time
- Data type: datetime64[us]
- Nulls: 0
- Unique values: 77880
- Description: Timestamp when the first response occurred.
- Used for: First Response Time KPI; response SLA compliance.
- Raw file note: In the raw CSV these columns are strings; parse to datetime during cleaning.
- Minimum observed: 2024-04-01 0:06
- Maximum observed: 2024-08-12 3:58

### Resolution time
- Data type: datetime64[us]
- Nulls: 0
- Unique values: 77880
- Description: Timestamp when the ticket was resolved.
- Used for: Resolution Time KPI; resolution SLA compliance.
- Raw file note: In the raw CSV these columns are strings; parse to datetime during cleaning.
- Minimum observed: 2024-04-01 0:14
- Maximum observed: 2024-08-12 3:59

### Close time
- Data type: datetime64[us]
- Nulls: 0
- Unique values: 77880
- Description: Timestamp when the ticket was closed (administrative finalization).
- Used for: Optional analysis of time from resolved to closed; not used for resolution SLA.
- Raw file note: In the raw CSV these columns are strings; parse to datetime during cleaning.
- Minimum observed: 2024-04-01 0:52
- Maximum observed: 2024-08-12 3:59

### Expected SLA to first response
- Data type: datetime64[us]
- Nulls: 0
- Unique values: 77880
- Description: Deadline timestamp by which the first response must occur to meet the response SLA.
- Used for: Response SLA target (deadline) used to compute response SLA met/breached.
- Raw file note: In the raw CSV these columns are strings; parse to datetime during cleaning.
- Minimum observed: 2024-04-01 0:31
- Maximum observed: 2024-08-12 4:27

### Expected SLA to resolve
- Data type: datetime64[us]
- Nulls: 0
- Unique values: 77880
- Description: Deadline timestamp by which the ticket must be resolved to meet the resolution SLA.
- Used for: Resolution SLA target (deadline) used to compute resolution SLA met/breached.
- Raw file note: In the raw CSV these columns are strings; parse to datetime during cleaning.
- Minimum observed: 2024-04-01 1:01
- Maximum observed: 2024-08-12 7:57

## SLA Outcome Labels Provided in Dataset

Note: In this dataset, every ticket is marked as "Met" for both response SLA and resolution SLA. 
There are no tickets labeled as "Breached". 
This means the provided SLA flags do not show any SLA failures. 
For this reason, SLA performance must be independently recalculated by comparing the actual timestamps against the SLA deadline timestamps.

### SLA For first response
- Data type: str
- Nulls: 0
- Unique values: 1
- Description: Provided label indicating whether the response SLA was met.
- Used for: Reconciliation only: compare against recalculated response SLA result.
- Allowed values (from dataset):
  - Met
- Notes: In this dataset the observed value set contains only Met. The project will recalculate SLA compliance to validate this.

### SLA For Resolution
- Data type: str
- Nulls: 0
- Unique values: 1
- Description: Provided label indicating whether the resolution SLA was met.
- Used for: Reconciliation only: compare against recalculated resolution SLA result.
- Allowed values (from dataset):
  - Met
- Notes: In this dataset the observed value set contains only Met. The project will recalculate SLA compliance to validate this.

## Workload and Quality

### Agent interactions
- Data type: int64
- Nulls: 0
- Unique values: 5
- Description: Count of interactions/updates logged for the ticket.
- Used for: Workload proxy; analysis of complexity vs resolution time.
- Minimum observed: 1
- Maximum observed: 5
- Notes: Use as numeric measure of effort and communication volume.

### Survey results
- Data type: str
- Nulls: 0
- Unique values: 3
- Description: Customer satisfaction outcome after ticket completion.
- Used for: Satisfaction KPIs and analysis of satisfaction vs SLA, priority, and agent group.
- Allowed values (from dataset):
  - Dissatisfied
  - Neutral
  - Satisfied

## Location

### Country
- Data type: str
- Nulls: 0
- Unique values: 6
- Description: Country associated with the ticket.
- Used for: Geographic breakdown and filtering.
- Allowed values (from dataset):
  - Bahrain
  - Kuwait
  - Oman
  - Qatar
  - Saudi Arabia
  - UAE

### Latitude
- Data type: float64
- Nulls: 0
- Unique values: 77880
- Description: Latitude coordinate for the ticket location.
- Used for: Optional map visualization; location validation (range checks).
- Minimum observed: 21.8477
- Maximum observed: 26.0476

### Longitude
- Data type: float64
- Nulls: 0
- Unique values: 77880
- Description: Longitude coordinate for the ticket location.
- Used for: Optional map visualization; location validation (range checks).
- Minimum observed: 50.0116
- Maximum observed: 56.0

## Derived Columns Created in This Project

The following columns are created during transformation (they are not in the raw dataset).

### first_response_minutes
- Data type: numeric
- Description: Minutes between Created time and First response time.
- Formula: (First response time - Created time) in minutes.

### resolution_minutes
- Data type: numeric
- Description: Minutes between Created time and Resolution time.
- Formula: (Resolution time - Created time) in minutes.

### response_sla_met_recalc
- Data type: boolean
- Description: Recalculated response SLA outcome.
- Logic: First response time <= Expected SLA to first response.

### resolution_sla_met_recalc
- Data type: boolean
- Description: Recalculated resolution SLA outcome.
- Logic: Resolution time <= Expected SLA to resolve.

### backlog_flag
- Data type: boolean
- Description: Flags tickets that are considered open backlog.
- Logic: Status in (New, Open, In Progress).

### satisfaction_score
- Data type: integer
- Description: Numeric satisfaction score for analysis.
- Mapping: Satisfied = 3, Neutral = 2, Dissatisfied = 1.


