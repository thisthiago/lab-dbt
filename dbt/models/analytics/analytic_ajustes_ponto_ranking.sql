-- =============================================================================
-- models/analytics/analytic_ajustes_ponto_ranking.sql (PASSO 5f)
-- =============================================================================
-- VISÃO ANALÍTICA: Ranking e Análise de Ajustes de Ponto
--
-- PROBLEMA QUE RESOLVE:
--   O sistema guarda cada solicitação de ajuste individualmente, mas o analista
--   de RH precisa de padrões para:
--     • Identificar funcionários que frequentemente esquecem de bater ponto
--     • Detectar departamentos com equipamentos com defeito ("Problema no sistema")
--     • Monitorar a taxa de aprovação dos gestores (gestores muito rigorosos?)
--     • Avaliar carga de trabalho do setor de RH com análise de pendentes
--
-- OBS: Esta view usa apenas o sistema 'admin' pois é onde os ajustes
--      são mais frequentes. Pode-se expandir para motoristas se necessário.
-- =============================================================================

with ajustes as (

    select * from {{ ref('stg_admin__ajustes') }}

),

funcionarios as (

    select
        sk_funcionario,
        funcionario_id,
        nome,
        departamento,
        cargo,
        empresa_razao_social
    from {{ ref('dim_funcionario') }}
    where sistema_origem = 'admin'

),

base as (

    select
        extract(year  from a.data_solicitacao)::int     as ano,
        extract(month from a.data_solicitacao)::int     as mes,
        to_char(a.data_solicitacao, 'YYYY-MM')          as ano_mes,

        f.sk_funcionario,
        f.nome,
        f.departamento,
        f.cargo,
        f.empresa_razao_social                          as empresa,

        -- Contagens por status
        count(*)                                        as total_ajustes,
        count(*) filter (where a.status = 'Aprovado')   as ajustes_aprovados,
        count(*) filter (where a.status = 'Reprovado')  as ajustes_reprovados,
        count(*) filter (where a.status = 'Pendente')   as ajustes_pendentes,

        -- Taxa de aprovação
        round(
            count(*) filter (where a.status = 'Aprovado')::numeric
            / nullif(count(*), 0) * 100,
            1
        )                                               as taxa_aprovacao_pct,

        -- Motivo mais frequente
        mode() within group (order by a.motivo)         as motivo_mais_frequente

    from ajustes a
    inner join funcionarios f
        on a.funcionario_id = f.funcionario_id

    group by
        ano, mes, ano_mes,
        f.sk_funcionario, f.nome, f.departamento, f.cargo, f.empresa_razao_social

)

select
    *,
    -- Ranking de ajustes por departamento no mês
    rank() over (
        partition by ano_mes, departamento
        order by total_ajustes desc
    )                                                   as ranking_no_departamento,

    -- Classificação do volume de ajustes
    case
        when total_ajustes = 0 then '🟢 Sem ocorrências'
        when total_ajustes <= 2 then '🟡 Ocasional (1-2/mês)'
        when total_ajustes <= 5 then '🟠 Frequente (3-5/mês)'
        else                        '🔴 Crítico (6+/mês)'
    end                                                 as classificacao_volume

from base
order by ano_mes desc, total_ajustes desc
