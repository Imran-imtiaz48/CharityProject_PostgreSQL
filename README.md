# CharityProject\_PostgreSQL

A comprehensive PostgreSQL project designed for managing data in a charity organization. This project simulates real-world operations such as managing orphans, donors, projects (wells, mosques), and seasonal campaigns (zakat, summer, winter), with a strong emphasis on reporting, analytics, and audit logging.

## 🌟 Key Features

### 📂 Schema Design

* **Orphans**: Manage orphan records including age, gender, and sponsorship status.
* **Projects**: Track charitable projects such as wells and mosques, their locations, and status.
* **Campaigns**: Organize zakat, summer, and winter donation campaigns with metadata.
* **Donations**: Manage donations from donors linked to specific campaigns or projects.
* **Sponsors & Donors**: Track donor contributions and sponsorships.

### 🔍 Views

* `view_orphan_details`: Detailed view of orphans with sponsorship info.
* `view_project_status`: Monitor ongoing and completed projects.
* `view_campaign_summary`: Overview of donation stats by campaign.
* `view_top_donors`: Top donors by amount and frequency.
* `view_upcoming_projects`: Filter projects nearing start or completion.
* `view_recent_donations`: Donations made in the last 30 days.

### ⚙️ Functions

* `get_top_donors(limit, start_date, end_date)`: Returns top N donors in a date range.
* `get_near_completion_projects()`: Returns projects about to be completed.
* `calculate_sponsorship_duration(orphan_id)`: Returns how long a sponsor has supported an orphan.
* `campaign_donation_total(campaign_id)`: Returns total donations for a specific campaign.

### 🔁 Triggers & Audit Logs

* **Audit tables** track INSERT, UPDATE, and DELETE actions on the `donations` table.
* Triggers automatically store change logs with timestamps and previous vs. new values.
* File: `triggers_auditing.sql`

### 🔐 Security and Constraints

* **Custom constraints** ensure data integrity like minimum donation amount.
* **Row Level Security (planned)** for future support of role-based access control.

---

## 🗂️ Project Structure

```
CharityProject_PostgreSQL/
├── schema.sql              # Tables and constraints
├── data.sql                # Sample data for all tables
├── views.sql               # Analytical and reporting views
├── functions.sql           # User-defined functions
├── triggers_auditing.sql   # Triggers and audit log implementation
├── README.md               # Project documentation
└── diagram.png             # ERD diagram for project visualization
```

---

## 🧐 Real-World Simulation

* Uses **real-time donation data** fetched from a live API and stored in JSONB format.
* Handles **seasonal campaigns** like Zakat, Winter Aid, and Summer Relief.
* Designed for scalability, reporting, and integration with external applications or dashboards.

---

## 🔗 GitHub Repository

[📁 View on GitHub](https://github.com/Imran-imtiaz48/CharityProject_PostgreSQL)

---

## 📌 Next Steps

* Add Role-Based Access Control via PostgreSQL policies
* Build a Power BI Dashboard from this dataset
* Add Scheduled Procedures for monthly reports
