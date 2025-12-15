/*▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

  ⭐ Star this project if it helped you! | Deixe uma estrela se te ajudou!
  🤝 Contributions welcome! | Contribuições são bem-vindas!
  
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬*/

-- CORE AUDIT FUNCTION - RECORD CHANGE
-- 
-- This file contains:
-- - Main trigger function that captures DML operations
-- - Handles INSERT, UPDATE, DELETE events
-- - Populates audit.logging_dml with before/after snapshots

--▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

-- Core audit trigger function
-- Captures data changes (INSERT/UPDATE/DELETE) and stores them in the partitioned audit log
CREATE OR REPLACE FUNCTION audit.record_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_operation CHAR(1);
  v_data_old  JSONB;
  v_data_new  JSONB;
BEGIN
/*===========================================================================
  
    📦 Project: postgres-audit-log
    🔗 Repository: https://github.com/richwrd/postgres-audit-log
    👤 Author: richwrd (Eduardo Richard)
    ⭐ Star this project if it helped you! 
  
=============================================================================*/

  IF (TG_OP = 'INSERT') THEN
      v_operation := 'I';
      v_data_new  := row_to_json(NEW.*);
      v_data_old  := NULL;
      
  ELSIF (TG_OP = 'UPDATE') THEN
      v_operation := 'U';
      v_data_new  := row_to_json(NEW.*);
      v_data_old  := row_to_json(OLD.*);
      
  ELSIF (TG_OP = 'DELETE') THEN
      v_operation := 'D';
      v_data_new  := NULL;
      v_data_old  := row_to_json(OLD.*);
  END IF;


  INSERT INTO audit.logging_dml (
      schema_name,
      table_name,
      operation,
      data_old,
      data_new
  ) VALUES (
      TG_TABLE_SCHEMA,
      TG_TABLE_NAME,
      v_operation,
      v_data_old,
      v_data_new
  );


  IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
  ELSE
      RETURN NEW;
  END IF;

END;
$function$;

COMMENT ON FUNCTION audit.record_change() IS 'Trigger function that captures changes and records into audit.logging_dml';