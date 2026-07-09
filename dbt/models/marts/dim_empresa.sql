-- =============================================================================
-- models/marts/dim_empresa.sql (PASSO 4a)
-- =============================================================================
-- DIMENSÃO: Empresa
-- Granularidade: 1 linha por empresa (3 empresas no total)
-- Fonte: stg_admin__empresas (as empresas são idênticas nos dois sistemas)
--
-- Por que usar o admin como fonte única?
--   Ambos os sistemas compartilham as mesmas 3 empresas com os mesmos IDs.
--   Usar apenas um sistema como master evita duplicidade.
--
-- sk_empresa = empresa_id original (IDs 1, 2, 3 — simples e consistente)
-- =============================================================================

with empresas as (

    select * from {{ ref('stg_admin__empresas') }}

)

select
    -- Chave surrogate: usamos o próprio ID da fonte pois é estável e único
    empresa_id                  as sk_empresa,
    empresa_id,
    cnpj,
    razao_social,
    -- Extrai UF do endereço (últimos 2 caracteres do CEP pattern)
    -- Simplificação didática: em produção, usar tabela de endereços estruturada
    endereco

from empresas
