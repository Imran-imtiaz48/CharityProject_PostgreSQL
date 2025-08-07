
-- Disaster Recovery SQL Script for CharityProject_PostgreSQL
-- Includes shadow tables, triggers, and recovery procedures

-- 1. Shadow Tables (Backups)
CREATE TABLE IF NOT EXISTS backup_donations AS TABLE donations WITH NO DATA;
CREATE TABLE IF NOT EXISTS backup_orphans AS TABLE orphans WITH NO DATA;
CREATE TABLE IF NOT EXISTS backup_projects AS TABLE projects WITH NO DATA;

-- 2. Triggers to Keep Shadow Tables Updated

-- Donations Trigger
CREATE OR REPLACE FUNCTION sync_backup_donations() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO backup_donations SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE backup_donations SET amount = NEW.amount, donor_id = NEW.donor_id, project_id = NEW.project_id, date_donated = NEW.date_donated
        WHERE donation_id = OLD.donation_id;
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM backup_donations WHERE donation_id = OLD.donation_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_backup_donations ON donations;
CREATE TRIGGER trg_backup_donations
AFTER INSERT OR UPDATE OR DELETE ON donations
FOR EACH ROW EXECUTE FUNCTION sync_backup_donations();

-- Orphans Trigger
CREATE OR REPLACE FUNCTION sync_backup_orphans() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO backup_orphans SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE backup_orphans SET name = NEW.name, age = NEW.age, gender = NEW.gender, date_registered = NEW.date_registered
        WHERE orphan_id = OLD.orphan_id;
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM backup_orphans WHERE orphan_id = OLD.orphan_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_backup_orphans ON orphans;
CREATE TRIGGER trg_backup_orphans
AFTER INSERT OR UPDATE OR DELETE ON orphans
FOR EACH ROW EXECUTE FUNCTION sync_backup_orphans();

-- Projects Trigger
CREATE OR REPLACE FUNCTION sync_backup_projects() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO backup_projects SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE backup_projects SET name = NEW.name, type = NEW.type, start_date = NEW.start_date, end_date = NEW.end_date, status = NEW.status
        WHERE project_id = OLD.project_id;
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM backup_projects WHERE project_id = OLD.project_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_backup_projects ON projects;
CREATE TRIGGER trg_backup_projects
AFTER INSERT OR UPDATE OR DELETE ON projects
FOR EACH ROW EXECUTE FUNCTION sync_backup_projects();


-- 3. Recovery Procedures

-- Restore Donations
CREATE OR REPLACE PROCEDURE restore_donations()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM donations;
    INSERT INTO donations SELECT * FROM backup_donations;
END;
$$;

-- Restore Orphans
CREATE OR REPLACE PROCEDURE restore_orphans()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM orphans;
    INSERT INTO orphans SELECT * FROM backup_orphans;
END;
$$;

-- Restore Projects
CREATE OR REPLACE PROCEDURE restore_projects()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM projects;
    INSERT INTO projects SELECT * FROM backup_projects;
END;
$$;

-- 4. Tamper Detection: Log Deletion Attempts
CREATE TABLE IF NOT EXISTS deletion_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT,
    record_id INT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_name TEXT DEFAULT current_user
);

-- Example for Donations
CREATE OR REPLACE FUNCTION log_donation_deletion() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO deletion_log(table_name, record_id) VALUES ('donations', OLD.donation_id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_donation_delete ON donations;
CREATE TRIGGER trg_log_donation_delete
BEFORE DELETE ON donations
FOR EACH ROW EXECUTE FUNCTION log_donation_deletion();
