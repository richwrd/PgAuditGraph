/*▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
  
  📦 Project: postgres-audit-log
  🔗 Repository: https://github.com/richwrd/postgres-audit-log
  👤 Author: richwrd (Eduardo Richard)
  
  ⭐ Star this project if it helped you! | Deixe uma estrela se te ajudou!
  🤝 Contributions welcome! | Contribuições são bem-vindas!

  📅 Created: July 30, 2023
  🔄 Updated: December 14, 2025

▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬*/

-- SETUP - AUDIT LOG SYSTEM
--
-- Master installation script for complete audit system deployment
-- 
-- MODULAR STRUCTURE:
-- 1. Schema - Database structure (tables, triggers, constraints)
-- 2. Core   - Business logic (audit functions and policy management)

-- Description: 
--    Full DML audit system (Insert/Update/Delete) with:
--    - Partitioning (Scalability)
--    - JSONB Data Diff (Old vs New)
--    - Security Triggers (Anti-Spoofing)
--    - Policy Management (Dynamic Triggers)

-- USAGE:
--   psql -U username -d database -f setup.sql
--
--▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

\echo ''
\echo '═══════════════════════════════════════════════════════════════'
\echo '   INSTALLING AUDIT LOG SYSTEM'
\echo '═══════════════════════════════════════════════════════════════'
\echo ''

-- 1. Schema (Database Structure)
\echo '→ [1/5] Creating tables...'
\i steps/1-schema/1.1-tables.sql
\echo '✓ Tables created!'

\echo '→ [2/5] Creating security triggers...'
\i steps/1-schema/1.2-triggers.sql
\echo '✓ Security triggers activated!'

-- 2. Core (Audit Logic)
\echo '→ [3/5] Creating change recording function...'
\i steps/2-core/2.1-record_change.sql
\echo '✓ Function record_change() created!'

\echo '→ [4/5] Creating policy management function...'
\i steps/2-core/2.2-apply_rules.sql
\echo '✓ Function apply_rules() created!'

\echo '→ [5/5] Creating partition management function...'
\i steps/2-core/2.3-partitions.sql
\echo '✓ Function auto_manage_partitions() created!'
\echo ''

\echo '═══════════════════════════════════════════════════════════════'
\echo '   ✨ INSTALLATION COMPLETED SUCCESSFULLY! ✨'
\echo '═══════════════════════════════════════════════════════════════'
\echo ''
\echo 'NEXT STEPS:'
\echo '1. Create partitions: SELECT audit.auto_manage_partitions();'
\echo '2. Configure schemas to audit in audit.log_control table'
\echo '3. Apply rules: SELECT audit.apply_rules();'
\echo '4. Query logs: SELECT * FROM audit.logging_dml;'
\echo ''
