-- =============================================================================
-- models/intermediate/int_funcionarios_unificados.sql (PASSO 3a)
-- =============================================================================
-- Objetivo: Unificar funcionários dos dois sistemas (admin + motoristas) em
--           uma única tabela com chave surrogate única.
--
-- Por que intermediate?
--   Esta tabela é uma transformação de negócio complexa (UNION + surrogate key)
--   que será reutilizada por dim_funcionario e pelos modelos analytics.
--   Ao ser "ephemeral", ela vira uma CTE inline nas queries que a consomem,
--   evitando materialização desnecessária no banco.
--
-- Surrogate Key:
--   Como os dois sistemas têm IDs independentes (podem ser iguais),
--   usamos a macro generate_surrogate_key do dbt-utils para criar um ID único
--   baseado no hash de (sistema_origem + funcionario_id).
-- =============================================================================

with admin as (

    select * from {{ ref('stg_admin__funcionarios') }}

),

motoristas as (

    select * from {{ ref('stg_motoristas__funcionarios') }}

),

-- UNION ALL: mantém todos os registros (os IDs são independentes entre sistemas)
todos_funcionarios as (

    select * from admin
    union all
    select * from motoristas

)

select
    -- generate_surrogate_key cria um hash MD5 dos campos fornecidos
    -- Garante unicidade mesmo com IDs iguais entre sistemas diferentes
    {{ dbt_utils.generate_surrogate_key(['sistema_origem', 'funcionario_id']) }}
        as sk_funcionario,

    funcionario_id,
    empresa_id,
    sistema_origem,
    nome,
    cpf,
    data_nascimento,
    data_admissao,
    data_demissao,
    setor,
    departamento,
    cargo,
    categoria,
    salario,
    status

from todos_funcionarios
