# 🚀 Quick Start

## 1. Clone the repository

```bash
git clone https://github.com/richwrd/postgres-audit-log.git
cd postgres-audit-log
```

## 2. Install in your database

```bash
psql -U your_user -d your_database -f ./src/setup.sql
```

## 3. Enable auditing for a schema

```sql
-- 1. Create initial partitions (Current + Next Month)
-- Or number of months you want to create passed as argument
SELECT audit.auto_manage_partitions();

-- 2. Enable audit for 'public' (example) schema
INSERT INTO audit.log_control (schema_name, log_insert, log_update, log_delete)
VALUES ('public', TRUE, TRUE, TRUE);

-- Note: After INSERT, audit.reset_validation() is triggered automatically.
-- This function can apply rules automatically if uncommented in src/1-schema/1.2-triggers.sql (line 30)

-- 3. Apply the rules (if automatic application is not enabled)
SELECT audit.apply_rules();
```

## 4. Check your audit logs

```sql
-- View all audit events
SELECT * FROM audit.logging_dml ORDER BY created_at DESC LIMIT 10;

-- View specific table changes
SELECT * FROM audit.logging_dml
WHERE table_name = 'users'
ORDER BY created_at DESC;
```

## 📚 Next Steps

For more examples, see the [Usage Examples](usage-examples.md).
