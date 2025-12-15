# 📖 Usage Examples

## Enable audit for multiple schemas

```sql
INSERT INTO audit.log_control (schema_name, log_insert, log_update, log_delete) VALUES
('public', TRUE, TRUE, TRUE),
('app', TRUE, TRUE, TRUE),
('reporting', TRUE, TRUE, TRUE);

SELECT audit.apply_rules();
```

## Disable audit for a schema

```sql
UPDATE audit.log_control
SET log_insert = FALSE, log_update = FALSE, log_delete = FALSE
WHERE schema_name = 'public';

SELECT audit.apply_rules();
```

---

## Query audit logs with filters

### All updates in the last hour

```sql
SELECT * FROM audit.logging_dml
WHERE operation = 'UPDATE'
AND created_at > NOW() - INTERVAL '1 hour';
```

### Compare old vs new data

```sql
SELECT
    table_name,
    old_data->>'email' as old_email,
    new_data->>'email' as new_email,
    created_at
FROM audit.logging_dml
WHERE operation = 'UPDATE'
AND old_data->>'email' IS DISTINCT FROM new_data->>'email';
```

### Monitor specific user changes

```sql
SELECT * FROM audit.logging_dml
WHERE changed_by = 'app_user'
ORDER BY created_at DESC;
```

---

## Track specific operations

### All insertions today

```sql
SELECT * FROM audit.logging_dml
WHERE operation = 'INSERT'
AND created_at >= CURRENT_DATE;
```

### All deletions for a specific table

```sql
SELECT * FROM audit.logging_dml
WHERE operation = 'DELETE'
AND table_name = 'orders'
ORDER BY created_at DESC;
```

---

## Analyze data changes

### Find who changed a specific record

```sql
SELECT
    operation,
    changed_by,
    created_at,
    old_data,
    new_data
FROM audit.logging_dml
WHERE table_name = 'users'
AND (old_data->>'id' = '123' OR new_data->>'id' = '123')
ORDER BY created_at;
```

### Track field-specific changes

```sql
-- Track all status changes
SELECT
    table_name,
    old_data->>'status' as old_status,
    new_data->>'status' as new_status,
    changed_by,
    created_at
FROM audit.logging_dml
WHERE operation = 'UPDATE'
AND old_data ? 'status'
AND old_data->>'status' IS DISTINCT FROM new_data->>'status';
```

---

## Generate reports

### Daily change summary

```sql
SELECT
    DATE(created_at) as date,
    operation,
    COUNT(*) as total_changes
FROM audit.logging_dml
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at), operation
ORDER BY date DESC, operation;
```

### Most modified tables

```sql
SELECT
    table_name,
    COUNT(*) as change_count,
    COUNT(DISTINCT changed_by) as unique_users
FROM audit.logging_dml
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY table_name
ORDER BY change_count DESC
LIMIT 10;
```

### User activity report

```sql
SELECT
    changed_by,
    operation,
    COUNT(*) as operations_count
FROM audit.logging_dml
WHERE created_at >= CURRENT_DATE
GROUP BY changed_by, operation
ORDER BY changed_by, operation;
```

---

## Advanced Queries

### Basic monitoring (Last 50 changes)

```sql
SELECT
    created_at::timestamp(0) as data,
    username,
    operation,    -- I, U, D
    schema_name || '.' || table_name as tabela,
    txid
FROM audit.logging_dml
ORDER BY created_at DESC
LIMIT 50;
```

### Timeline of a specific record

Track the complete history of a record (e.g., user ID 42):

```sql
SELECT
    created_at,
    operation,
    username,
    -- Extracting data directly from JSON into readable columns
    data_old->>'email' as email_anterior,
    data_new->>'email' as email_novo
FROM audit.logging_dml
WHERE
    schema_name = 'public'
    AND table_name = 'users'
    -- Search both new (Insert/Update) and old (Update/Delete) data.
    AND (data_new->>'id' = '42' OR data_old->>'id' = '42')
ORDER BY created_at DESC;
```

### Disaster recovery - Who deleted what?

Find deleted records and who deleted them to restore data:

```sql
SELECT
    created_at,
    username,
    table_name,
    data_old -- Complete backup of the deleted line
FROM audit.logging_dml
WHERE
    operation = 'D'
    AND created_at >= CURRENT_DATE
ORDER BY created_at DESC;
```

### Transaction analysis (Complete context)

Find all operations in the same transaction (same commit):

```sql
-- First, get the TXID of a suspicious transaction.
-- Let's say the suspicious TXID is 123456789.

SELECT
    operation,
    schema_name,
    table_name,
    data_new
FROM audit.logging_dml
WHERE txid = 123456789 
ORDER BY id ASC;
```

### Advanced JSONB queries

Find changes where a specific field was modified to a specific value:

```sql
SELECT
    created_at,
    username,
    table_name,
    data_old->>'status' as old_status,
    data_new->>'status' as new_status
FROM audit.logging_dml
WHERE
    operation = 'U'
    AND data_new->>'status' = 'INACTIVE'
    AND data_old->>'status' != 'INACTIVE'
ORDER BY created_at DESC;
```

### Productivity/Volume report

Which tables have the most changes?

```sql
SELECT
    schema_name,
    table_name,
    COUNT(*) as total_ops,
    COUNT(*) FILTER (WHERE operation = 'I') as inserts,
    COUNT(*) FILTER (WHERE operation = 'U') as updates,
    COUNT(*) FILTER (WHERE operation = 'D') as deletes
FROM audit.logging_dml
WHERE created_at >= DATE_TRUNC('MONTH', CURRENT_DATE)
GROUP BY 1, 2
ORDER BY total_ops DESC;
```
