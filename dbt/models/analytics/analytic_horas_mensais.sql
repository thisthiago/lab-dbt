-- =============================================================================
-- models/analytics/analytic_horas_mensais.sql (PASSO 5a)
-- =============================================================================
-- VISÃO ANALÍTICA: Consolidação Mensal de Horas por Funcionário
--
-- PROBLEMA QUE RESOLVE:
--   O sistema OLTP armazena batidas individuais (entrada/saída).
--   O analista de RH precisa de uma visão consolidada por mês para:
--     • Verificar cumprimento da jornada contratada
--     • Identificar quem tem saldo positivo/negativo de horas
--     • Comparar performance entre funcionários
--
-- MÉTRICAS:
--   - dias_trabalhados: quantos dias o funcionário bateu ponto no mês
--   - total_horas_trabalhadas: soma de horas efetivas no mês
--   - total_horas_contratadas: o que deveria ter trabalhado (dias × jornada)
--   - saldo_horas: diferença (positivo = banco de horas; negativo = débito)
--   - total_horas_extras: horas acima da jornada diária acumuladas no mês
--   - dias_com_atraso: quantos dias o funcionário chegou tarde
-- =============================================================================

with fato as (

    select * from {{ ref('fato_ponto') }}

),

funcionarios as (

    select
        sk_funcionario,
        nome,
        cargo,
        departamento,
        setor,
        categoria,
        sistema_origem
    from {{ ref('dim_funcionario') }}

),

datas as (

    select sk_data, ano, mes, mes_nome, ano_mes
    from {{ ref('dim_data') }}

),

empresas as (

    select sk_empresa, razao_social
    from {{ ref('dim_empresa') }}

)

select
    -- Contexto temporal
    d.ano,
    d.mes,
    d.mes_nome,
    d.ano_mes,

    -- Contexto do funcionário
    f.sk_funcionario,
    f.nome,
    f.cargo,
    f.departamento,
    f.setor,
    f.categoria,
    f.sistema_origem,
    e.razao_social                                          as empresa,

    -- Métricas de presença
    count(*)                                                as dias_trabalhados,

    -- Métricas de jornada
    round(sum(fp.horas_trabalhadas)::numeric, 2)            as total_horas_trabalhadas,
    round(sum(fp.jornada_contratada_horas)::numeric, 2)     as total_horas_contratadas,
    round(sum(fp.saldo_horas_dia)::numeric, 2)              as saldo_horas,
    round(sum(fp.horas_extras)::numeric, 2)                 as total_horas_extras,

    -- Métricas de pontualidade
    sum(case when fp.flag_atraso then 1 else 0 end)         as dias_com_atraso,
    round(
        sum(case when fp.flag_atraso then 1 else 0 end)::numeric
        / nullif(count(*), 0) * 100,
        1
    )                                                       as percentual_dias_com_atraso

from fato fp
inner join funcionarios f   on fp.sk_funcionario = f.sk_funcionario
inner join datas d          on fp.sk_data        = d.sk_data
inner join empresas e       on fp.sk_empresa     = e.sk_empresa

group by
    d.ano, d.mes, d.mes_nome, d.ano_mes,
    f.sk_funcionario, f.nome, f.cargo, f.departamento,
    f.setor, f.categoria, f.sistema_origem, e.razao_social
