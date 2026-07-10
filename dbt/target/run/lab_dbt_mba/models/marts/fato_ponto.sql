
  
    

  create  table "db_dw"."marts"."fato_ponto__dbt_tmp"
  
  
    as
  
  (
    -- =============================================================================
-- models/marts/fato_ponto.sql
-- =============================================================================

with  __dbt__cte__int_apontamentos_diarios as (
-- =============================================================================
-- models/intermediate/int_apontamentos_diarios.sql (PASSO 3b)
-- =============================================================================
-- Objetivo: Transformar os apontamentos brutos (registros de entrada/saída)
--           em uma visão diária por funcionário, calculando as horas trabalhadas.
--
-- Lógica de pareamento de batidas (Usando Window Functions):
--   1. Ordenamos todos os batidas de cada funcionário cronologicamente.
--   2. Usamos a função LEAD() para pegar a próxima batida (que deve ser a Saída).
--   3. Calculamos a diferença de horas entre a Entrada e a Saída.
--   4. Somamos tudo no nível do dia.
--
-- Esta lógica é superior pois lida perfeitamente com Turnos da Noite (onde
-- a Entrada é num dia e a Saída no outro), evitando cálculos de horas negativas.
-- =============================================================================

with admin_apontamentos as (
    select * from "db_dw"."staging"."stg_admin__apontamentos"
),

motoristas_apontamentos as (
    select * from "db_dw"."staging"."stg_motoristas__apontamentos"
),

-- Unifica todos os apontamentos dos dois sistemas
todos as (
    select * from admin_apontamentos
    union all
    select * from motoristas_apontamentos
),

-- Usa a função LEAD para olhar a próxima linha do mesmo funcionário
sessoes as (
    select
        funcionario_id,
        sistema_origem,
        data_apontamento,
        tipo,
        data_hora as hora_entrada,
        lead(data_hora) over (
            partition by funcionario_id, sistema_origem 
            order by data_hora
        ) as hora_saida,
        lead(tipo) over (
            partition by funcionario_id, sistema_origem 
            order by data_hora
        ) as proximo_tipo
    from todos
),

-- Filtramos apenas as linhas de 'Entrada' que têm uma 'Saída' logo em seguida
pares as (
    select
        funcionario_id,
        sistema_origem,
        data_apontamento, -- A data considerada é a data da Entrada (ex: para turno da noite)
        hora_entrada,
        hora_saida,
        extract(epoch from (hora_saida - hora_entrada)) / 3600.0 as horas_periodo
    from sessoes
    where tipo = 'Entrada'
      and proximo_tipo = 'Saída'
      and hora_saida is not null
      and extract(epoch from (hora_saida - hora_entrada)) > 60 -- Ignora batidas duplas acidentais (menos de 1 minuto)
),

-- Agrega os pares do dia em um único registro diário
diario as (
    select
        funcionario_id,
        sistema_origem,
        data_apontamento,
        min(hora_entrada)                           as primeira_entrada,
        max(hora_saida)                             as ultima_saida,
        round(sum(horas_periodo)::numeric, 2)       as horas_trabalhadas,
        count(*)                                    as num_pares_batida
    from pares
    group by funcionario_id, sistema_origem, data_apontamento
)

select * from diario
), apontamentos as (

    select * from __dbt__cte__int_apontamentos_diarios

),

funcionarios as (

    select
        sk_funcionario,
        funcionario_id,
        sistema_origem,
        categoria
    from "db_dw"."marts"."dim_funcionario"

),

datas as (

    select sk_data, data_completa
    from "db_dw"."marts"."dim_data"

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
    md5(cast(coalesce(cast(sk_funcionario as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sk_data as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as sk_fato_ponto,
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
  );
  