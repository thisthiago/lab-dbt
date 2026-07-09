-- =============================================================================
-- models/staging/stg_motoristas__ferias.sql (PASSO 2h)
-- =============================================================================
-- Objetivo: Padronizar as férias dos motoristas.
-- =============================================================================

with source as (

    select * from {{ source('motoristas', 'ferias') }}

),

renamed as (

    select
        id                          as ferias_id,
        funcionario_id,
        data_inicio,
        data_fim,
        (data_fim - data_inicio)    as dias_ferias,
        'motoristas'                as sistema_origem

    from source

)

select * from renamed
