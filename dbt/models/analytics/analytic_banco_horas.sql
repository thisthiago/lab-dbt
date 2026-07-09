-- =============================================================================
-- models/analytics/analytic_banco_horas.sql (PASSO 5b)
-- =============================================================================
-- VISÃO ANALÍTICA: Banco de Horas Acumulado por Funcionário
--
-- PROBLEMA QUE RESOLVE:
--   O sistema OLTP não tem conceito de banco de horas.
--   O analista de RH precisa saber:
--     • Quem tem crédito acumulado de horas extras?
--     • Quem tem débito (trabalhou menos do que deveria)?
--     • Como evoluiu o saldo ao longo do tempo?
--
-- LÓGICA:
--   Usa window function SUM() OVER (PARTITION BY funcionário ORDER BY mês)
--   para calcular o saldo acumulado mês a mês (como um extrato bancário).
--
-- INTERPRETAÇÃO DO SALDO:
--   Positivo (+) → funcionário tem horas a receber (banco de horas ativo)
--   Negativo (-) → funcionário deve horas (absenteísmo / saídas antecipadas)
-- =============================================================================

with horas_mensais as (

    -- Reutiliza a visão de horas mensais já calculada
    select * from {{ ref('analytic_horas_mensais') }}

)

select
    -- Contexto temporal
    ano_mes,
    ano,
    mes,
    mes_nome,

    -- Contexto do funcionário
    sk_funcionario,
    nome,
    cargo,
    departamento,
    empresa,
    categoria,

    -- Métricas do mês
    dias_trabalhados,
    total_horas_trabalhadas,
    total_horas_contratadas,
    saldo_horas                                         as saldo_horas_mes,

    -- BANCO DE HORAS: saldo acumulado mês a mês por funcionário
    -- Equivale a um extrato bancário de horas
    round(
        sum(saldo_horas) over (
            partition by sk_funcionario
            order by ano_mes
            rows between unbounded preceding and current row
        )::numeric,
        2
    )                                                   as saldo_acumulado_horas,

    -- Horas extras acumuladas (só o excedente positivo, sem descontar débitos)
    round(
        sum(total_horas_extras) over (
            partition by sk_funcionario
            order by ano_mes
            rows between unbounded preceding and current row
        )::numeric,
        2
    )                                                   as horas_extras_acumuladas,

    -- Classificação do saldo atual
    case
        when saldo_horas > 10  then 'Alto Crédito (> 10h no mês)'
        when saldo_horas > 0   then 'Crédito'
        when saldo_horas = 0   then 'Equilibrado'
        when saldo_horas > -10 then 'Débito'
        else                        'Alto Débito (> 10h no mês)'
    end                                                 as classificacao_saldo_mes

from horas_mensais
