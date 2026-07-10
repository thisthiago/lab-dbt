-- =============================================================================
-- models/marts/fato_ponto.sql
-- =============================================================================

with apontamentos as (

    select * from {{ ref('int_apontamentos_diarios') }}

),

funcionarios as (

    select
        sk_funcionario,
        funcionario_id,
        sistema_origem,
        categoria
    from {{ ref('dim_funcionario') }}

),

datas as (

    select sk_data, data_completa
    from {{ ref('dim_data') }}

),

joined as (

    select
        a.funcionario_id,
        a.sistema_origem,
        a.data_apontamento,
        a.horas_trabalhadas,
        a.primeira_entrada,
        a.ultima_saida,
        a.num_pares_batida,

        f.sk_funcionario,
        d.sk_data,

        case
            when f.categoria = 'Estagiário' then 6.0
            else 8.0
        end as jornada_contratada_horas,

        greatest(
            0,
            a.horas_trabalhadas - case
                when f.categoria = 'Estagiário' then 6.0
                else 8.0
            end
        ) as horas_extras,

        case
            when extract(hour from a.primeira_entrada) > 8
              or (
                  extract(hour from a.primeira_entrada) = 8
                  and extract(minute from a.primeira_entrada) > 30
              )
            then true
            else false
        end as flag_atraso

    from apontamentos a
    inner join funcionarios f
        on  a.funcionario_id  = f.funcionario_id
        and a.sistema_origem  = f.sistema_origem
    inner join datas d
        on  a.data_apontamento = d.data_completa

)

select
    {{ dbt_utils.generate_surrogate_key(['sk_funcionario', 'sk_data']) }} as sk_fato_ponto,
    sk_funcionario,
    sk_data,
    data_apontamento,
    horas_trabalhadas,
    jornada_contratada_horas,
    horas_extras,
    round((horas_trabalhadas - jornada_contratada_horas)::numeric, 2) as saldo_horas_dia,
    num_pares_batida,
    flag_atraso,
    primeira_entrada,
    ultima_saida

from joined
