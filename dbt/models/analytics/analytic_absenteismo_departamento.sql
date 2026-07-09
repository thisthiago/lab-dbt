-- =============================================================================
-- models/analytics/analytic_absenteismo_departamento.sql (PASSO 5d)
-- =============================================================================
-- VISÃO ANALÍTICA: Taxa de Absenteísmo por Departamento
--
-- PROBLEMA QUE RESOLVE:
--   Absenteísmo é invisível no sistema OLTP — ele registra QUANDO alguém
--   bate ponto, não QUANDO alguém deveria ter batido e não bateu.
--   O analista de RH precisa:
--     • Comparar a taxa de faltas entre departamentos
--     • Identificar sazonalidade do absenteísmo (épocas do ano)
--     • Subsidiar políticas de saúde ocupacional e gestão de pessoas
--
-- LÓGICA:
--   Taxa de absenteísmo = (dias possíveis - dias presentes) / dias possíveis
--   onde "dias possíveis" = funcionários ativos no mês × dias úteis do mês
--
-- NOTA DIDÁTICA:
--   Esta visão simplifica ao não descontar férias dos dias possíveis.
--   Em produção, subtrairia os dias de férias de cada funcionário.
-- =============================================================================

with fato as (

    select * from {{ ref('fato_ponto') }}

),

funcionarios as (

    select sk_funcionario, departamento, setor, sistema_origem
    from {{ ref('dim_funcionario') }}

),

datas as (

    select sk_data, ano, mes, mes_nome, ano_mes, flag_dia_util, data_completa
    from {{ ref('dim_data') }}

),

empresas as (

    select sk_empresa, razao_social
    from {{ ref('dim_empresa') }}

),

-- Calcula dias úteis por mês no período analisado
dias_uteis_por_mes as (

    select
        ano_mes,
        ano,
        mes,
        mes_nome,
        count(*)    as total_dias_uteis

    from datas
    where flag_dia_util = true
      and data_completa between '2020-01-01' and current_date
    group by ano_mes, ano, mes, mes_nome

),

-- Conta presença por departamento/mês
presenca_departamento as (

    select
        d.ano_mes,
        f.departamento,
        f.setor,
        e.razao_social                          as empresa,

        -- Funcionários distintos que bateram ponto no mês
        count(distinct fp.sk_funcionario)       as funcionarios_presentes,

        -- Total de dias-presença (ex: 20 funcionários × 18 dias = 360 dias-presença)
        count(*)                                as total_dias_presentes

    from fato fp
    inner join funcionarios f   on fp.sk_funcionario = f.sk_funcionario
    inner join datas d          on fp.sk_data        = d.sk_data
    inner join empresas e       on fp.sk_empresa     = e.sk_empresa

    group by d.ano_mes, f.departamento, f.setor, e.razao_social

)

select
    p.ano_mes,
    du.ano,
    du.mes,
    du.mes_nome,
    p.departamento,
    p.setor,
    p.empresa,

    p.funcionarios_presentes,
    du.total_dias_uteis,

    -- Dias possíveis = funcionários × dias úteis do mês
    p.funcionarios_presentes * du.total_dias_uteis  as dias_possiveis,
    p.total_dias_presentes                          as dias_presentes,

    -- Dias de ausência estimados
    (p.funcionarios_presentes * du.total_dias_uteis)
     - p.total_dias_presentes                       as dias_ausentes_estimados,

    -- Taxa de absenteísmo (%)
    round(
        (
            (p.funcionarios_presentes * du.total_dias_uteis)
            - p.total_dias_presentes
        )::numeric
        / nullif(p.funcionarios_presentes * du.total_dias_uteis, 0) * 100,
        2
    )                                               as taxa_absenteismo_pct,

    -- Classificação do nível de absenteísmo
    case
        when round(
            ((p.funcionarios_presentes * du.total_dias_uteis) - p.total_dias_presentes)::numeric
            / nullif(p.funcionarios_presentes * du.total_dias_uteis, 0) * 100, 2
        ) <= 2  then '🟢 Baixo (até 2%)'
        when round(
            ((p.funcionarios_presentes * du.total_dias_uteis) - p.total_dias_presentes)::numeric
            / nullif(p.funcionarios_presentes * du.total_dias_uteis, 0) * 100, 2
        ) <= 5  then '🟡 Moderado (2-5%)'
        when round(
            ((p.funcionarios_presentes * du.total_dias_uteis) - p.total_dias_presentes)::numeric
            / nullif(p.funcionarios_presentes * du.total_dias_uteis, 0) * 100, 2
        ) <= 10 then '🟠 Alto (5-10%)'
        else         '🔴 Crítico (> 10%)'
    end                                             as nivel_absenteismo

from presenca_departamento p
inner join dias_uteis_por_mes du using (ano_mes)
order by p.empresa, p.departamento, p.ano_mes
