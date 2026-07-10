
  create view "db_dw"."analytics"."analytic_horas_mensais__dbt_tmp"
    
    
  as (
    -- =============================================================================
-- models/analytics/analytic_horas_mensais.sql
-- =============================================================================

with fato as (

    select * from "db_dw"."marts"."fato_ponto"

),

funcionarios as (

    select
        sk_funcionario,
        nome,
        cargo,
        departamento,
        sistema_origem
    from "db_dw"."marts"."dim_funcionario"

),

datas as (

    select sk_data, ano, mes, mes_nome, ano_mes
    from "db_dw"."marts"."dim_data"

)

select
    d.ano,
    d.mes,
    d.mes_nome,
    d.ano_mes,

    f.sk_funcionario,
    f.nome,
    f.cargo,
    f.departamento,
    f.sistema_origem,

    count(*) as dias_trabalhados,

    round(sum(fp.horas_trabalhadas)::numeric, 2) as total_horas_trabalhadas,
    round(sum(fp.jornada_contratada_horas)::numeric, 2) as total_horas_contratadas,
    round(sum(fp.saldo_horas_dia)::numeric, 2) as saldo_horas,
    round(sum(fp.horas_extras)::numeric, 2) as total_horas_extras,

    sum(case when fp.flag_atraso then 1 else 0 end) as dias_com_atraso

from fato fp
inner join funcionarios f   on fp.sk_funcionario = f.sk_funcionario
inner join datas d          on fp.sk_data        = d.sk_data

group by
    d.ano, d.mes, d.mes_nome, d.ano_mes,
    f.sk_funcionario, f.nome, f.cargo, f.departamento, f.sistema_origem
  );