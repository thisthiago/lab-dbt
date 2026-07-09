-- =============================================================================
-- models/analytics/analytic_atrasos_por_funcionario.sql (PASSO 5c)
-- =============================================================================
-- VISÃO ANALÍTICA: Ranking de Atrasos por Funcionário
--
-- PROBLEMA QUE RESOLVE:
--   O sistema registra a hora da batida, mas não classifica como "atraso".
--   O analista de RH precisa identificar padrões de pontualidade para:
--     • Conversas de feedback com gestores
--     • Identificar áreas/turnos com problema sistêmico
--     • Subsidiar avaliações de desempenho
--
-- MÉTRICAS:
--   - dias_com_atraso: absoluto
--   - percentual_atraso: % dos dias trabalhados com atraso
--   - ranking: posição do funcionário por atrasos dentro do seu departamento
-- =============================================================================

with fato as (

    select * from {{ ref('fato_ponto') }}

),

funcionarios as (

    select sk_funcionario, nome, cargo, departamento, setor, sistema_origem
    from {{ ref('dim_funcionario') }}

),

datas as (

    select sk_data, ano, mes, ano_mes
    from {{ ref('dim_data') }}

),

empresas as (

    select sk_empresa, razao_social
    from {{ ref('dim_empresa') }}

),

base as (

    select
        d.ano,
        d.mes,
        d.ano_mes,

        f.sk_funcionario,
        f.nome,
        f.cargo,
        f.departamento,
        f.setor,
        e.razao_social                                      as empresa,

        count(*)                                            as total_dias_trabalhados,

        sum(case when fp.flag_atraso then 1 else 0 end)     as dias_com_atraso,

        round(
            sum(case when fp.flag_atraso then 1 else 0 end)::numeric
            / nullif(count(*), 0) * 100,
            1
        )                                                   as percentual_atraso

    from fato fp
    inner join funcionarios f   on fp.sk_funcionario = f.sk_funcionario
    inner join datas d          on fp.sk_data        = d.sk_data
    inner join empresas e       on fp.sk_empresa     = e.sk_empresa

    group by
        d.ano, d.mes, d.ano_mes,
        f.sk_funcionario, f.nome, f.cargo, f.departamento, f.setor, e.razao_social

)

select
    *,
    -- Ranking de atrasos dentro do mesmo departamento/mês
    rank() over (
        partition by ano_mes, departamento
        order by dias_com_atraso desc
    )                                                       as ranking_atraso_no_departamento,

    -- Classificação de pontualidade
    case
        when percentual_atraso = 0    then '🟢 Pontual'
        when percentual_atraso < 20   then '🟡 Eventual'
        when percentual_atraso < 50   then '🟠 Frequente'
        else                               '🔴 Crítico'
    end                                                     as classificacao_pontualidade

from base
