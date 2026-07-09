-- =============================================================================
-- models/marts/dim_funcionario.sql (PASSO 4b)
-- =============================================================================
-- DIMENSÃO: Funcionário
-- Granularidade: 1 linha por funcionário (admin + motoristas unificados)
-- Tipo: Dimensão estática (SCD Tipo 1 — apenas estado atual)
--
-- Enriquecimentos aplicados:
--   - Cálculo de idade atual
--   - Cálculo de tempo de empresa em meses
--   - Join com empresa para desnormalizar razão social
--   - Faixa etária e faixa salarial (categóricas para análise)
-- =============================================================================

with funcionarios as (

    select * from {{ ref('int_funcionarios_unificados') }}

),

empresas as (

    select * from {{ ref('dim_empresa') }}

),

enriquecido as (

    select
        -- Chave surrogate (herdada do intermediate)
        f.sk_funcionario,

        -- Chaves naturais e de relacionamento
        f.funcionario_id,
        f.sistema_origem,
        f.empresa_id,

        -- Dados pessoais (sensíveis — proteger conforme LGPD)
        f.nome,
        f.cpf,
        f.data_nascimento,
        date_part('year', age(current_date, f.data_nascimento))::int
                                                            as idade,

        -- Dados do contrato
        f.data_admissao,
        f.data_demissao,
        f.setor,
        f.departamento,
        f.cargo,
        f.categoria,
        f.salario,
        f.status,

        -- Tempo de empresa em meses (calculado até data_demissao ou hoje)
        case
            when f.data_demissao is not null then
                (date_part('year',  age(f.data_demissao, f.data_admissao)) * 12
                 + date_part('month', age(f.data_demissao, f.data_admissao)))::int
            else
                (date_part('year',  age(current_date, f.data_admissao)) * 12
                 + date_part('month', age(current_date, f.data_admissao)))::int
        end                                                 as tempo_empresa_meses,

        -- Dimensão empresa (desnormalizada para facilitar consultas)
        e.sk_empresa,
        e.razao_social                                      as empresa_razao_social,
        e.cnpj                                              as empresa_cnpj

    from funcionarios f
    left join empresas e
        on f.empresa_id = e.sk_empresa

)

select
    *,
    -- Faixa etária (útil para análises de diversidade/sucessão)
    case
        when idade < 25 then '18-24 anos'
        when idade < 35 then '25-34 anos'
        when idade < 45 then '35-44 anos'
        when idade < 55 then '45-54 anos'
        else                 '55+ anos'
    end                                                     as faixa_etaria,

    -- Faixa de tempo de empresa
    case
        when tempo_empresa_meses < 12  then '0-1 ano'
        when tempo_empresa_meses < 36  then '1-3 anos'
        when tempo_empresa_meses < 60  then '3-5 anos'
        when tempo_empresa_meses < 120 then '5-10 anos'
        else                                '10+ anos'
    end                                                     as faixa_antiguidade,

    -- Faixa salarial (útil para análises sem expor salário exato)
    case
        when salario < 2000  then 'A — Até R$2.000'
        when salario < 4000  then 'B — R$2.001 a R$4.000'
        when salario < 7000  then 'C — R$4.001 a R$7.000'
        when salario < 12000 then 'D — R$7.001 a R$12.000'
        else                      'E — Acima de R$12.000'
    end                                                     as faixa_salarial

from enriquecido
