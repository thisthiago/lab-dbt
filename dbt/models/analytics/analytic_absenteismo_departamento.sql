-- =============================================================================
-- models/analytics/analytic_absenteismo_departamento.sql
-- =============================================================================

with fato as (

    select * from {{ ref('fato_ponto') }}

),

funcionarios as (

    select sk_funcionario, departamento
    from {{ ref('dim_funcionario') }}

),

datas as (

    select sk_data, ano_mes, flag_dia_util, data_completa
    from {{ ref('dim_data') }}

),

dias_uteis_por_mes as (

    select
        ano_mes,
        count(*) as total_dias_uteis
    from datas
    where flag_dia_util = true
      and data_completa between '2020-01-01' and current_date
    group by ano_mes

),

presenca_departamento as (

    select
        d.ano_mes,
        f.departamento,
        count(distinct fp.sk_funcionario) as funcionarios_presentes,
        count(*) as total_dias_presentes

    from fato fp
    inner join funcionarios f   on fp.sk_funcionario = f.sk_funcionario
    inner join datas d          on fp.sk_data        = d.sk_data

    group by d.ano_mes, f.departamento

)

select
    p.ano_mes,
    p.departamento,
    p.funcionarios_presentes,
    du.total_dias_uteis,

    p.funcionarios_presentes * du.total_dias_uteis as dias_possiveis,
    p.total_dias_presentes as dias_presentes,

    round(
        (
            (p.funcionarios_presentes * du.total_dias_uteis)
            - p.total_dias_presentes
        )::numeric
        / nullif(p.funcionarios_presentes * du.total_dias_uteis, 0) * 100,
        2
    ) as taxa_absenteismo_pct

from presenca_departamento p
inner join dias_uteis_por_mes du using (ano_mes)
order by p.departamento, p.ano_mes
