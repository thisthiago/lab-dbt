-- =============================================================================
-- models/analytics/analytic_custo_hora_departamento.sql (PASSO 5j)
-- =============================================================================
-- VISÃO ANALÍTICA: Custo por Hora Trabalhada por Departamento
--
-- PROBLEMA QUE RESOLVE:
--   Nenhum sistema OLTP calcula o custo real por hora de trabalho.
--   O analista de RH e os gestores precisam desse dado para:
--     • Precificação de projetos internos (ex: "projeto X consumiu X horas de TI")
--     • Benchmarking entre departamentos e empresas do grupo
--     • Análise de eficiência: horas pagas vs horas produtivas
--     • Identificar onde horas extras custam mais (altas faixas salariais)
--
-- LÓGICA DE CÁLCULO:
--   Custo/hora = Massa salarial do mês / Horas efetivamente trabalhadas
--   Massa salarial = soma dos salários dos funcionários ativos no período
--
-- OBS: Este é o custo DIRETO (salário). Em produção, multiplica-se por
--      ~1.7–2.0 para incluir encargos (INSS, FGTS, férias provisionadas, etc.)
-- =============================================================================

with fato as (

    select * from {{ ref('fato_ponto') }}

),

funcionarios as (

    select
        sk_funcionario,
        departamento,
        setor,
        cargo,
        categoria,
        sistema_origem,
        salario,
        sk_empresa
    from {{ ref('dim_funcionario') }}

),

datas as (

    select sk_data, ano, mes, mes_nome, ano_mes
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
        d.mes_nome,
        d.ano_mes,
        f.departamento,
        f.setor,
        f.cargo,
        f.categoria,
        f.sistema_origem,
        e.razao_social                                          as empresa,

        count(distinct fp.sk_funcionario)                       as num_funcionarios,
        round(sum(fp.horas_trabalhadas)::numeric, 2)            as total_horas_trabalhadas,
        round(sum(fp.horas_extras)::numeric, 2)                 as total_horas_extras,

        -- Massa salarial do período: salário ÷ 22 dias úteis × dias presentes
        -- (estimativa proporcional ao trabalho realizado)
        round(
            sum(f.salario / 22.0)::numeric, 2
        )                                                       as massa_salarial_estimada_mes,

        -- Custo teórico por hora (salário / jornada mensal esperada)
        round(
            avg(f.salario / (
                case when f.categoria = 'Estagiário' then 6.0 * 22.0
                     else 8.0 * 22.0
                end
            ))::numeric,
            4
        )                                                       as custo_hora_teorico_medio

    from fato fp
    inner join funcionarios f   on fp.sk_funcionario = f.sk_funcionario
    inner join datas d          on fp.sk_data        = d.sk_data
    inner join empresas e       on fp.sk_empresa     = e.sk_empresa

    group by
        d.ano, d.mes, d.mes_nome, d.ano_mes,
        f.departamento, f.setor, f.cargo, f.categoria,
        f.sistema_origem, e.razao_social

)

select
    *,

    -- Custo EFETIVO por hora: quanto foi pago por cada hora efetivamente trabalhada
    round(
        massa_salarial_estimada_mes / nullif(total_horas_trabalhadas, 0)::numeric,
        2
    )                                                           as custo_por_hora_efetivo,

    -- Eficiência: razão horas extras / total (ideal: baixa = jornada equilibrada)
    round(
        total_horas_extras / nullif(total_horas_trabalhadas, 0)::numeric * 100,
        1
    )                                                           as percentual_horas_extras,

    -- Fator de encargo estimado (didático: real varia por empresa)
    round(
        (massa_salarial_estimada_mes / nullif(total_horas_trabalhadas, 0)) * 1.75::numeric,
        2
    )                                                           as custo_hora_com_encargos_estimado

from base
order by ano_mes, empresa, departamento
