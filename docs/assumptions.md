## Data Assumptions

- Each ticket is identified by a unique ticket ID.
- Ticket timestamps such as creation and resolution times are assumed to be correct unless clearly invalid.
- Tickets without a resolution timestamp are treated as open tickets.
- Each ticket priority is linked to one fixed SLA target, and that rule is applied the same way throughout the project.

## SLA Assumptions

- SLA targets are defined based on ticket priority.
- Each priority level is linked to one fixed SLA target.
- The same SLA target for a given priority is used in Python, SQL, and the dashboard.
- SLA targets are documented and not changed dynamically.

## Time Calculation Assumptions

- First response time is calculated as the difference between ticket creation time and the earliest available response or status update timestamp.
- Resolution time is calculated as the difference between ticket creation time and resolution time.
- Business hours, weekends, and holidays are not considered unless explicitly supported by the dataset.

Resolved status indicates technical completion of the ticket.
Closed status indicates administrative finalization.
SLA performance is measured using resolution time.
Backlog excludes both Resolved and Closed tickets.
