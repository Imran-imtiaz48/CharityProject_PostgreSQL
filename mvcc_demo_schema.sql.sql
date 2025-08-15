-- ===========================================================
-- MVCC, temporal versioning for donations
-- Pattern: base history table + updatable view + INSTEAD OF triggers
-- Guarantees a single current version per business key
-- Includes helpers to query history, as of time, and restore versions
-- ===========================================================

-- Safety, create schema placeholder if you use a dedicated schema
-- CREATE SCHEMA IF NOT EXISTS charity;

-- 1) Base history table, stores every version
CREATE TABLE IF NOT EXISTS donations_hist (
    donation_id        BIGINT        NOT NULL,         -- business key, stable across versions
    version_id         BIGSERIAL     PRIMARY KEY,      -- technical version identifier
    donor_id           BIGINT        NOT NULL,
    project_id         BIGINT        NULL,
    campaign_id        BIGINT        NULL,
    orphan_id          BIGINT        NULL,
    amount             NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency           TEXT          NOT NULL DEFAULT 'USD',
    donation_date      DATE          NOT NULL,
    -- system time validity window
    valid_from         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    valid_to           TIMESTAMPTZ   NOT NULL DEFAULT 'infinity',
    -- metadata
    txid               BIGINT        NOT NULL DEFAULT txid_current(),
    op                 CHAR(1)       NOT NULL CHECK (op IN ('I','U','D')),
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by         TEXT          NULL             -- optional, fill from app or session
);

-- Optional FKs, comment out if the referenced tables are not present
-- ALTER TABLE donations_hist
--   ADD CONSTRAINT fk_donations_hist_donor    FOREIGN KEY (donor_id)   REFERENCES donors(donor_id),
--   ADD CONSTRAINT fk_donations_hist_project  FOREIGN KEY (project_id) REFERENCES projects(project_id),
--   ADD CONSTRAINT fk_donations_hist_campaign FOREIGN KEY (campaign_id)REFERENCES campaigns(campaign_id),
--   ADD CONSTRAINT fk_donations_hist_orphan   FOREIGN KEY (orphan_id)  REFERENCES orphans(orphan_id);

-- Only one current version per donation_id
CREATE UNIQUE INDEX IF NOT EXISTS ux_donations_hist_current
ON donations_hist(donation_id)
WHERE valid_to = 'infinity';

-- Helpful lookup indexes
CREATE INDEX IF NOT EXISTS ix_donations_hist_id_from ON donations_hist(donation_id, valid_from);
CREATE INDEX IF NOT EXISTS ix_donations_hist_from_to ON donations_hist(valid_from, valid_to);
CREATE INDEX IF NOT EXISTS ix_donations_hist_txid    ON donations_hist(txid);

-- 2) Updatable view that always shows the current snapshot
CREATE OR REPLACE VIEW donations AS
SELECT
    donation_id,
    donor_id,
    project_id,
    campaign_id,
    orphan_id,
    amount,
    currency,
    donation_date
FROM donations_hist
WHERE valid_to = 'infinity';

COMMENT ON VIEW donations IS 'Current snapshot of donations, backed by donations_hist MVCC table';

-- 3) Trigger functions that implement versioning on the view

-- Insert, always creates a new current version
CREATE OR REPLACE FUNCTION trg_donations_ins()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO donations_hist(
        donation_id, donor_id, project_id, campaign_id, orphan_id,
        amount, currency, donation_date,
        valid_from, valid_to, op, created_by
    )
    VALUES (
        NEW.donation_id, NEW.donor_id, NEW.project_id, NEW.campaign_id, NEW.orphan_id,
        NEW.amount, COALESCE(NEW.currency, 'USD'), NEW.donation_date,
        now(), 'infinity', 'I', current_user
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update, closes the current version, inserts a new one
CREATE OR REPLACE FUNCTION trg_donations_upd()
RETURNS TRIGGER AS $$
DECLARE
    v_now timestamptz := now();
BEGIN
    -- Close the current version window
    UPDATE donations_hist
    SET valid_to = v_now, op = 'U'
    WHERE donation_id = OLD.donation_id
      AND valid_to = 'infinity';

    -- Insert the new version
    INSERT INTO donations_hist(
        donation_id, donor_id, project_id, campaign_id, orphan_id,
        amount, currency, donation_date,
        valid_from, valid_to, op, created_by
    )
    VALUES (
        OLD.donation_id,
        COALESCE(NEW.donor_id,    OLD.donor_id),
        COALESCE(NEW.project_id,  OLD.project_id),
        COALESCE(NEW.campaign_id, OLD.campaign_id),
        COALESCE(NEW.orphan_id,   OLD.orphan_id),
        COALESCE(NEW.amount,      OLD.amount),
        COALESCE(NEW.currency,    OLD.currency),
        COALESCE(NEW.donation_date, OLD.donation_date),
        v_now, 'infinity', 'U', current_user
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Delete, closes the current version, optionally writes a tombstone
CREATE OR REPLACE FUNCTION trg_donations_del()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE donations_hist
    SET valid_to = now(), op = 'D'
    WHERE donation_id = OLD.donation_id
      AND valid_to = 'infinity';

    -- Optional, uncomment to write an explicit tombstone row
    -- INSERT INTO donations_hist(
    --   donation_id, donor_id, project_id, campaign_id, orphan_id,
    --   amount, currency, donation_date,
    --   valid_from, valid_to, op, created_by
    -- ) VALUES (
    --   OLD.donation_id, OLD.donor_id, OLD.project_id, OLD.campaign_id, OLD.orphan_id,
    --   OLD.amount, OLD.currency, OLD.donation_date,
    --   now(), now(), 'D', current_user
    -- );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 4) INSTEAD OF triggers on the view
DROP TRIGGER IF EXISTS ins_donations_mvcc ON donations;
DROP TRIGGER IF EXISTS upd_donations_mvcc ON donations;
DROP TRIGGER IF EXISTS del_donations_mvcc ON donations;

CREATE TRIGGER ins_donations_mvcc
INSTEAD OF INSERT ON donations
FOR EACH ROW EXECUTE FUNCTION trg_donations_ins();

CREATE TRIGGER upd_donations_mvcc
INSTEAD OF UPDATE ON donations
FOR EACH ROW EXECUTE FUNCTION trg_donations_upd();

CREATE TRIGGER del_donations_mvcc
INSTEAD OF DELETE ON donations
FOR EACH ROW EXECUTE FUNCTION trg_donations_del();

-- 5) Helper functions

-- 5a, full history for a donation_id
CREATE OR REPLACE FUNCTION get_donation_history(p_donation_id BIGINT)
RETURNS TABLE (
    version_id    BIGINT,
    donation_id   BIGINT,
    donor_id      BIGINT,
    project_id    BIGINT,
    campaign_id   BIGINT,
    orphan_id     BIGINT,
    amount        NUMERIC,
    currency      TEXT,
    donation_date DATE,
    valid_from    TIMESTAMPTZ,
    valid_to      TIMESTAMPTZ,
    op            CHAR(1),
    txid          BIGINT,
    created_at    TIMESTAMPTZ,
    created_by    TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.version_id, h.donation_id, h.donor_id, h.project_id, h.campaign_id, h.orphan_id,
        h.amount, h.currency, h.donation_date, h.valid_from, h.valid_to, h.op, h.txid, h.created_at, h.created_by
    FROM donations_hist h
    WHERE h.donation_id = p_donation_id
    ORDER BY h.valid_from;
END;
$$ LANGUAGE plpgsql STABLE;

-- 5b, as of timeline query, returns the snapshot at a given time
CREATE OR REPLACE FUNCTION donations_as_of(p_as_of TIMESTAMPTZ)
RETURNS TABLE (
    donation_id   BIGINT,
    donor_id      BIGINT,
    project_id    BIGINT,
    campaign_id   BIGINT,
    orphan_id     BIGINT,
    amount        NUMERIC,
    currency      TEXT,
    donation_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT donation_id, donor_id, project_id, campaign_id, orphan_id, amount, currency, donation_date
    FROM donations_hist
    WHERE valid_from <= p_as_of
      AND valid_to   >  p_as_of;
END;
$$ LANGUAGE plpgsql STABLE;

-- 5c, restore a specific historic version to be the new current one
CREATE OR REPLACE FUNCTION restore_donation_version(p_donation_id BIGINT, p_version_id BIGINT)
RETURNS VOID AS $$
DECLARE
    v_row donations_hist%ROWTYPE;
    v_now timestamptz := now();
BEGIN
    SELECT * INTO v_row
    FROM donations_hist
    WHERE donation_id = p_donation_id
      AND version_id  = p_version_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Version % for donation % not found', p_version_id, p_donation_id;
    END IF;

    -- Close current version, if any
    UPDATE donations_hist
    SET valid_to = v_now, op = 'U'
    WHERE donation_id = p_donation_id
      AND valid_to = 'infinity';

    -- Insert a copy as the new current version
    INSERT INTO donations_hist(
        donation_id, donor_id, project_id, campaign_id, orphan_id,
        amount, currency, donation_date,
        valid_from, valid_to, op, created_by
    )
    VALUES (
        v_row.donation_id, v_row.donor_id, v_row.project_id, v_row.campaign_id, v_row.orphan_id,
        v_row.amount, v_row.currency, v_row.donation_date,
        v_now, 'infinity', 'U', current_user
    );
END;
$$ LANGUAGE plpgsql;

-- 6) Quick demo, uncomment to test
-- INSERT INTO donations(donation_id, donor_id, amount, donation_date) VALUES (1001, 1, 50.00, CURRENT_DATE);
-- UPDATE donations SET amount = 75.00 WHERE donation_id = 1001;
-- DELETE FROM donations WHERE donation_id = 1001;
-- SELECT * FROM get_donation_history(1001);
-- SELECT * FROM donations_as_of(now() - interval '5 minutes');

-- Notes
-- Use the donations view for all CRUD in your app
-- The system enforces one current version per donation_id by partial unique index
-- History is immutable, only new versions are added, current is closed by setting valid_to
