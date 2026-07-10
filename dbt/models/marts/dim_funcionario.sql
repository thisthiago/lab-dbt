-- =============================================================================
-- models/marts/dim_funcionario.sql
-- =============================================================================

with funcionarios as (

    select * from {{ ref('int_funcionarios_unificados') }}

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
