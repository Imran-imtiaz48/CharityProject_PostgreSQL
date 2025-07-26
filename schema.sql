-- schema.sql

CREATE TABLE orphans (
    orphan_id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    birth_date DATE NOT NULL,
    gender TEXT CHECK (gender IN ('Male', 'Female')),
    country TEXT,
    additional_info JSONB
);

CREATE TABLE donors (
    donor_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    country TEXT,
    donation_preferences JSONB
);

CREATE TABLE volunteers (
    volunteer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    role TEXT,
    availability JSONB
);

CREATE TABLE sponsors (
    sponsor_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    contact_info TEXT,
    sponsored_since DATE
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    type TEXT CHECK (type IN ('Well', 'Mosque', 'School', 'Clinic')),
    location TEXT NOT NULL,
    start_date DATE,
    end_date DATE,
    sponsor_id INT REFERENCES sponsors(sponsor_id),
    metadata JSONB
);

CREATE TABLE campaigns (
    campaign_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT CHECK (type IN ('Zakat', 'Ramadan', 'Summer', 'Winter')),
    start_date DATE,
    end_date DATE,
    goal_amount NUMERIC,
    status TEXT CHECK (status IN ('Active', 'Closed'))
);

CREATE TABLE donations (
    donation_id SERIAL PRIMARY KEY,
    donor_id INT REFERENCES donors(donor_id),
    campaign_id INT REFERENCES campaigns(campaign_id),
    amount NUMERIC NOT NULL,
    donated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_details JSONB
);

CREATE TABLE feedback (
    feedback_id SERIAL PRIMARY KEY,
    orphan_id INT REFERENCES orphans(orphan_id),
    feedback_date DATE,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comments TEXT
);

CREATE TABLE event_log (
    event_id SERIAL PRIMARY KEY,
    event_type TEXT,
    event_data JSONB,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS donor_monthly_summary (
    donor_id INT NOT NULL,
    donor_name TEXT NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    summary_month DATE NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (donor_id, summary_month)
);
