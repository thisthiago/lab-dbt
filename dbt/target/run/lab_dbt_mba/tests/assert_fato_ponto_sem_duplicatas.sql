
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- =============================================================================
-- tests/assert_fato_ponto_sem_duplicatas.sql (PASSO 6b)
-- =============================================================================
-- TESTE SINGULAR: Garante unicidade de (funcionário × dia) na fato_ponto
--
-- Por que esse teste importa?
--   A granularidade da fato_ponto é "1 linha por funcionário por dia".
--   Se um funcionário aparece DUAS vezes no mesmo dia, significa:
--     - Erro na lógica de agregação do modelo
--     - Problema no pareamento de batidas (criou dois grupos para o mesmo dia)
--
-- Esse teste é REDUNDANTE com o teste unique em sk_fato_ponto (_marts.yml),
-- mas é mantido aqui como exemplo didático de TESTE SINGULAR customizado —
-- que verifica a combinação natural das chaves antes do hash.
--
-- Executar: dbt test --select assert_fato_ponto_sem_duplicatas
-- =============================================================================

select
    sk_funcionario,
    sk_data,
    count(*)    as ocorrencias

from "db_dw"."marts"."fato_ponto"

group by sk_funcionario, sk_data

having count(*) > 1

-- Se esta query retornar QUALQUER linha, o teste falha.
-- Esperado: 0 linhas (cada combinação funcionário+dia deve ser única)
  
  
      
    ) dbt_internal_test