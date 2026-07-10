
  create view "db_dw"."analytics"."vw_funcionarios_anonimizados__dbt_tmp"
    
    
  as (
    -- =============================================================================
-- models/analytics/vw_funcionarios_anonimizados.sql
-- =============================================================================

with funcionarios as (

    select * from "db_dw"."marts"."dim_funcionario"

)

select
    f.sk_funcionario,

    
    regexp_replace(
        initcap(f.nome),
        '(\S)\S+(\s|$)',
        '\1***\2',
        'g'
    )
 as nome_anonimizado,
    
    encode(sha256(f.cpf::bytea), 'hex')
 as cpf_hash_sha256,

    f.faixa_salarial,
    f.tempo_empresa_meses,

    f.cargo,
    f.departamento,
    f.status,
    f.sistema_origem

from funcionarios f
  );