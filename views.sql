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
