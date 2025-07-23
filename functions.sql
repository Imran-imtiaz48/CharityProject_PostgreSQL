-- functions.sql

-- Function: calculate_total_donations_for_campaign
CREATE OR REPLACE FUNCTION calculate_total_donations_for_campaign(c_id INT)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO total FROM donations WHERE campaign_id = c_id;
    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Function: get_orphan_json_summary
CREATE OR REPLACE FUNCTION get_orphan_json_summary(orphan_id INT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'orphan_id', o.id,
        'full_name', o.full_name,
        'gender', o.gender,
        'country', o.country,
        'additional_info', o.additional_info,
        'feedbacks', jsonb_agg(jsonb_build_object(
            'date', f.feedback_date,
            'rating', f.rating,
            'comments', f.comments
        ))
    )
    INTO result
    FROM orphans o
    LEFT JOIN feedback f ON o.id = f.orphan_id
    WHERE o.id = orphan_id
    GROUP BY o.id;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function: log_event
CREATE OR REPLACE FUNCTION log_event(evt_type TEXT, evt_data JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO event_log (event_type, event_data) VALUES (evt_type, evt_data);
END;
$$ LANGUAGE plpgsql;

-- Function: get_active_campaigns_by_type
CREATE OR REPLACE FUNCTION get_active_campaigns_by_type(campaign_type TEXT)
RETURNS TABLE(id INT, name TEXT, goal NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT id, name, goal_amount
    FROM campaigns
    WHERE type = campaign_type AND status = 'Active';
END;
$$ LANGUAGE plpgsql;

-- Function: get_volunteer_availability_json
CREATE OR REPLACE FUNCTION get_volunteer_availability_json(vol_id INT)
RETURNS JSONB AS $$
DECLARE
    v JSONB;
BEGIN
    SELECT availability INTO v FROM volunteers WHERE id = vol_id;
    RETURN v;
END;
$$ LANGUAGE plpgsql;
