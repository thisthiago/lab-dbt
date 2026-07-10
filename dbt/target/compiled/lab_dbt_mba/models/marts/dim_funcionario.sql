-- =============================================================================
-- models/marts/dim_funcionario.sql
-- =============================================================================

with  __dbt__cte__int_funcionarios_unificados as (
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

    select * from "db_dw"."staging"."stg_admin__funcionarios"

),

motoristas as (

    select * from "db_dw"."staging"."stg_motoristas__funcionarios"

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
    md5(cast(coalesce(cast(sistema_origem as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(funcionario_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
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
), funcionarios as (

    select * from __dbt__cte__int_funcionarios_unificados

)

select
    -- Chave surrogate (herdada do intermediate)
    f.sk_funcionario,

    -- Chaves naturais e de relacionamento
    f.funcionario_id,
    f.sistema_origem,
    f.empresa_id,

    -- Dados pessoais
    f.nome,
    f.cpf,
    f.data_nascimento,
    date_part('year', age(current_date, f.data_nascimento))::int as idade,

    -- Dados do contrato
    f.data_admissao,
    f.data_demissao,
    f.setor,
    f.departamento,
    f.cargo,
    f.categoria,
    f.salario,
    f.status,

    -- Tempo de empresa em meses
    case
        when f.data_demissao is not null then
            (date_part('year',  age(f.data_demissao, f.data_admissao)) * 12
             + date_part('month', age(f.data_demissao, f.data_admissao)))::int
        else
            (date_part('year',  age(current_date, f.data_admissao)) * 12
             + date_part('month', age(current_date, f.data_admissao)))::int
    end as tempo_empresa_meses,

    -- Faixa salarial
    case
        when f.salario < 2000  then 'A — Até R$2.000'
        when f.salario < 4000  then 'B — R$2.001 a R$4.000'
        when f.salario < 7000  then 'C — R$4.001 a R$7.000'
        when f.salario < 12000 then 'D — R$7.001 a R$12.000'
        else                        'E — Acima de R$12.000'
    end as faixa_salarial

from funcionarios f