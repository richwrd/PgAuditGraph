/*============================================================================================

  * Project: postgres-audit-log
  * Repository: https://github.com/richwrd/postgres-audit-log
  * Author: richwrd (Eduardo Richard)

  * Star this project if it helped you! | Deixe uma estrela se te ajudou!
  * Contributions welcome! | Contribuições são bem-vindas!

============================================================================================*/

-- AUDIT SCHEMA

CREATE SCHEMA IF NOT EXISTS audit;

COMMENT ON SCHEMA audit IS 'Dedicated schema for DML audit system';

--============================================================================================
-- DML TRIGGER CONFIGURATION

CREATE TABLE IF NOT EXISTS audit.log_control(
	id			        BIGINT GENERATED ALWAYS AS IDENTITY,
	schema_name     TEXT        NOT NULL,
	log_insert      BOOL        NOT NULL DEFAULT FALSE,
	log_update      BOOL        NOT NULL DEFAULT FALSE,
	log_delete      BOOL        NOT NULL DEFAULT FALSE,
	r_owner         TEXT        NOT NULL DEFAULT CURRENT_USER,
	configured_at   TIMESTAMP   NOT NULL DEFAULT CLOCK_TIMESTAMP(),
	validated       BOOL        NOT NULL DEFAULT FALSE,

	CONSTRAINT log_control_pk PRIMARY KEY (id),
	CONSTRAINT uq_log_control_schema UNIQUE (schema_name)
);

COMMENT ON TABLE  audit.log_control                 IS 'Controls which schemas have active DML auditing';
COMMENT ON COLUMN audit.log_control.id              IS 'Primary key';
COMMENT ON COLUMN audit.log_control.schema_name     IS 'Schema name to be audited';
COMMENT ON COLUMN audit.log_control.log_insert      IS 'TRUE = audit INSERTs';
COMMENT ON COLUMN audit.log_control.log_update      IS 'TRUE = audit UPDATEs';
COMMENT ON COLUMN audit.log_control.log_delete      IS 'TRUE = audit DELETEs';
COMMENT ON COLUMN audit.log_control.r_owner         IS 'User who configured the audit';
COMMENT ON COLUMN audit.log_control.configured_at   IS 'Configuration timestamp';
COMMENT ON COLUMN audit.log_control.validated       IS 'TRUE = triggers applied, FALSE/NULL = pending';

--============================================================================================
-- DML COMMAND LOG - AUDIT RECORDS (DEPENDENT PARTITIONING FUNCTION)

CREATE TABLE IF NOT EXISTS audit.logging_dml (
  id          BIGINT      GENERATED ALWAYS AS IDENTITY,
  created_at  TIMESTAMP   NOT NULL DEFAULT CLOCK_TIMESTAMP(),
  txid        BIGINT      NOT NULL DEFAULT txid_current(),
  schema_name TEXT        NOT NULL,
  table_name  TEXT        NOT NULL,
  operation   CHAR(1)     NOT NULL CHECK (operation IN ('I', 'U', 'D')),
  username    TEXT        NOT NULL DEFAULT CURRENT_USER,
  data_old    JSONB       NULL,
  data_new    JSONB       NULL,

  CONSTRAINT logging_dml_pk PRIMARY KEY (created_at, id)
) PARTITION BY RANGE (created_at);

COMMENT ON TABLE  audit.logging_dml             IS 'Records all audited DML operations';
COMMENT ON COLUMN audit.logging_dml.id          IS 'Primary key part';
COMMENT ON COLUMN audit.logging_dml.operation   IS 'Command type: I (Insert), U (Update) or D (Delete)';
COMMENT ON COLUMN audit.logging_dml.username    IS 'User who executed the operation';
COMMENT ON COLUMN audit.logging_dml.created_at  IS 'Operation timestamp (Partition Key)';
COMMENT ON COLUMN audit.logging_dml.data_old    IS 'Row data BEFORE operation (Update/Delete)';
COMMENT ON COLUMN audit.logging_dml.data_new    IS 'Row data AFTER operation (Insert/Update)';

-- Indexes to optimize common queries
CREATE INDEX IF NOT EXISTS idx_logging_dml_target     ON audit.logging_dml (schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_logging_dml_created_at ON audit.logging_dml (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logging_dml_txid       ON audit.logging_dml (txid);
CREATE INDEX IF NOT EXISTS idx_logging_dml_username   ON audit.logging_dml (username);
CREATE INDEX IF NOT EXISTS idx_logging_dml_operation  ON audit.logging_dml (operation);

COMMENT ON INDEX audit.idx_logging_dml_target     IS 'Optimizes filtering by Schema and Table';
COMMENT ON INDEX audit.idx_logging_dml_created_at IS 'Optimizes time-range queries';
COMMENT ON INDEX audit.idx_logging_dml_operation  IS 'Optimizes command type filters';
COMMENT ON INDEX audit.idx_logging_dml_username   IS 'Optimizes user-based queries';