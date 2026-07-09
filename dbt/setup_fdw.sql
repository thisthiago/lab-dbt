-- =============================================================================
-- PASSO 0 — Configuração do PostgreSQL Foreign Data Wrapper (FDW)
-- =============================================================================
-- Execute este script UMA VEZ no banco db_dw antes de rodar o dbt.
-- O FDW permite que db_dw leia dados de db_admin e db_motoristas como se
-- fossem tabelas locais, sem precisar copiar os dados.
--
-- Como executar:
--   psql -h localhost -p 5455 -U postgres -d db_dw -f setup_fdw.sql
--
-- Ou via psql interativo:
--   \c db_dw
--   \i setup_fdw.sql
-- =============================================================================

-- 1. Habilitar a extensão postgres_fdw
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- =============================================================================
-- 2. Criar os servidores estrangeiros (Foreign Servers)
--    Host 'postgres-sistemas': nome do serviço Docker (dentro da rede Docker)
--    Se rodar fora do Docker, troque por 'localhost' e porta 5454
-- =============================================================================

-- Servidor para db_admin (sistema de funcionários administrativos)
DROP SERVER IF EXISTS srv_admin CASCADE;
CREATE SERVER srv_admin
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'postgres-sistemas',   -- nome do serviço no docker-compose
        port '5432',
        dbname 'db_admin'
    );

-- Servidor para db_motoristas (sistema de motoristas)
DROP SERVER IF EXISTS srv_motoristas CASCADE;
CREATE SERVER srv_motoristas
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'postgres-sistemas',
        port '5432',
        dbname 'db_motoristas'
    );

-- =============================================================================
-- 3. Criar mapeamento de usuário (User Mapping)
--    Define qual usuário local se conecta com qual usuário remoto
-- =============================================================================

CREATE USER MAPPING IF NOT EXISTS FOR postgres
    SERVER srv_admin
    OPTIONS (user 'postgres', password 'postgres');

CREATE USER MAPPING IF NOT EXISTS FOR postgres
    SERVER srv_motoristas
    OPTIONS (user 'postgres', password 'postgres');

-- =============================================================================
-- 4. Importar os schemas remotos como tabelas estrangeiras
--    Isso cria "foreign tables" em db_dw que apontam para as tabelas originais
-- =============================================================================

-- Schema para receber as tabelas de db_admin
CREATE SCHEMA IF NOT EXISTS raw_admin;
DROP FOREIGN TABLE IF EXISTS
    raw_admin.empresa,
    raw_admin.funcionario,
    raw_admin.apontamento,
    raw_admin.ferias,
    raw_admin.solicitacao_ajuste;

IMPORT FOREIGN SCHEMA public
    FROM SERVER srv_admin
    INTO raw_admin;

-- Schema para receber as tabelas de db_motoristas
CREATE SCHEMA IF NOT EXISTS raw_motoristas;
DROP FOREIGN TABLE IF EXISTS
    raw_motoristas.empresa,
    raw_motoristas.funcionario,
    raw_motoristas.apontamento,
    raw_motoristas.ferias,
    raw_motoristas.solicitacao_ajuste;

IMPORT FOREIGN SCHEMA public
    FROM SERVER srv_motoristas
    INTO raw_motoristas;

-- =============================================================================
-- 5. Verificar a configuração
-- =============================================================================

-- Liste as tabelas importadas
SELECT schemaname, tablename, servername
FROM information_schema.foreign_tables
JOIN pg_foreign_table ft ON ft.ftrelid = (schemaname || '.' || tablename)::regclass
JOIN pg_foreign_server fs ON fs.oid = ft.ftserver
ORDER BY schemaname, tablename;

-- Testar acesso a cada fonte
SELECT 'db_admin — empresas:' as fonte, count(*) FROM raw_admin.empresa
UNION ALL
SELECT 'db_admin — funcionarios:', count(*) FROM raw_admin.funcionario
UNION ALL
SELECT 'db_motoristas — funcionarios:', count(*) FROM raw_motoristas.funcionario;
