# 🏗️ How It Works

The solution consists of three main components:

## 1. [`audit.log_control`](../src/1-schema/1.1-tables.sql)

Control table that defines which schemas should be audited.

This table acts as the configuration center for the audit system. Each row represents a schema that can be monitored.

## 2. [`audit.logging_dml`](../src/1-schema/1.1-tables.sql)

Log table where all DML events are stored in JSONB format.

This table captures every INSERT, UPDATE, and DELETE operation performed on the monitored tables. Each log entry includes metadata such as the operation type, timestamp, user, and before/after data snapshots.

## 3. [`audit.apply_rules()`](../src/2-core/2.2-apply_rules.sql)

Main function that automatically creates/removes triggers based on `log_control`:

```sql
SELECT audit.apply_rules();
```

### What This Function Does

1. **Scans** all schemas marked as `active = true` in `audit.log_control`
2. **Creates** audit triggers on all tables in those schemas
3. **Removes** triggers from tables in schemas marked as `active = false` or removed from control
4. **Returns** a report of actions taken

### Trigger Behavior

Each table gets three triggers automatically created:

- `audit_dml_trigger`: Captures INSERT operations
- `audit_dml_trigger`: Captures UPDATE operations
- `audit_dml_trigger`: Captures DELETE operations

These triggers are invisible to your application and execute before the DML operation completes.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant App as Application
    participant Ctrl as audit.log_control
    participant Reset as audit.reset_validation()
    participant Rules as audit.apply_rules()
    participant DB as Database Table
    participant Trig as Audit Trigger
    participant Func as audit.record_change()
    participant Log as audit.logging_dml
    participant Part as Partition Management

    Note over App,Part: Setup Phase
    App->>Ctrl: INSERT INTO audit.log_control<br/>(schema_name, log_insert, log_update, log_delete)
    Ctrl->>Reset: Trigger fires (log_control_validation)
    Reset->>Reset: Sets r_owner, configured_at<br/>validated = FALSE

    alt Automatic mode (line 30 uncommented 1.2-triggers.sql)
        Reset->>Rules: PERFORM audit.apply_rules()
        Rules->>DB: Creates triggers on all tables
    else Manual mode (default)
        Reset-->>Ctrl: Return
        Note over App,Rules: Manual step required
        App->>Rules: SELECT audit.apply_rules()
        Rules->>DB: Creates triggers on all tables
    end

    App->>Part: SELECT audit.auto_manage_partitions()
    Part->>Log: Creates monthly partitions

    Note over App,Part: Runtime - DML Operation
    App->>DB: INSERT/UPDATE/DELETE
    DB->>Trig: Trigger fires (BEFORE operation)
    Trig->>Func: Calls audit.record_change()

    alt INSERT Operation
        Func->>Log: Stores NEW data in data_new
    else UPDATE Operation
        Func->>Log: Stores OLD data in data_old<br/>NEW data in data_new
    else DELETE Operation
        Func->>Log: Stores OLD data in data_old
    end

    Func->>Log: Records metadata:<br/>- username<br/>- timestamp<br/>- operation type<br/>- txid
    Log-->>Func: Log stored
    Func-->>Trig: Return
    Trig-->>DB: Continue operation
    DB-->>App: Operation completed

    Note over App,Part: Monthly Maintenance (Automatic)
    Part->>Log: Creates next month partition
    Part->>Log: Optionally archives old partitions
```
