-- STEP 1: Create the audit table
CREATE TABLE IF NOT EXISTS donation_audit (
    audit_id SERIAL PRIMARY KEY,
    donation_id INT,
    donor_id INT,
    orphan_id INT,
    amount NUMERIC(10,2),
    operation_type TEXT CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STEP 2: Create the trigger function
CREATE OR REPLACE FUNCTION log_donation_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO donation_audit (donation_id, donor_id, orphan_id, amount, operation_type)
        VALUES (NEW.donation_id, NEW.donor_id, NEW.orphan_id, NEW.amount, 'INSERT');
        
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO donation_audit (donation_id, donor_id, orphan_id, amount, operation_type)
        VALUES (NEW.donation_id, NEW.donor_id, NEW.orphan_id, NEW.amount, 'UPDATE');
        
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO donation_audit (donation_id, donor_id, orphan_id, amount, operation_type)
        VALUES (OLD.donation_id, OLD.donor_id, OLD.orphan_id, OLD.amount, 'DELETE');
    END IF;

    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

-- STEP 3: Attach the trigger to the donations table
DROP TRIGGER IF EXISTS trg_donation_audit ON donations;

CREATE TRIGGER trg_donation_audit
AFTER INSERT OR UPDATE OR DELETE ON donations
FOR EACH ROW
EXECUTE FUNCTION log_donation_changes();
