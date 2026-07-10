-- =============================================================================
-- models/staging/stg_motoristas__funcionarios.sql (PASSO 2f)
-- =============================================================================
-- Objetivo: Padronizar os motoristas do sistema de logística.
--
-- Diferença em relação ao sistema admin:
--   - Todos têm setor='Transporte', departamento='Logística', cargo='Motorista'
--   - Categorias apenas: 'Mensalista' ou 'Horista' (sem Estagiário)
--   - sistema_origem = 'motoristas' (tag para unificação posterior)
-- =============================================================================

with source as (

    select * from "db_dw"."raw_motoristas"."funcionario"

),

renamed as (

    select
        id                          as funcionario_id,
        empresa_id,
        nome,
        cpf,
        data_nascimento,
        data_admissao,
        data_demissao,
        setor,                      -- sempre 'Transporte'
        departamento,               -- sempre 'Logística'
        cargo,                      -- sempre 'Motorista'
        categoria,                  -- 'Mensalista' ou 'Horista'
        salario::numeric(10, 2)     as salario,
        status,
        'motoristas'                as sistema_origem  -- TAG de origem

    from source

)

select * from renamed