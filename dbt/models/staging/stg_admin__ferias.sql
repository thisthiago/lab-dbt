-- =============================================================================
-- models/staging/stg_admin__ferias.sql (PASSO 2d)
-- =============================================================================
-- Objetivo: Padronizar os períodos de férias do sistema administrativo.
--
-- Transformações:
--   - Cálculo de dias_ferias (data_fim - data_inicio)
--   - Adição de sistema_origem
-- =============================================================================

with source as (

    select * from {{ source('admin', 'ferias') }}

),

renamed as (

    select
        id                              as ferias_id,
        funcionario_id,
        data_inicio,
        data_fim,
        (data_fim - data_inicio)        as dias_ferias,  -- duração em dias
        'admin'                         as sistema_origem

    from source

)

select * from renamed
