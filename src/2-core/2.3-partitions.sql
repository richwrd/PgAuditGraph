/*============================================================================================

  * Star this project if it helped you! | Deixe uma estrela se te ajudou!
  * Contributions welcome! | Contribuições são bem-vindas!
  
============================================================================================*/

-- PARTITION MANAGEMENT - AUTO MANAGE PARTITIONS
-- 
-- This file contains:
-- - Function to automatically create monthly partitions
-- - Handles current and future months based on parameter
-- - Optimizes partitions for write-heavy audit logs (fillfactor=100)
-- - Prevents gaps in partition coverage

-- Automatically creates monthly partitions for audit.logging_dml
-- Parameter: p_months_ahead = number of future months to pre-create (default: 1)
CREATE OR REPLACE FUNCTION audit.auto_manage_partitions(p_months_ahead INT DEFAULT 1)
RETURNS text LANGUAGE plpgsql AS $function$
DECLARE
    v_date_target DATE;
    v_start_date  DATE;
    v_end_date    DATE;
    v_table_name  TEXT;
    v_sql         TEXT;
    i             INT;
BEGIN
/*===========================================================================
  
    * Project: postgres-audit-log
    * Repository: https://github.com/richwrd/postgres-audit-log
    * Author: richwrd (Eduardo Richard)
    * Star this project if it helped you! 
  
=============================================================================*/

    /* Parameter p_months_ahead:
       0 = Current month only
       1 = Current month + Next month (Default)
       12 = Current month + Next 12 months
    */

    FOR i IN 0..p_months_ahead LOOP
        v_date_target := DATE_TRUNC('MONTH', CURRENT_DATE) + (i || ' month')::INTERVAL;
        v_start_date  := v_date_target;
        v_end_date    := v_start_date + INTERVAL '1 month';
        
        v_table_name := 'logging_dml_y' || TO_CHAR(v_start_date, 'YYYY') || 'm' || TO_CHAR(v_start_date, 'MM');

        IF TO_REGCLASS('audit.' || v_table_name) IS NULL THEN
            v_sql := format('CREATE TABLE IF NOT EXISTS audit.%I PARTITION OF audit.logging_dml FOR VALUES FROM (%L) TO (%L)', 
                            v_table_name, v_start_date, v_end_date);
            EXECUTE v_sql;
            
            -- Optimization: Logs are Write-Once (Append Only), fillfactor 100 saves ~10-15% disk space
            EXECUTE format('ALTER TABLE audit.%I SET (fillfactor = 100)', v_table_name);
            
            RAISE NOTICE '[OK] Partition Created: audit.% (Range: % to %)', v_table_name, v_start_date, v_end_date;
        ELSE
            RAISE NOTICE '[OK] Partition already exists: audit.%', v_table_name;
        END IF;
    END LOOP;

    RETURN 'Partition verification completed for ' || (p_months_ahead + 1) || ' months.';
END;
$function$;

COMMENT ON FUNCTION audit.auto_manage_partitions(INT) IS 'Automatically creates and manages monthly partitions for audit.logging_dml';

--============================================================================================
-- EXECUTION EXAMPLES

-- 1. Default usage (Ensures current and next month) - Ideal for monthly Cron Jobs
-- SELECT audit.auto_manage_partitions();

-- 2. Manual usage (Ensures entire semester) - Ideal for initial deployment
-- SELECT audit.auto_manage_partitions(36);