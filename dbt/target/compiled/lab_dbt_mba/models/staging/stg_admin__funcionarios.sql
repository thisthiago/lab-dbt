-- =============================================================================
-- models/staging/stg_admin__funcionarios.sql (PASSO 2b)
-- =============================================================================
-- Objetivo: Padronizar e enriquecer minimamente os funcionários administrativos.
--
-- Transformações aplicadas:
--   - Renomeação de ID
--   - Cast explícito de salario (Numeric)
--   - Adição da coluna 'sistema_origem' = 'admin' (essencial para o UNION posterior)
--   - Sem filtros — staging carrega TUDO da fonte
-- =============================================================================

with source as (

    select * from "db_dw"."raw_admin"."funcionario"

),

renamed as (

    select
        id                          as funcionario_id,
        empresa_id,
        nome,
        cpf,
        data_nascimento,
        data_admissao,
        data_demissao,              -- NULL quando funcionário ainda ativo
        setor,
        departamento,
        cargo,
        categoria,                  -- 'Mensalista', 'Horista' ou 'Estagiário'
        salario::numeric(10, 2)     as salario,
        status,                     -- 'Ativo' ou 'Demitido'
        'admin'                     as sistema_origem  -- TAG de origem do dado

    from source

)

select * from renamed