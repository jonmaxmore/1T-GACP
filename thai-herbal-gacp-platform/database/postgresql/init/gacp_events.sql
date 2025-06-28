-- Create event store schema
CREATE SCHEMA IF NOT EXISTS gacp_events;
SET search_path TO gacp_events;

-- Events table
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_data JSONB NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    version INT NOT NULL,
    metadata JSONB
);

-- Indexes for query optimization
CREATE INDEX IF NOT EXISTS idx_events_aggregate_id ON events (aggregate_id);
CREATE INDEX IF NOT EXISTS idx_events_event_type ON events (event_type);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events (timestamp);
CREATE INDEX IF NOT EXISTS idx_events_version ON events (version);

-- Snapshots table (for optimized state loading)
CREATE TABLE IF NOT EXISTS snapshots (
    aggregate_id TEXT PRIMARY KEY,
    state JSONB NOT NULL,
    last_event_version INT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Audit log table (for business reporting)
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES events(id),
    user_id TEXT,
    action_type TEXT NOT NULL,
    target_entity TEXT,
    details JSONB,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Certificate verification view
CREATE MATERIALIZED VIEW IF NOT EXISTS certificate_status_view
AS
SELECT
    aggregate_id AS certificate_id,
    last_value(event_data ->> 'certificateNumber') FILTER (WHERE event_type = 'CertificateIssued') AS certificate_number,
    last_value(event_data ->> 'companyName') FILTER (WHERE event_type = 'CertificateIssued') AS company_name,
    MAX(timestamp) FILTER (WHERE event_type IN ('CertificateIssued', 'CertificateRenewed')) AS last_issue_date,
    MAX(timestamp) FILTER (WHERE event_type = 'CertificateExpired') AS expiry_date,
    CASE
        WHEN bool_or(event_type = 'CertificateRevoked') THEN 'revoked'
        WHEN bool_or(event_type = 'CertificateSuspended') THEN 'suspended'
        WHEN MAX(timestamp) FILTER (WHERE event_type = 'CertificateExpired') < CURRENT_TIMESTAMP THEN 'expired'
        ELSE 'active'
   
