-- =============================================================================
-- models/analytics/analytic_headcount_mensal.sql (PASSO 5g)
-- =============================================================================
-- VISÃO ANALÍTICA: Evolução Mensal do Headcount
--
-- PROBLEMA QUE RESOLVE:
--   O sistema OLTP mostra quem está ativo AGORA, mas não a evolução histórica.
--   O analista de RH precisa responder:
--     • Quantos funcionários tínhamos em março de 2023?
--     • Em qual mês tivemos mais motoristas?
--     • Como cresceu o departamento de TI nos últimos 2 anos?
--
-- LÓGICA:
--   Para cada mês, conta funcionários que:
--     1. Foram admitidos ANTES ou NO início do mês
--     2. Foram demitidos DEPOIS do início do mês (ou não foram demitidos)
--   = estavam ativos no início daquele mês
--
-- MÉTRICAS INCLUÍDAS:
--   - headcount_ativo: quantos funcionários ativos no início do mês
--   - salario_medio: remuneração média da equipe naquele snapshot
--   - folha_total_estimada: estimativa da massa salarial do mês
-- =============================================================================

with meses as (

    -- Um registro por mês no período analisado
    select distinct
        ano_mes,
        ano,
        mes,
        mes_nome,
        min(data_completa) over (partition by ano_mes) as primeiro_dia_mes

    from {{ ref('dim_data') }}
    where flag_dia_util = true
      and data_completa between '2020-01-01' and current_date

),

funcionarios as (

    select
        sk_funcionario,
        data_admissao,
        data_demissao,
        departamento,
        setor,
        cargo,
        categoria,
        salario,
        sistema_origem,
        sk_empresa
    from {{ ref('dim_funcionario') }}

),

empresas as (

    select sk_empresa, razao_social
    from {{ ref('dim_empresa') }}

),

-- Cross join: para cada mês, quais funcionários estavam ativos?
snapshots as (

    select
        m.ano_mes,
        m.ano,
        m.mes,
        m.mes_nome,
        m.primeiro_dia_mes,
        f.departamento,
        f.setor,
        f.cargo,
        f.categoria,
        f.sistema_origem,
        e.razao_social                  as empresa,
        f.salario

    from meses m
    cross join funcionarios f
    inner join empresas e on f.sk_empresa = e.sk_empresa

    where
        -- Estava admitido antes ou no início do mês
        f.data_admissao <= m.primeiro_dia_mes
        -- E ainda não tinha sido demitido (ou foi demitido depois do início do mês)
        and (f.data_demissao is null or f.data_demissao > m.primeiro_dia_mes)

)

select
    ano_mes,
    ano,
    mes,
    mes_nome,
    empresa,
    departamento,
    setor,
    cargo,
    categoria,
    sistema_origem,

    -- Métricas de headcount
    count(*)                                            as headcount_ativo,
    round(avg(salario)::numeric, 2)                     as salario_medio,
    round(sum(salario)::numeric, 2)                     as folha_total_estimada,
    round(max(salario)::numeric, 2)                     as salario_maximo,
    round(min(salario)::numeric, 2)                     as salario_minimo

from snapshots
group by
    ano_mes, ano, mes, mes_nome, empresa,
    departamento, setor, cargo, categoria, sistema_origem
order by ano_mes, empresa, departamento
