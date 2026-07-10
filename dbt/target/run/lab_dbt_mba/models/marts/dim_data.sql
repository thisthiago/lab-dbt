
  
    

  create  table "db_dw"."marts"."dim_data__dbt_tmp"
  
  
    as
  
  (
    -- =============================================================================
-- models/marts/dim_data.sql (PASSO 4c)
-- =============================================================================
-- DIMENSÃO: Data (Calendário)
-- Granularidade: 1 linha por dia (2018-01-01 a 2027-12-31)
--
-- Esta dimensão é gerada PELO dbt, sem fonte OLTP.
-- Usa generate_series do PostgreSQL para criar uma sequência de datas.
--
-- Padrão comum em DW: a dim_data é criada uma única vez e raramente atualizada.
-- sk_data = inteiro no formato YYYYMMDD (ex: 20240115) — chave natural de datas
-- =============================================================================

with date_spine as (

    -- Gera uma linha para cada dia no intervalo
    select
        generate_series::date as data_completa
    from generate_series(
        '2018-01-01'::date,
        '2027-12-31'::date,
        '1 day'::interval
    )

)

select
    -- sk_data: YYYYMMDD como inteiro — padrão universal em DW
    to_char(data_completa, 'YYYYMMDD')::int         as sk_data,

    -- Data completa
    data_completa,

    -- Hierarquia temporal
    extract(year    from data_completa)::int         as ano,
    extract(quarter from data_completa)::int         as trimestre,
    extract(month   from data_completa)::int         as mes,
    to_char(data_completa, 'TMMonth')                as mes_nome,        -- Jan, Fev, ...
    to_char(data_completa, 'MM/YYYY')                as mes_ano_label,
    to_char(data_completa, 'YYYY-MM')                as ano_mes,         -- '2024-01' (útil para GROUP BY)
    extract(week    from data_completa)::int         as semana_ano,      -- ISO week number
    extract(day     from data_completa)::int         as dia,

    -- Dia da semana (0=Dom, 1=Seg, ..., 6=Sáb no PostgreSQL extract)
    extract(dow from data_completa)::int             as dia_semana_num,
    to_char(data_completa, 'TMDay')                  as dia_semana_nome, -- Segunda, Terça, ...

    -- Flags úteis
    case
        when extract(dow from data_completa) in (0, 6)
        then true else false
    end                                              as flag_fim_de_semana,

    case
        when extract(dow from data_completa) not in (0, 6)
        then true else false
    end                                              as flag_dia_util,

    -- Semestre
    case
        when extract(month from data_completa) <= 6 then 1 else 2
    end                                              as semestre

from date_spine
  );
  