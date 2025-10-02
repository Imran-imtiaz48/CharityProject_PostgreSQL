# Charity Project in PostgreSQL

The PostgreSQL-based project is designed for a charity organization that manages orphans, projects (wells, mosques), and various campaigns (summer, winter, zakat). The project uses advanced PostgreSQL features including views, functions, JSONB, audit logging, MVCC version tracking, and disaster recovery mechanisms.

## 🔧 Features

### Core Tables

* **orphans**: Stores orphan details.
* **donors**: Stores donor information.
* **projects**: Includes project details such as wells and mosques.
* **campaigns**: Handles seasonal campaigns like Summer, Winter, and Zakat.
* **donations**: Tracks donations linked to donors, orphans, projects, or campaigns.

### JSONB Usage

* Metadata and extended information is stored in JSONB format for flexible querying and storage.

### Views

* Comprehensive SQL views for:

  * Orphan sponsorship details
  * Donation statistics
  * Campaign donation summary
  * Project progress reports

### Functions & Stored Procedures

* Get top N donors in a date range
* Return projects nearing completion
* Auto-calculate sponsorship duration
* Summarize monthly donations
* Generate campaign donation reports

### Triggers & Auditing

* Audit tables track changes in orphans, donations, and projects.
* Each insert, update, and delete is logged with a timestamp.

### MVCC (Multi-Version Concurrency Control)

* **Custom MVCC Implementation** to track historical changes without overwriting existing data.
* Tables store multiple versions of each record using `valid_from` and `valid_to` timestamps.
* **Triggers** automatically insert a new row version on updates.
* **Functions** to:

  * Retrieve the current active version of a record
  * Retrieve all historical versions
  * Restore older versions if needed
* Demonstrates how PostgreSQL’s concurrency model can be implemented and extended at the schema level.

### Disaster Recovery

* Backup (shadow) tables with triggers to maintain real-time backups.
* Procedures to restore tables from backup.
* Detection mechanisms for tampering or unauthorized deletions.

## 📁 File Structure

* `schema.sql` — Table definitions
* `data.sql` — Sample data insertion
* `views.sql` — SQL views
* `functions.sql` — Functions for analytics and business logic
* `storedProcedures.sql` — Stored procedures for complex operations
* `triggers_auditing.sql` — Triggers and audit logs
* `mvcc_demo_schema.sql` — MVCC-enabled table, triggers, and functions
* `disaster_recovery.sql` — Recovery and backup scripts
* `diagram.png` — ERD diagram for understanding schema

## 🌐 Real-time Data

This project is structured to easily incorporate real-time external data (e.g. exchange rates or donor validation APIs) through extensions or application layers.

## 🚀 How to Use

1. Clone the repository:

```bash
git clone https://github.com/Imran-imtiaz48/CharityProject_PostgreSQL.git
cd CharityProject_PostgreSQL
```

2. Run scripts in PostgreSQL:

```sql
\i schema.sql
\i data.sql
\i views.sql
\i functions.sql
\i storedProcedures.sql
\i triggers_auditing.sql
\i mvcc_demo_schema.sql
\i disaster_recovery.sql
```

3. Explore and expand!

## 📷 ERD Preview

![ERD](diagram.png)

---

This project demonstrates real-world database architecture, maintainability, and data protection best practices, including version control for data changes through MVCC.

---
