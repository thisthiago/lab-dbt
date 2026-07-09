-- =============================================================================
-- models/staging/stg_admin__ajustes.sql (PASSO 2e)
-- =============================================================================
-- Objetivo: Padronizar as solicitações de ajuste de ponto do sistema admin.
--
-- Contexto de negócio:
--   Solicitação de ajuste ocorre quando o funcionário esquece de bater ponto
--   ou quando há falha no sistema. O supervisor aprova ou reprova.
-- =============================================================================

with source as (

    select * from {{ source('admin', 'solicitacao_ajuste') }}

),

renamed as (

    select
        id                  as ajuste_id,
        funcionario_id,
        data_solicitacao,
        data_hora_ajuste,
        motivo,             -- 'Esquecimento', 'Problema no sistema', 'Trabalho externo'
        status,             -- 'Pendente', 'Aprovado', 'Reprovado'
        'admin'             as sistema_origem

    from source

)

select * from renamed
