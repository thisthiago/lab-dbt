-- =============================================================================
-- models/analytics/analytic_antiguidade_funcionarios.sql (PASSO 5i)
-- =============================================================================
-- VISÃO ANALÍTICA: Distribuição de Tempo de Casa (Antiguidade)
--
-- PROBLEMA QUE RESOLVE:
--   O sistema apenas armazena data_admissao, mas não classifica os funcionários
--   por faixas de tempo de casa. O analista de RH precisa desse dado para:
--
--     • Planejamento de sucessão: identificar concentração em "0-1 ano" (risco)
--     • Retenção de talentos: quais departamentos perdem profissionais experientes?
--     • Programas de reconhecimento: quem completou 5, 10 anos?
--     • Análise de conhecimento tácito: muito "< 1 ano" = perda de know-how
--     • Due diligence trabalhista: passivos de rescisão (+ tempo = + custo)
--
-- SAÍDA:
--   Distribuição percentual de funcionários por faixa de antiguidade,
--   segmentada por empresa, departamento, cargo e categoria.
-- =============================================================================

with funcionarios as (

    select
        sk_funcionario,
        status,
        departamento,
        setor,
        cargo,
        categoria,
        sistema_origem,
        faixa_antiguidade,
        tempo_empresa_meses,
        salario,
        sk_empresa
    from {{ ref('dim_funcionario') }}

),

empresas as (

    select sk_empresa, razao_social
    from {{ ref('dim_empresa') }}

),

base as (

    select
        f.status,
        f.departamento,
        f.setor,
        f.cargo,
        f.categoria,
        f.sistema_origem,
        e.razao_social                                  as empresa,
        f.faixa_antiguidade,

        count(*)                                        as quantidade_funcionarios,
        round(avg(f.salario)::numeric, 2)               as salario_medio,
        round(avg(f.tempo_empresa_meses)::numeric, 1)   as tempo_medio_meses,
        round(min(f.tempo_empresa_meses)::numeric, 0)   as tempo_minimo_meses,
        round(max(f.tempo_empresa_meses)::numeric, 0)   as tempo_maximo_meses

    from funcionarios f
    inner join empresas e on f.sk_empresa = e.sk_empresa

    group by
        f.status, f.departamento, f.setor, f.cargo,
        f.categoria, f.sistema_origem, e.razao_social, f.faixa_antiguidade

),

-- Total por grupo (para calcular percentual)
totais_por_grupo as (

    select
        status, departamento, empresa,
        sum(quantidade_funcionarios)    as total_grupo

    from base
    group by status, departamento, empresa

)

select
    b.*,
    t.total_grupo,
    round(b.quantidade_funcionarios::numeric / nullif(t.total_grupo, 0) * 100, 1)
                                                        as percentual_na_faixa,
    -- Flag de risco: > 40% do time com menos de 1 ano = alto risco de conhecimento
    case
        when b.faixa_antiguidade = '0-1 ano'
          and round(b.quantidade_funcionarios::numeric / nullif(t.total_grupo, 0) * 100, 1) > 40
        then true else false
    end                                                 as flag_risco_conhecimento_tacito

from base b
inner join totais_por_grupo t
    on  b.status       = t.status
    and b.departamento = t.departamento
    and b.empresa      = t.empresa

order by b.empresa, b.departamento, b.faixa_antiguidade
