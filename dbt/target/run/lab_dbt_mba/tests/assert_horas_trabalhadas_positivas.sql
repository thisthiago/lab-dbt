
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- =============================================================================
-- tests/assert_horas_trabalhadas_positivas.sql (PASSO 6a)
-- =============================================================================
-- TESTE SINGULAR: Garante que não há registros com horas negativas ou zeradas
--
-- Por que esse teste importa?
--   Um registro com horas_trabalhadas <= 0 indica:
--     - Bug no pareamento de batidas (saída antes da entrada)
--     - Dado corrompido na fonte
--     - Erro na lógica do modelo int_apontamentos_diarios
--
-- Como funciona um teste singular no dbt?
--   O dbt executa a query e espera que ela retorne 0 linhas.
--   Se retornar qualquer linha, o teste FALHA.
--
-- Executar: dbt test --select assert_horas_trabalhadas_positivas
-- =============================================================================

select
    sk_fato_ponto,
    sk_funcionario,
    data_apontamento,
    horas_trabalhadas

from "db_dw"."marts"."fato_ponto"

where horas_trabalhadas <= 0

-- Se esta query retornar QUALQUER linha, o teste falha.
-- Esperado: 0 linhas (todas as horas trabalhadas devem ser > 0)
  
  
      
    ) dbt_internal_test