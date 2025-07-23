# CharityConnect PostgreSQL Project

CharityConnect is a fully structured PostgreSQL-based database project built to support the operational needs of a charitable organization. It includes support for managing orphans, projects (like wells and mosques), seasonal campaigns (summer, winter, zakat), donations, and volunteer coordination. The project is built entirely in PostgreSQL (no Python or other language used), with real-time JSONB data usage, custom functions, views, and event logging.

## 🔧 Technologies Used

* PostgreSQL 15+
* JSONB columns for flexible data
* PL/pgSQL for user-defined functions
* Views and triggers for advanced querying

## 📁 Project Structure

```
CharityConnect_PostgreSQL/
├── schema.sql            # Database tables and structure
├── data.sql              # Sample data for all tables
├── views.sql             # Defined reusable views
├── functions.sql         # User-defined functions in PL/pgSQL
├── README.md             # Project overview and setup guide
└── CharityConnect_Full_PostgreSQL.zip
```

## 📦 Tables Included

* `orphans`: Information about orphan children
* `projects`: Details about water wells, mosques, etc.
* `campaigns`: Seasonal and donation campaigns (summer, winter, zakat)
* `donors`: People who contribute funds
* `donations`: Donation records
* `volunteers`: Volunteers and their availability (JSONB)
* `feedback`: Feedback submitted on support and projects
* `event_log`: System logging for JSONB event tracking

## 🔍 Views

* `view_orphan_details`
* `view_active_campaigns`
* `view_donations_summary`
* `view_project_impact`

## 🧠 Functions

* `calculate_total_donations_for_campaign(id)`
* `get_orphan_json_summary(id)`
* `log_event(type, jsonb)`
* `get_active_campaigns_by_type(type)`
* `get_volunteer_availability_json(volunteer_id)`

## 🌐 Real-time Data

Used JSONB columns in `volunteers` and `orphans` for storing flexible real-world data including:

* Availability schedules
* Dynamic feedback
* Donor metadata

## ⚙️ Setup Instructions

1. Make sure PostgreSQL is installed (`version 15+` recommended).
2. Create a database:
   `CREATE DATABASE charity_connect;`
3. Load schema:
   `psql -d charity_connect -f schema.sql`
4. Insert data:
   `psql -d charity_connect -f data.sql`
5. Create views:
   `psql -d charity_connect -f views.sql`
6. Load functions:
   `psql -d charity_connect -f functions.sql`

## 📌 Contribution Ideas

* Add triggers for automatic updates
* Create audit logging on donation changes
* Expand with region-based projects (countries, zones)
* Integrate with APIs using PostgreSQL foreign data wrappers (FDW)

