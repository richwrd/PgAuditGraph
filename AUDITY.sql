-- by Eduardo Richard.
-- data: 30 de jun. de 2023

--▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
-- REGISTRO DOS SCHEMAS A POSSUIR TRIGGER DML

CREATE SEQUENCE IF NOT EXISTS audit.log_control_id_seq;
	
CREATE TABLE IF NOT EXISTS audit.log_control(
	idkey		INT8 		NOT NULL DEFAULT NEXTVAL('audit.log_control_id_seq'::REGCLASS),
	schema_name	TEXT 		NULL,
	log_insert	BOOL		NULL,
	log_update	BOOL 		NULL,
	log_delete	BOOL 		NULL,
	r_owner		TEXT 		NOT NULL DEFAULT CURRENT_USER,
	datehour	TIMESTAMP	NOT NULL DEFAULT NOW(),
	validated	BOOL 		NULL,
	CONSTRAINT log_control_pk PRIMARY KEY (idkey)
);

CREATE OR REPLACE FUNCTION audit.update_validated()
 RETURNS TRIGGER
 LANGUAGE plpgsql
AS $FUNCTION$
BEGIN
		NEW.validated	:= FALSE;	
		NEW.r_owner		:= CURRENT_USER;
		NEW.datehour	:= NOW();

		RETURN NEW;
END;
$FUNCTION$;

CREATE TRIGGER log_control_validated 
BEFORE
	INSERT OR UPDATE OF schema_name, log_insert, log_update, log_delete, r_owner
	ON audit.log_control
FOR EACH ROW
	EXECUTE FUNCTION audit.update_validated();
END;
	
--▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
--	REGISTRO DE COMANDOS DML COMPLETO

CREATE SEQUENCE IF NOT EXISTS audit.logging_dml_id_seq;
	
CREATE TABLE IF NOT EXISTS audit.logging_dml (
	idkey 		INT8		NOT NULL DEFAULT nextval('audit.logging_dml_id_seq'::regclass),
	oid_table 	INT8		NOT NULL,
	command_dml	TEXT		NOT NULL,
	username	TEXT		NOT NULL DEFAULT CURRENT_USER,
	datehour	TIMESTAMP	NOT NULL DEFAULT NOW(),
	data_object	JSONB		NULL,
	CONSTRAINT pk_logging_dml PRIMARY KEY (idkey)
);
CREATE INDEX ipk_logging_dml ON audit.logging_dml USING btree (idkey); 


CREATE OR REPLACE FUNCTION audit.log_dml()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	oid_rec int8;
	command TEXT;
	data_log JSONB;
BEGIN
/*===========================================================================

	---------------------<|    by: richwrd    |>-----------------------

=============================================================================*/
	
	oid_rec := TG_RELID;
	
		IF (TG_OP = 'INSERT') THEN
				
			data_log  := row_to_json(NEW.*);
			command := 'INSERT';
		
			INSERT INTO audit.logging_dml (oid_table, command_dml, data_object) VALUES
				(oid_rec, command, data_log);
			
			RETURN NEW;

		ELSEIF (TG_OP = 'UPDATE') THEN
			
			data_log := row_to_json(OLD.*);
			command := 'UPDATE';
		
			INSERT INTO audit.logging_dml (oid_table, command_dml, data_object) VALUES
				(oid_rec, command, data_log);
				
			RETURN NEW;
			
		ELSEIF (TG_OP = 'DELETE') THEN
		
			data_log := row_to_json(OLD.*);
			command := 'DELETE';
		
			INSERT INTO audit.logging_dml (oid_table, command_dml, data_object) VALUES
				(oid_rec, command, data_log);
				
			RETURN NULL;
		
		END IF;
END $function$;
	
--▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
--◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘
--▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔

--SELECT audit.validate_log();

-- Percorre os schemas (e tabelas contidas) criando as devidas triggers definidas na tabela de controle */
	
CREATE OR REPLACE FUNCTION audit.validate_log()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    info_r record;
    recursive_tables record;
    table_verify TEXT;
    trigger_exists bool;
BEGIN
/*===========================================================================
        
        CRIA/DELETA LOG de comandos DML a partir de definições setadas em audit.log_control
            
---------------------<|            TRIGGERS            |>--------------------
---------------------<|    INSERT / UPDATE / DELETE    |>--------------------

            Tabelas RECEBE triggers setados     APENAS como   >> TRUE  <<  
            Tabelas PERDE  triggers setados     APENAS como   >> FALSE <<  
        
            ->  select audit.validate_log();
        
          ---------------------<|    (O.0)    |>-----------------------
    
                                 by: richwrd 

=============================================================================*/

    IF EXISTS (
        SELECT 1
        FROM audit.log_control lc 
        WHERE lc.validated = FALSE OR lc.validated IS NULL
    )
    THEN

        -- LOOP P/ SCHEMA
        FOR info_r IN (
            SELECT
                lc.idkey,
                lc.schema_name,
                lc.log_insert,
                lc.log_update,
                lc.log_delete,
                lc.r_owner,
                lc.datehour,
                lc.validated
            FROM audit.log_control lc 
            WHERE lc.validated = FALSE OR lc.validated IS NULL
        )
        LOOP

            -- Para cada tabela do schema, monta o nome completo com segurança
            FOR recursive_tables IN (
                SELECT t.tablename
                FROM pg_catalog.pg_tables t
                WHERE schemaname = info_r.schema_name
            )
            LOOP
                table_verify := quote_ident(info_r.schema_name) || '.' || quote_ident(recursive_tables.tablename);

                -- LOG INSERT
                IF info_r.log_insert THEN
                    SELECT EXISTS (
                        SELECT 1
                        FROM pg_trigger t
                        WHERE t.tgconstraint = 0
                          AND t.tgname = 'log_insert'
                          AND t.tgrelid = table_verify::regclass
                    ) INTO trigger_exists;

                    IF NOT trigger_exists THEN
                        EXECUTE 'CREATE TRIGGER "log_insert"
                            BEFORE INSERT ON ' || table_verify ||
                            ' FOR EACH ROW EXECUTE FUNCTION audit.log_dml();';
                    END IF;

                ELSE  -- DELETA TRIGGER INSERT
                    SELECT EXISTS (
                        SELECT 1
                        FROM pg_trigger t
                        WHERE t.tgconstraint = 0
                          AND t.tgname = 'log_insert'
                          AND t.tgrelid = table_verify::regclass
                    ) INTO trigger_exists;

                    IF trigger_exists THEN
                        EXECUTE 'DROP TRIGGER "log_insert" ON ' || table_verify;
                    END IF;
                END IF;

                -- LOG UPDATE
                IF info_r.log_update THEN
                    SELECT EXISTS (
                        SELECT 1
                        FROM pg_trigger t
                        WHERE t.tgconstraint = 0
                          AND t.tgname = 'log_update'
                          AND t.tgrelid = table_verify::regclass
                    ) INTO trigger_exists;

                    IF NOT trigger_exists THEN
                        EXECUTE 'CREATE TRIGGER "log_update"
                            AFTER UPDATE ON ' || table_verify ||
                            ' FOR EACH ROW EXECUTE FUNCTION audit.log_dml();';
                    END IF;

                ELSE  -- DELETA TRIGGER UPDATE
                    SELECT EXISTS (
                        SELECT 1
                        FROM pg_trigger t
                        WHERE t.tgconstraint = 0
                          AND t.tgname = 'log_update'
                          AND t.tgrelid = table_verify::regclass
                    ) INTO trigger_exists;

                    IF trigger_exists THEN
                        EXECUTE 'DROP TRIGGER "log_update" ON ' || table_verify;
                    END IF;
                END IF;

                -- LOG DELETE
                IF info_r.log_delete THEN
                    SELECT EXISTS (
                        SELECT 1
                        FROM pg_trigger t
                        WHERE t.tgconstraint = 0
                          AND t.tgname = 'log_delete'
                          AND t.tgrelid = table_verify::regclass
                    ) INTO trigger_exists;

                    IF NOT trigger_exists THEN
                        EXECUTE 'CREATE TRIGGER "log_delete"
                            AFTER DELETE ON ' || table_verify ||
                            ' FOR EACH ROW EXECUTE FUNCTION audit.log_dml();';
                    END IF;

                ELSE  -- DELETA TRIGGER DELETE
                    SELECT EXISTS (
                        SELECT 1
                        FROM pg_trigger t
                        WHERE t.tgconstraint = 0
                          AND t.tgname = 'log_delete'
                          AND t.tgrelid = table_verify::regclass
                    ) INTO trigger_exists;

                    IF trigger_exists THEN
                        EXECUTE 'DROP TRIGGER "log_delete" ON ' || table_verify;
                    END IF;
                END IF;

            END LOOP;  -- Fim do loop de tabelas

            -- Notificações
            IF info_r.log_insert THEN
                RAISE NOTICE '✨ INSERT LOG FROM ALL % HAS BEEN >> CREATED << 🎉', info_r.schema_name;
            ELSE
                RAISE NOTICE '❌ INSERT LOG FROM ALL % HAS BEEN >> DELETED << 🗑️', info_r.schema_name;
            END IF;

            IF info_r.log_update THEN
                RAISE NOTICE '✨ UPDATE LOG FROM ALL % HAS BEEN >> CREATED << 🎉', info_r.schema_name;
            ELSE
                RAISE NOTICE '❌ UPDATE LOG FROM ALL % HAS BEEN >> DELETED << 🗑️', info_r.schema_name;
            END IF;

            IF info_r.log_delete THEN
                RAISE NOTICE '✨ DELETE LOG FROM ALL % HAS BEEN >> CREATED << 🎉', info_r.schema_name;
            ELSE
                RAISE NOTICE '❌ DELETE LOG FROM ALL % HAS BEEN >> DELETED << 🗑️', info_r.schema_name;
            END IF;

            -- Marcar o schema como validado
            UPDATE audit.log_control
            SET validated = TRUE
            WHERE idkey = info_r.idkey;

        END LOOP;  -- Fim do loop de schemas

        RETURN 'TRIGGERS criados com SUCESSO!';

    ELSE
        RETURN 'Todos SCHEMAS estão validados, não há nada a fazer.';
    END IF;
END
$function$;


--▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
--◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘◘
--▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔

SELECT audit.validate_log();

SELECT
	ps.nspname		AS "schema",
	p.relname		AS "table",
	ld.command_dml 	AS comando,
	ld.username		AS usuario,
	ld.datehour		AS datahora,
	ld.data_object	AS dados
FROM
	audit.logging_dml ld 
LEFT JOIN
	pg_class p
	ON p."oid" = ld.oid_table 
LEFT JOIN 
	pg_catalog.pg_namespace ps
	ON p.relnamespace = ps."oid";

