-- Migration: 001_init_event_store
-- Created at: 2023-10-01

BEGIN;

-- Create event store schema
CREATE SCHEMA IF NOT EXISTS gacp_events;
COMMENT ON SCHEMA gacp_events IS 'Schema for GACP event sourcing tables';

-- Create events table
CREATE TABLE gacp_events.events (
    id UUID PRIMARY KEY,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_data JSONB NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    version INTEGER NOT NULL,
    metadata JSONB
);
COMMENT ON TABLE gacp_events.events IS 'Stores all domain events';
COMMENT ON COLUMN gacp_events.events.id IS 'Unique event identifier';
COMMENT ON COLUMN gacp_events.events.aggregate_id IS 'Aggregate root identifier';
COMMENT ON COLUMN gacp_events.events.event_type IS 'Type of the event';
COMMENT ON COLUMN gacp_events.events.event_data IS 'Event payload in JSON format';
COMMENT ON COLUMN gacp_events.events.timestamp IS 'Event creation timestamp';
COMMENT ON COLUMN gacp_events.events.version IS 'Event version in the aggregate stream';
COMMENT ON COLUMN gacp_events.events.metadata IS 'Additional event metadata';

-- Create indexes
CREATE INDEX idx_events_aggregate_id ON gacp_events.events (aggregate_id);
CREATE INDEX idx_events_event_type ON gacp_events.events (event_type);
CREATE INDEX idx_events_timestamp ON gacp_events.events (timestamp);
CREATE INDEX idx_events_version ON gacp_events.events (version);
CREATE INDEX idx_events_data ON gacp_events.events USING GIN (event_data);

-- Create snapshots table
CREATE TABLE gacp_events.snapshots (
    aggregate_id TEXT PRIMARY KEY,
    state JSONB NOT NULL,
    last_event_version INTEGER NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
COMMENT ON TABLE gacp_events.snapshots IS 'Stores aggregate state snapshots';
COMMENT ON COLUMN gacp_events.snapshots.aggregate_id IS 'Aggregate root identifier';
COMMENT ON COLUMN gacp_events.snapshots.state IS 'Serialized aggregate state';
COMMENT ON COLUMN gacp_events.snapshots.last_event_version IS 'Last event version included in snapshot';
COMMENT ON COLUMN gacp_events.snapshots.timestamp IS 'Snapshot creation timestamp';

-- Create audit log table
CREATE TABLE gacp_events.audit_log (
    id UUID PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES gacp_events.events(id),
    user_id TEXT,
    action_type TEXT NOT NULL,
    target_entity TEXT,
    details JSONB,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
COMMENT ON TABLE gacp_events.audit_log IS 'Audit log for business operations';
COMMENT ON COLUMN gacp_events.audit_log.event_id IS 'Reference to the related event';
COMMENT ON COLUMN gacp_events.audit_log.user_id IS 'User who performed the action';
COMMENT ON COLUMN gacp_events.audit_log.action_type IS 'Type of action performed';
COMMENT ON COLUMN gacp_events.audit_log.target_entity IS 'Entity affected by the action';
COMMENT ON COLUMN gacp_events.audit_log.details IS 'Additional action details';
COMMENT ON COLUMN gacp_events.audit_log.recorded_at IS 'Action recording timestamp';

-- Create materialized views
CREATE MATERIALIZED VIEW gacp_events.certificate_status_view AS
SELECT
    aggregate_id AS certificate_id,
    (event_data->>'certificateNumber') AS certificate_number,
    (event_data->>'companyName') AS company_name,
    MAX(timestamp) FILTER (WHERE event_type = 'CertificateIssued') AS issue_date,
    MAX(timestamp) FILTER (WHERE event_type = 'CertificateExpired') AS expiry_date,
    CASE
        WHEN EXISTS (SELECT 1 FROM gacp_events.events e2 WHERE e2.aggregate_id = e.aggregate_id AND e2.event_type = 'CertificateRevoked') THEN 'revoked'
        WHEN EXISTS (SELECT 1 FROM gacp_events.events e2 WHERE e2.aggregate_id = e.aggregate_id AND e2.event_type = 'CertificateSuspended') THEN 'suspended'
        WHEN MAX(timestamp) FILTER (WHERE event_type = 'CertificateExpired') < CURRENT_TIMESTAMP THEN 'expired'
        ELSE 'active'
    END AS status,
    MAX(version) AS current_version
FROM gacp_events.events e
WHERE event_type IN ('CertificateIssued', 'CertificateExpired', 'CertificateRevoked', 'CertificateSuspended')
GROUP BY aggregate_id, event_data->>'certificateNumber', event_data->>'companyName'
WITH DATA;

CREATE MATERIALIZED VIEW gacp_events.application_status_view AS
SELECT
    aggregate_id AS application_id,
    (event_data->>'companyName') AS company_name,
    (event_data->>'status') AS status,
    MAX(timestamp) FILTER (WHERE event_type = 'ApplicationSubmitted') AS submission_date,
    MAX(timestamp) FILTER (WHERE event_type = 'ApplicationApproved') AS approval_date,
    MAX(version) AS current_version
FROM gacp_events.events
WHERE event_type IN ('ApplicationSubmitted', 'ApplicationApproved', 'ApplicationRejected')
GROUP BY aggregate_id, event_data->>'companyName', event_data->>'status'
WITH DATA;

-- Create refresh functions
CREATE OR REPLACE FUNCTION gacp_events.refresh_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW gacp_events.certificate_status_view;
    REFRESH MATERIALIZED VIEW gacp_events.application_status_view;
END;
$$ LANGUAGE plpgsql;

-- Create trigger function for view refresh
CREATE OR REPLACE FUNCTION gacp_events.trigger_refresh_views()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM gacp_events.refresh_views();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER refresh_views_trigger
AFTER INSERT OR UPDATE OR DELETE ON gacp_events.events
FOR EACH STATEMENT
EXECUTE FUNCTION gacp_events.trigger_refresh_views();

COMMIT;
