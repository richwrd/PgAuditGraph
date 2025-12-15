/*============================================================================================

  * Star this project if it helped you! | Deixe uma estrela se te ajudou!
  * Contributions welcome! | Contribuições são bem-vindas!
  
============================================================================================*/

-- POLICY MANAGEMENT - APPLY RULES
-- 
-- This file contains:
-- - Function to synchronize audit policies with database triggers
-- - Reads configuration from audit.log_control
-- - Dynamically creates/updates triggers on target tables
-- - Validates and marks policies as applied

--============================================================================================

-- Reads audit policies from log_control and synchronizes triggers on all tables
CREATE OR REPLACE FUNCTION audit.apply_rules()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    r_schema    RECORD;
    r_table     RECORD;
    v_table_full TEXT;
    v_events     TEXT;
    v_sql        TEXT;
    v_counter    INT := 0;
BEGIN
/*===========================================================================
  
    * Project: postgres-audit-log
    * Repository: https://github.com/richwrd/postgres-audit-log
    * Author: richwrd (Eduardo Richard)
    * Star this project if it helped you! 
  
=============================================================================*/

    -- Check for pending policies
    IF NOT EXISTS (SELECT 1 FROM audit.log_control WHERE validated = FALSE) THEN
        RETURN '[OK] All policies are up to date.';
    END IF;

    -- Iterate through pending schemas
    FOR r_schema IN (
        SELECT id, schema_name, log_insert, log_update, log_delete
        FROM audit.log_control 
        WHERE validated = FALSE
    )
    LOOP
        -- Safety: Prevent circular logging
        IF r_schema.schema_name = 'audit' THEN
            RAISE WARNING '[!] Security Alert: Policy for schema "audit" ignored.';
            UPDATE audit.log_control SET validated = TRUE WHERE id = r_schema.id;
            CONTINUE;
        END IF;

        RAISE NOTICE '[->] Processing Policy for Schema: % ...', r_schema.schema_name;

        -- Build Event String
        v_events := '';
        IF r_schema.log_insert THEN v_events := 'INSERT'; END IF;
        
        IF r_schema.log_update THEN 
            IF v_events != '' THEN v_events := v_events || ' OR '; END IF;
            v_events := v_events || 'UPDATE'; 
        END IF;
        
        IF r_schema.log_delete THEN 
            IF v_events != '' THEN v_events := v_events || ' OR '; END IF;
            v_events := v_events || 'DELETE'; 
        END IF;

        -- Apply to Tables
        FOR r_table IN (
            SELECT tablename 
            FROM pg_catalog.pg_tables 
            WHERE schemaname = r_schema.schema_name
        )
        LOOP
            v_table_full := quote_ident(r_schema.schema_name) || '.' || quote_ident(r_table.tablename);

            -- Clean up old trigger
            EXECUTE format('DROP TRIGGER IF EXISTS audit_dml_trigger ON %s', v_table_full);

            -- Create new trigger (if events exist)
            IF v_events != '' THEN
                v_sql := format(
                    'CREATE TRIGGER audit_dml_trigger ' ||
                    'AFTER %s ON %s ' ||
                    'FOR EACH ROW EXECUTE FUNCTION audit.record_change()',
                    v_events, v_table_full
                );
                EXECUTE v_sql;
            END IF;
            
            v_counter := v_counter + 1;
        END LOOP;

        -- Feedback
        IF v_events = '' THEN
            RAISE NOTICE '[X] Audit removed for schema: %', r_schema.schema_name;
        ELSE
            RAISE NOTICE '[OK] Audit active (%s) for schema: %', v_events, r_schema.schema_name;
        END IF;

        -- Mark as Validated
        UPDATE audit.log_control SET validated = TRUE WHERE id = r_schema.id;

    END LOOP;

    RETURN format('[OK] Policies successfully applied to %s tables.', v_counter);
END;
$function$;

COMMENT ON FUNCTION audit.apply_rules() IS 'Synchronizes audit policies from log_control table and creates/updates triggers on target tables';