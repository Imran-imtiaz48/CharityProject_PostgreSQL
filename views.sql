-- View to display all orphans with their assigned project and campaign (if any)
CREATE OR REPLACE VIEW view_orphan_details AS
SELECT
  o.orphan_id,
  o.name AS orphan_name,
  o.date_of_birth,
  o.gender,
  o.country,
  o.status,
  p.project_name,
  c.campaign_name
FROM orphans o
LEFT JOIN projects p ON o.assigned_project_id = p.project_id
LEFT JOIN campaigns c ON o.assigned_campaign_id = c.campaign_id;

-- View to get summary of donations per campaign
CREATE OR REPLACE VIEW view_donations_summary AS
SELECT
  c.campaign_name,
  SUM(d.amount) AS total_donated,
  COUNT(d.donation_id) AS total_transactions
FROM donations d
JOIN campaigns c ON d.campaign_id = c.campaign_id
GROUP BY c.campaign_name;

-- View to list all active campaigns
CREATE OR REPLACE VIEW view_active_campaigns AS
SELECT
  campaign_id,
  campaign_name,
  start_date,
  end_date,
  description
FROM campaigns
WHERE CURRENT_DATE BETWEEN start_date AND end_date;

-- View to analyze project reach and orphan assignment
CREATE OR REPLACE VIEW view_project_impact AS
SELECT
  p.project_id,
  p.project_name,
  p.project_type,
  COUNT(o.orphan_id) AS orphans_supported,
  COUNT(DISTINCT d.donation_id) AS donations_received
FROM projects p
LEFT JOIN orphans o ON o.assigned_project_id = p.project_id
LEFT JOIN donations d ON d.project_id = p.project_id
GROUP BY p.project_id, p.project_name, p.project_type;

-- View to show JSON summary of volunteers and their availability
CREATE OR REPLACE VIEW view_volunteer_json_summary AS
SELECT
  volunteer_id,
  name,
  contact_info,
  availability_jsonb
FROM volunteers;

CREATE OR REPLACE VIEW orphan_full_profile AS
SELECT
    o.id AS orphan_id,
    jsonb_build_object(
        'name', o.full_name,
        'dob', o.date_of_birth,
        'age', date_part('year', age(o.date_of_birth)),
        'gender', o.gender,
        'project', p.project_name,
        'campaign', c.campaign_name
    ) AS orphan_profile
FROM orphan o
LEFT JOIN orphan_project op ON o.id = op.orphan_id
LEFT JOIN project p ON op.project_id = p.id
LEFT JOIN campaign_orphan co ON o.id = co.orphan_id
LEFT JOIN campaign c ON co.campaign_id = c.id;

CREATE OR REPLACE VIEW campaign_donation_summary AS
SELECT
    c.campaign_name,
    c.season,
    COUNT(d.id) AS total_donations,
    SUM(d.amount) AS total_amount_raised,
    RANK() OVER (ORDER BY SUM(d.amount) DESC) AS rank_by_donation
FROM campaign c
LEFT JOIN donation d ON d.campaign_id = c.id
GROUP BY c.id;

CREATE OR REPLACE VIEW project_status_overview AS
SELECT
    p.id,
    p.project_name,
    p.type,
    p.start_date,
    p.end_date,
    CASE
        WHEN p.end_date IS NULL THEN 'Ongoing'
        WHEN p.end_date <= CURRENT_DATE THEN 'Completed'
        ELSE 'Planned'
    END AS status
FROM project p;

CREATE OR REPLACE VIEW infrastructure_by_country AS
SELECT
    country,
    type,
    COUNT(*) AS project_count
FROM project
GROUP BY country, type
ORDER BY project_count DESC;

CREATE OR REPLACE VIEW campaign_orphans_json AS
SELECT
    c.campaign_name,
    jsonb_agg(
        jsonb_build_object(
            'orphan_id', o.id,
            'name', o.full_name,
            'dob', o.date_of_birth
        )
    ) AS orphans
FROM campaign c
JOIN campaign_orphan co ON c.id = co.campaign_id
JOIN orphan o ON o.id = co.orphan_id
GROUP BY c.id;

CREATE OR REPLACE VIEW donor_impact AS
SELECT
    d.name AS donor_name,
    COUNT(DISTINCT don.project_id) AS projects_supported,
    SUM(don.amount) AS total_donated
FROM donor d
JOIN donation don ON don.donor_id = d.id
GROUP BY d.name
ORDER BY total_donated DESC;

CREATE OR REPLACE VIEW recent_donations AS
SELECT
    d.name AS donor_name,
    do.amount,
    do.currency,
    do.donated_at,
    p.project_name,
    c.campaign_name
FROM donation do
LEFT JOIN donor d ON d.id = do.donor_id
LEFT JOIN project p ON p.id = do.project_id
LEFT JOIN campaign c ON c.id = do.campaign_id
WHERE do.donated_at >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY do.donated_at DESC;

