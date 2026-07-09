-- =============================================================================
-- models/staging/stg_admin__empresas.sql (PASSO 2a)
-- =============================================================================
-- Objetivo: Padronizar e renomear colunas da tabela 'empresa' do sistema admin.
--
-- Padrões de nomenclatura staging:
--   - Prefixo "stg_": indica camada staging
--   - "admin__": indica o sistema de origem
--   - Colunas renomeadas para snake_case consistente
--   - ID renomeado para "{entidade}_id" (clareza de qual entidade é)
--   - Sem lógica de negócio — apenas limpeza estrutural
-- =============================================================================

with source as (

    -- {{ source() }} referencia a tabela declarada em _sources.yml
    -- Permite rastrear a linhagem no dbt docs
    select * from {{ source('admin', 'empresa') }}

),

renamed as (

    select
        id           as empresa_id,
        cnpj,
        razao_social,
        endereco

    from source

)

select * from renamed
