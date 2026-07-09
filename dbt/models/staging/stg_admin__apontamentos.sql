-- =============================================================================
-- models/staging/stg_admin__apontamentos.sql (PASSO 2c)
-- =============================================================================
-- Objetivo: Padronizar os registros de ponto do sistema administrativo.
--
-- Transformações:
--   - Extração de data e hora separados do timestamp
--   - Cast explícito para garantir tipos corretos
--   - Adição de sistema_origem para rastreabilidade
--
-- Atenção: Esta tabela pode ter MUITOS registros (~1M+ linhas).
--          Por isso, esta staging é materializada como VIEW (não TABLE).
-- =============================================================================

with source as (

    select * from {{ source('admin', 'apontamento') }}

),

renamed as (

    select
        id                              as apontamento_id,
        funcionario_id,
        data_hora::timestamp            as data_hora,
        data_hora::date                 as data_apontamento,    -- data isolada (para joins com dim_data)
        extract(hour from data_hora)    as hora_apontamento,    -- hora isolada (para análises de atraso)
        tipo,                                                   -- 'Entrada' ou 'Saída'
        'admin'                         as sistema_origem

    from source

)

select * from renamed
