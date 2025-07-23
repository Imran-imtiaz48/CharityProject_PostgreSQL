-- data.sql

-- Orphans
INSERT INTO orphans (full_name, birth_date, gender, country, additional_info) VALUES
('Ayaan Khan', '2015-03-12', 'Male', 'Pakistan', '{"hobbies": ["cricket", "drawing"], "health": "good"}'),
('Fatima Noor', '2013-08-22', 'Female', 'Bangladesh', '{"school": "Dhaka Public", "grade": "5th"}'),
('Ali Rehman', '2014-01-09', 'Male', 'India', '{"vaccinated": true, "guardian": "Uncle"}');

-- Donors
INSERT INTO donors (name, email, country, donation_preferences) VALUES
('Imran Ali', 'imran@example.com', 'UAE', '{"preferred_campaigns": ["Zakat", "Winter"]}'),
('Sarah Johnson', 'sarah.johnson@example.com', 'USA', '{"payment_method": "Credit Card"}');

-- Volunteers
INSERT INTO volunteers (name, email, phone, role, availability) VALUES
('Ahmed Musa', 'ahmed@example.com', '0501234567', 'Field Volunteer', '{"days": ["Monday", "Thursday"]}'),
('Maria Khalid', 'maria@example.com', '0509876543', 'Media Coordinator', '{"remote": true}');

-- Sponsors
INSERT INTO sponsors (name, contact_info, sponsored_since) VALUES
('WaterAid Foundation', 'contact@wateraid.org', '2021-06-01'),
('Masjid Builders Intl', 'info@masjidbuilders.org', '2020-01-15');

-- Projects
INSERT INTO projects (type, location, start_date, end_date, sponsor_id, metadata) VALUES
('Well', 'Karachi, Pakistan', '2024-01-10', '2024-03-15', 1, '{"depth": "150ft", "status": "Completed"}'),
('Mosque', 'Lahore, Pakistan', '2023-08-01', NULL, 2, '{"floors": 2, "imam": "Sheikh Usman"}');

-- Campaigns
INSERT INTO campaigns (name, type, start_date, end_date, goal_amount, status) VALUES
('Zakat Drive 2025', 'Zakat', '2025-02-01', '2025-04-01', 10000, 'Active'),
('Winter Relief', 'Winter', '2024-11-01', '2025-01-15', 15000, 'Active');

-- Donations
INSERT INTO donations (donor_id, campaign_id, amount, payment_details) VALUES
(1, 1, 500, '{"method": "Card", "transaction_id": "TXN123"}'),
(2, 2, 300, '{"method": "PayPal", "confirmation": "CONF456"}');

-- Feedback
INSERT INTO feedback (orphan_id, feedback_date, rating, comments) VALUES
(1, '2025-03-10', 5, 'Happy and well-settled in new shelter.'),
(2, '2025-04-12', 4, 'Needs educational support.');

-- Event Logs
INSERT INTO event_log (event_type, event_data) VALUES
('donation', '{"donor": "Imran Ali", "amount": 500}'),
('project_completion', '{"project": "Well", "status": "Completed"}');
