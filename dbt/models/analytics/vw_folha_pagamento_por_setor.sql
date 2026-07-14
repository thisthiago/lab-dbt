-- =============================================================================
-- models/analytics/vw_folha_pagamento_por_setor.sql
-- =============================================================================
-- Objetivo: Trazer o total gasto com folha de pagamento por setor no último
--           mês em que houve apontamento de ponto registrado.
-- =============================================================================

with funcionarios as (

    select * from {{ ref('dim_funcionario') }}

),

fato_ponto as (

    select * from {{ ref('fato_ponto') }}

),

ultimo_mes as (

    -- Identifica o ano_mes do último apontamento de ponto registrado no sistema
    select
        to_char(max(data_apontamento), 'YYYY-MM') as ref_ano_mes
    from fato_ponto

)

select
    f.setor,
    count(distinct f.sk_funcionario) as total_funcionarios,
    sum(f.salario) as total_gasto_folha,
    (select ref_ano_mes from ultimo_mes) as mes_referencia

from funcionarios f
where f.status = 'Ativo'
  -- Filtramos funcionários que foram admitidos até o último dia do mês de referência
  and to_char(f.data_admissao, 'YYYY-MM') <= (select ref_ano_mes from ultimo_mes)
group by f.setor, mes_referencia
order by total_gasto_folha desc

