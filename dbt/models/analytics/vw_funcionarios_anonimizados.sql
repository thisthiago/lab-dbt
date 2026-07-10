-- =============================================================================
-- models/analytics/vw_funcionarios_anonimizados.sql
-- =============================================================================

with funcionarios as (

    select * from {{ ref('dim_funcionario') }}

)

select
    f.sk_funcionario,

    {{ anonimizar_nome('f.nome') }} as nome_anonimizado,
    {{ hash_pii('f.cpf') }} as cpf_hash_sha256,

    f.faixa_salarial,
    f.tempo_empresa_meses,

    f.cargo,
    f.departamento,
    f.status,
    f.sistema_origem

from funcionarios f
