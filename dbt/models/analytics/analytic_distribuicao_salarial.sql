-- =============================================================================
-- models/analytics/analytic_distribuicao_salarial.sql (PASSO 5k)
-- =============================================================================
-- VISÃO ANALÍTICA: Distribuição Salarial por Cargo e Categoria
--
-- PROBLEMA QUE RESOLVE:
--   O sistema OLTP armazena o salário de cada funcionário individualmente.
--   O analista de RH precisa de uma visão estatística para:
--     • Detectar anomalias salariais (outliers fora da banda esperada)
--     • Comparar equidade salarial entre departamentos/empresas
--     • Preparar revisões de tabela salarial (salary bands)
--     • Subsidiar processos seletivos com referência de mercado interno
--     • Identificar risco de inequidade de gênero/senioridade
--
-- MÉTRICAS ESTATÍSTICAS:
--   - salario_minimo / salario_maximo: extremos da faixa
--   - salario_medio: média (sensível a outliers)
--   - salario_mediana (P50): valor central (mais robusto)
--   - salario_p25 / salario_p75: quartis (banda salarial interquartil)
--   - amplitude_iqr: P75 - P25 (dispersão da banda central)
--   - desvio_padrao: variabilidade geral
--   - folha_total: impacto financeiro total por grupo
-- =============================================================================

with funcionarios as (

    select
        sk_funcionario,
        cargo,
        categoria,
        departamento,
        setor,
        sistema_origem,
        status,
        salario,
        faixa_salarial,
        sk_empresa
    from {{ ref('dim_funcionario') }}

),

empresas as (

    select sk_empresa, razao_social
    from {{ ref('dim_empresa') }}

)

select
    f.cargo,
    f.categoria,
    f.departamento,
    f.setor,
    f.sistema_origem,
    e.razao_social                                          as empresa,
    f.status,

    -- Volume
    count(*)                                                as total_funcionarios,

    -- Estatísticas salariais
    round(min(f.salario)::numeric, 2)                       as salario_minimo,
    round(max(f.salario)::numeric, 2)                       as salario_maximo,
    round(avg(f.salario)::numeric, 2)                       as salario_medio,

    -- Percentis (usando percentile_cont = interpolação contínua)
    round(percentile_cont(0.25) within group (order by f.salario)::numeric, 2)
                                                            as salario_p25,
    round(percentile_cont(0.50) within group (order by f.salario)::numeric, 2)
                                                            as salario_mediana,
    round(percentile_cont(0.75) within group (order by f.salario)::numeric, 2)
                                                            as salario_p75,

    -- Amplitude interquartil (IQR): dispersão da faixa central (P75 - P25)
    round(
        (percentile_cont(0.75) within group (order by f.salario)
         - percentile_cont(0.25) within group (order by f.salario))::numeric,
        2
    )                                                       as amplitude_iqr,

    -- Desvio padrão (quanto os salários variam em torno da média)
    round(stddev(f.salario)::numeric, 2)                    as desvio_padrao,

    -- Coeficiente de variação (desvio / média): mede homogeneidade da faixa
    round(stddev(f.salario)::numeric / nullif(avg(f.salario), 0) * 100, 1)
                                                            as coeficiente_variacao_pct,

    -- Impacto financeiro
    round(sum(f.salario)::numeric, 2)                       as folha_total,
    round(avg(f.salario)::numeric, 2)                       as custo_medio_por_posicao

from funcionarios f
inner join empresas e on f.sk_empresa = e.sk_empresa

group by
    f.cargo, f.categoria, f.departamento, f.setor,
    f.sistema_origem, e.razao_social, f.status

order by f.departamento, f.cargo, f.categoria
