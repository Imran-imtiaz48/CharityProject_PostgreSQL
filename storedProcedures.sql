-- =========================================
-- Procedure: generate_monthly_donation_summary
-- Description: Summarizes total donations per donor for the previous month
-- Inserts summary data into donor_monthly_summary table
-- =========================================
CREATE OR REPLACE PROCEDURE generate_monthly_donation_summary()
LANGUAGE plpgsql
AS $$
DECLARE
    month_start DATE := date_trunc('month', CURRENT_DATE) - INTERVAL '1 month';
    month_end DATE := date_trunc('month', CURRENT_DATE) - INTERVAL '1 day';
BEGIN
    DELETE FROM donor_monthly_summary
    WHERE summary_month = month_start;

    INSERT INTO donor_monthly_summary (donor_id, donor_name, total_amount, summary_month)
    SELECT
        d.donor_id,
        d.full_name,
        SUM(don.amount),
        month_start
    FROM donors d
    JOIN donations don ON d.donor_id = don.donor_id
    WHERE don.donation_date BETWEEN month_start AND month_end
    GROUP BY d.donor_id, d.full_name;

    RAISE NOTICE 'Monthly donation summary generated for % to %', month_start, month_end;
END;
$$;

-- =========================================
-- Procedure: get_projects_nearing_completion
-- Description: Lists projects not completed yet that are ending within next 30 days
-- =========================================
CREATE OR REPLACE PROCEDURE get_projects_nearing_completion()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Projects nearing completion (within 30 days):';

    RETURN QUERY
    SELECT p.project_id, p.name, p.status_id, ps.status_name, p.end_date
    FROM projects p
    JOIN project_status ps ON p.status_id = ps.status_id
    WHERE ps.status_name != 'Completed'
      AND p.end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days';
END;
$$;

-- =========================================
-- Procedure: calculate_sponsorship_duration
-- Description: Calculates total sponsorship duration in months for a given orphan
-- Parameter: p_orphan_id INT - ID of the orphan
-- =========================================
CREATE OR REPLACE PROCEDURE calculate_sponsorship_duration(p_orphan_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    sponsorship_start DATE;
    sponsorship_end DATE := CURRENT_DATE;
    duration_months INT;
BEGIN
    SELECT MIN(d.donation_date) INTO sponsorship_start
    FROM donations d
    WHERE d.orphan_id = p_orphan_id;

    IF sponsorship_start IS NULL THEN
        RAISE NOTICE 'Orphan % has no sponsorships.', p_orphan_id;
        RETURN;
    END IF;

    duration_months := DATE_PART('year', sponsorship_end) * 12 + DATE_PART('month', sponsorship_end)
                      - DATE_PART('year', sponsorship_start) * 12 - DATE_PART('month', sponsorship_start);

    RAISE NOTICE 'Orphan % has been sponsored for % months.', p_orphan_id, duration_months;
END;
$$;

-- =========================================
-- Procedure: generate_campaign_donation_summary
-- Description: Generates summary of total donors and total donations per campaign
-- =========================================
CREATE OR REPLACE PROCEDURE generate_campaign_donation_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Campaign Donation Summary:';

    RETURN QUERY
    SELECT
        c.campaign_id,
        c.name AS campaign_name,
        COUNT(DISTINCT d.donor_id) AS total_donors,
        SUM(d.amount) AS total_donations
    FROM campaigns c
    LEFT JOIN donations d ON c.campaign_id = d.campaign_id
    GROUP BY c.campaign_id, c.name
    ORDER BY total_donations DESC;
END;
$$;
