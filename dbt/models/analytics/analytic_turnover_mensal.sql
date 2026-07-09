-- =============================================================================
-- models/analytics/analytic_turnover_mensal.sql (PASSO 5h)
-- =============================================================================
-- VISÃO ANALÍTICA: Taxa de Turnover Mensal
--
-- PROBLEMA QUE RESOLVE:
--   O sistema armazena data_admissao e data_demissao, mas nunca calcula
--   a taxa de rotatividade. O analista de RH precisa:
--     • Monitorar a saúde organizacional mês a mês
--     • Comparar turnover entre empresas e departamentos
--     • Identificar meses sazonalmente críticos (ex: dezembro, pós-férias)
--     • Apresentar KPIs de RH para a diretoria
--
-- FÓRMULA DO TURNOVER (método de rotatividade):
--   Taxa = (Desligamentos / ((Headcount Início + Headcount Fim) / 2)) × 100
--   Simplificação: usamos admissões + desligamentos como denominador base
--
-- INTERPRETAÇÃO:
--   Turnover < 5%/mês   → Baixo (empresa saudável)
--   Turnover 5-10%/mês  → Moderado (atenção)
--   Turnover > 10%/mês  → Alto (problema sistêmico)
-- =============================================================================

with funcionarios as (

    select
        sk_funcionario,
        departamento,
        setor,
        sistema_origem,
        empresa_razao_social,
        data_admissao,
        data_demissao,
        status
    from {{ ref('dim_funcionario') }}

),

-- Admissões por mês
admissoes as (

    select
        to_char(data_admissao, 'YYYY-MM')   as ano_mes,
        departamento,
        empresa_razao_social                as empresa,
        sistema_origem,
        count(*)                            as admissoes

    from funcionarios
    where data_admissao >= '2020-01-01'
    group by
        to_char(data_admissao, 'YYYY-MM'),
        departamento, empresa_razao_social, sistema_origem

),

-- Desligamentos por mês
desligamentos as (

    select
        to_char(data_demissao, 'YYYY-MM')   as ano_mes,
        departamento,
        empresa_razao_social                as empresa,
        sistema_origem,
        count(*)                            as desligamentos

    from funcionarios
    where data_demissao is not null
      and data_demissao >= '2020-01-01'
    group by
        to_char(data_demissao, 'YYYY-MM'),
        departamento, empresa_razao_social, sistema_origem

),

-- Headcount ativo ao início de cada mês (para ser denominador mais preciso)
headcount_mensal as (

    select
        ano_mes,
        empresa,
        departamento,
        sistema_origem,
        sum(headcount_ativo) as headcount_ativo_mes

    from {{ ref('analytic_headcount_mensal') }}
    group by ano_mes, empresa, departamento, sistema_origem

),

-- Combina admissões e desligamentos
combined as (

    select
        coalesce(a.ano_mes,        d.ano_mes)         as ano_mes,
        coalesce(a.departamento,   d.departamento)     as departamento,
        coalesce(a.empresa,        d.empresa)          as empresa,
        coalesce(a.sistema_origem, d.sistema_origem)   as sistema_origem,
        coalesce(a.admissoes,      0)                  as admissoes,
        coalesce(d.desligamentos,  0)                  as desligamentos

    from admissoes a
    full outer join desligamentos d
        on  a.ano_mes        = d.ano_mes
        and a.departamento   = d.departamento
        and a.empresa        = d.empresa
        and a.sistema_origem = d.sistema_origem

)

select
    c.ano_mes,
    split_part(c.ano_mes, '-', 1)::int          as ano,
    split_part(c.ano_mes, '-', 2)::int          as mes,
    c.departamento,
    c.empresa,
    c.sistema_origem,
    c.admissoes,
    c.desligamentos,
    coalesce(h.headcount_ativo_mes, 0)          as headcount_no_mes,

    -- Taxa de turnover: desligamentos / headcount médio estimado × 100
    round(
        c.desligamentos::numeric
        / nullif(coalesce(h.headcount_ativo_mes, c.admissoes + c.desligamentos), 0) * 100,
        2
    )                                           as taxa_turnover_pct,

    -- Saldo líquido do mês (admissões - desligamentos)
    c.admissoes - c.desligamentos               as saldo_headcount,

    -- Classificação
    case
        when round(
            c.desligamentos::numeric
            / nullif(coalesce(h.headcount_ativo_mes, c.admissoes + c.desligamentos), 0) * 100,
            2
        ) <= 2  then '🟢 Baixo (≤ 2%)'
        when round(
            c.desligamentos::numeric
            / nullif(coalesce(h.headcount_ativo_mes, c.admissoes + c.desligamentos), 0) * 100,
            2
        ) <= 5  then '🟡 Moderado (2-5%)'
        when round(
            c.desligamentos::numeric
            / nullif(coalesce(h.headcount_ativo_mes, c.admissoes + c.desligamentos), 0) * 100,
            2
        ) <= 10 then '🟠 Alto (5-10%)'
        else         '🔴 Crítico (> 10%)'
    end                                         as classificacao_turnover

from combined c
left join headcount_mensal h
    on  c.ano_mes       = h.ano_mes
    and c.departamento  = h.departamento
    and c.empresa       = h.empresa
    and c.sistema_origem = h.sistema_origem

order by c.ano_mes, c.empresa, c.departamento
