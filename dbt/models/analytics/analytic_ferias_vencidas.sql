-- =============================================================================
-- models/analytics/analytic_ferias_vencidas.sql (PASSO 5e)
-- =============================================================================
-- VISÃO ANALÍTICA: Férias Vencidas e Passivo Trabalhista
--
-- PROBLEMA QUE RESOLVE:
--   A CLT (art. 134) determina que férias devem ser concedidas em até 12 meses
--   após o período aquisitivo (1 ano de trabalho). O não cumprimento gera:
--     • Pagamento em dobro (art. 137 CLT)
--     • Multa administrativa
--     • Passivo trabalhista relevante
--
--   O sistema OLTP guarda as datas mas NUNCA alerta sobre esse risco.
--   Esta view é uma ferramenta de gestão preventiva de passivo.
--
-- CLASSIFICAÇÃO:
--   🔴 VENCIDAS: > 365 dias sem férias → risco legal imediato
--   🟠 ATENÇÃO:  270-365 dias         → programar com urgência
--   🟡 MONITORAR: 180-270 dias        → acompanhar
--   🟢 REGULAR:  < 180 dias           → ok
-- =============================================================================

with funcionarios as (

    select
        sk_funcionario,
        nome,
        cpf,
        cargo,
        departamento,
        setor,
        empresa_razao_social,
        data_admissao,
        status,
        sistema_origem
    from {{ ref('dim_funcionario') }}

),

-- Última data de término de férias por funcionário
ultima_ferias as (

    select
        sk_funcionario,
        max(data_fim)   as ultima_data_ferias
    from {{ ref('fato_ferias') }}
    group by sk_funcionario

)

select
    f.sk_funcionario,
    f.nome,
    f.cargo,
    f.departamento,
    f.setor,
    f.empresa_razao_social                          as empresa,
    f.sistema_origem,
    f.data_admissao,

    -- Referência: última vez que voltou de férias (ou data de admissão se nunca tirou)
    coalesce(uf.ultima_data_ferias, f.data_admissao)
                                                    as referencia_ferias,

    uf.ultima_data_ferias,

    -- Quantos dias sem férias desde a última vez (ou desde a admissão)
    current_date - coalesce(uf.ultima_data_ferias, f.data_admissao)
                                                    as dias_sem_ferias,

    -- Classificação de risco
    case
        when current_date - coalesce(uf.ultima_data_ferias, f.data_admissao) > 365
            then '🔴 VENCIDAS — Risco Legal'
        when current_date - coalesce(uf.ultima_data_ferias, f.data_admissao) > 270
            then '🟠 ATENÇÃO — Programar urgente'
        when current_date - coalesce(uf.ultima_data_ferias, f.data_admissao) > 180
            then '🟡 MONITORAR'
        else
            '🟢 REGULAR'
    end                                             as status_ferias,

    -- Se nunca tirou férias
    case when uf.ultima_data_ferias is null then true else false end
                                                    as nunca_tirou_ferias

from funcionarios f
left join ultima_ferias uf on f.sk_funcionario = uf.sk_funcionario

where
    f.status = 'Ativo'                              -- apenas funcionários ativos
    and current_date - f.data_admissao > 365        -- só quem já adquiriu direito (1 ano)

order by dias_sem_ferias desc
