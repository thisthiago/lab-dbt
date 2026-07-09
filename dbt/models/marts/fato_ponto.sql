-- =============================================================================
-- models/marts/fato_ponto.sql (PASSO 4d)
-- =============================================================================
-- FATO: Ponto Eletrônico
-- Granularidade: 1 linha por funcionário por dia trabalhado
-- Tipo: Fato transacional acumulado diário
--
-- Métricas disponíveis:
--   - horas_trabalhadas: total de horas efetivamente trabalhadas no dia
--   - jornada_contratada_horas: horas que deveria ter trabalhado (por categoria)
--   - horas_extras: horas acima da jornada contratada (máx 2h/dia legalmente)
--   - flag_atraso: TRUE se a primeira entrada foi após 08:30
--   - num_pares_batida: quantas vezes bateu entrada/saída no dia
--
-- Chaves estrangeiras:
--   - sk_funcionario → dim_funcionario
--   - sk_empresa     → dim_empresa
--   - sk_data        → dim_data
-- =============================================================================

with apontamentos as (

    select * from {{ ref('int_apontamentos_diarios') }}

),

funcionarios as (

    select
        sk_funcionario,
        funcionario_id,
        sistema_origem,
        sk_empresa,
        categoria,
        departamento,
        setor,
        cargo
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

        -- Chaves das dimensões
        f.sk_funcionario,
        f.sk_empresa,
        d.sk_data,

        -- Jornada contratada por categoria de trabalho
        case
            when f.categoria = 'Estagiário' then 6.0  -- CLT: 6h para estagiário
            else 8.0                                   -- padrão: 8h
        end                                                 as jornada_contratada_horas,

        -- Horas extras (positivo = excedente, 0 se dentro da jornada)
        greatest(
            0,
            a.horas_trabalhadas - case
                when f.categoria = 'Estagiário' then 6.0
                else 8.0
            end
        )                                                   as horas_extras,

        -- Flag de atraso: primeira entrada depois das 08:30
        case
            when extract(hour   from a.primeira_entrada) > 8
              or (
                  extract(hour   from a.primeira_entrada) = 8
                  and extract(minute from a.primeira_entrada) > 30
              )
            then true
            else false
        end                                                 as flag_atraso

    from apontamentos a
    inner join funcionarios f
        on  a.funcionario_id  = f.funcionario_id
        and a.sistema_origem  = f.sistema_origem
    inner join datas d
        on  a.data_apontamento = d.data_completa

)

select
    -- Chave surrogate da linha da fato
    {{ dbt_utils.generate_surrogate_key(['sk_funcionario', 'sk_data']) }}
                                                            as sk_fato_ponto,
    sk_funcionario,
    sk_empresa,
    sk_data,
    data_apontamento,
    horas_trabalhadas,
    jornada_contratada_horas,
    horas_extras,
    -- Saldo do dia (negativo = falta, positivo = banco de horas)
    round((horas_trabalhadas - jornada_contratada_horas)::numeric, 2)
                                                            as saldo_horas_dia,
    num_pares_batida,
    flag_atraso,
    primeira_entrada,
    ultima_saida

from joined
