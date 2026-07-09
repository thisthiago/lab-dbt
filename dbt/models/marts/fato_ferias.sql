-- =============================================================================
-- models/marts/fato_ferias.sql (PASSO 4e)
-- =============================================================================
-- FATO: Férias
-- Granularidade: 1 linha por período de férias por funcionário
-- Tipo: Fato acumulado (snapshot de evento)
--
-- Métricas disponíveis:
--   - dias_ferias: duração total do período de férias
--
-- Chaves estrangeiras:
--   - sk_funcionario  → dim_funcionario
--   - sk_empresa      → dim_empresa
--   - sk_data_inicio  → dim_data (data de início das férias)
--   - sk_data_fim     → dim_data (data de término das férias)
-- =============================================================================

with admin_ferias as (

    select * from {{ ref('stg_admin__ferias') }}

),

motoristas_ferias as (

    select * from {{ ref('stg_motoristas__ferias') }}

),

todas_ferias as (

    select * from admin_ferias
    union all
    select * from motoristas_ferias

),

funcionarios as (

    select sk_funcionario, funcionario_id, sistema_origem, sk_empresa
    from {{ ref('dim_funcionario') }}

),

-- Precisamos do sk_data para INÍCIO e FIM das férias
-- Fazemos dois joins com dim_data usando aliases diferentes
dim_data_inicio as (

    select sk_data, data_completa
    from {{ ref('dim_data') }}

),

dim_data_fim as (

    select sk_data, data_completa
    from {{ ref('dim_data') }}

)

select
    -- Chave surrogate: hash de ferias_id + sistema_origem
    {{ dbt_utils.generate_surrogate_key(['f.ferias_id', 'f.sistema_origem']) }}
                                    as sk_fato_ferias,

    -- Chaves das dimensões
    func.sk_funcionario,
    func.sk_empresa,
    di.sk_data                      as sk_data_inicio,
    df.sk_data                      as sk_data_fim,

    -- Datas (desnormalizadas para facilitar filtros)
    f.data_inicio,
    f.data_fim,

    -- Métricas
    f.dias_ferias

from todas_ferias f
inner join funcionarios func
    on  f.funcionario_id  = func.funcionario_id
    and f.sistema_origem  = func.sistema_origem
inner join dim_data_inicio di
    on  f.data_inicio     = di.data_completa
inner join dim_data_fim df
    on  f.data_fim        = df.data_completa
