-- =============================================================================
-- models/staging/stg_motoristas__apontamentos.sql (PASSO 2g)
-- =============================================================================
-- Objetivo: Padronizar os apontamentos de ponto dos motoristas.
--
-- Idêntico ao stg_admin__apontamentos, mas com sistema_origem = 'motoristas'.
-- Essa simetria é intencional: facilita o UNION ALL na camada intermediate.
-- =============================================================================

with source as (

    select * from "db_dw"."raw_motoristas"."apontamento"

),

renamed as (

    select
        id                              as apontamento_id,
        funcionario_id,
        data_hora::timestamp            as data_hora,
        data_hora::date                 as data_apontamento,
        extract(hour from data_hora)    as hora_apontamento,
        tipo,
        'motoristas'                    as sistema_origem

    from source

)

select * from renamed