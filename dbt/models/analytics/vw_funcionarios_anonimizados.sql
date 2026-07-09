-- =============================================================================
-- models/analytics/vw_funcionarios_anonimizados.sql (PASSO 5l)
-- =============================================================================
-- VISÃO ANALÍTICA: Funcionários com Dados Anonimizados (LGPD)
--
-- CONTEXTO LGPD (Lei 13.709/2018):
--   Art. 5º, II: "dado pessoal sensível" inclui CPF, nome completo e salário.
--   Art. 12: "dado anonimizado" não é pessoal — pode ser tratado livremente.
--   Art. 46: necessidade de proteção técnica dos dados pessoais.
--
-- OBJETIVO DIDÁTICO:
--   Demonstrar como o dbt pode ser usado para criar uma visão de acesso
--   seguro a dados de funcionários, onde analistas externos podem trabalhar
--   sem ter acesso às informações pessoais identificáveis (PII).
--
-- TÉCNICAS APLICADAS:
--   1. hash_pii(cpf)        → SHA-256 irreversível (não dá para recuperar o CPF)
--   2. anonimizar_nome()    → Mantém apenas a inicial de cada palavra
--   3. Salário → faixa_salarial (categórica, não o valor exato)
--   4. data_nascimento → apenas a faixa etária (não a data exata)
--   5. Removido: nome completo, CPF exato, salário exato, data_nascimento exata
--
-- CAMPOS MANTIDOS SEM ANONIMIZAÇÃO:
--   Dados operacionais não identificáveis: cargo, departamento, status, tempo de empresa
-- =============================================================================

with funcionarios as (

    select * from {{ ref('dim_funcionario') }}

),

empresas as (

    select sk_empresa, razao_social
    from {{ ref('dim_empresa') }}

)

select
    -- Identificador interno (não pessoal — é um hash interno do DW)
    f.sk_funcionario,

    -- ✅ Dados ANONIMIZADOS (técnica: máscara de texto)
    -- Nome: "João Silva Santos" → "J*** S*** S***"
    {{ anonimizar_nome('f.nome') }}                 as nome_anonimizado,

    -- CPF: aplicação de SHA-256 (não reversível)
    {{ hash_pii('f.cpf') }}                         as cpf_hash_sha256,

    -- Faixa etária (em vez da data de nascimento exata)
    f.faixa_etaria,

    -- ✅ Dados CATEGÓRICOS (não identificam o indivíduo)
    f.faixa_salarial,           -- ex: "B — R$3.001 a R$6.000"
    f.faixa_antiguidade,        -- ex: "1-3 anos"
    f.tempo_empresa_meses,      -- número de meses (sem data exata)

    -- ✅ Dados OPERACIONAIS (necessários para análises de RH)
    f.cargo,
    f.departamento,
    f.setor,
    f.categoria,
    f.status,
    f.sistema_origem,
    e.razao_social              as empresa,

    -- Datas de admissão/demissão: mantidas para análises de turnover
    -- Em casos mais restritivos, substituir por trimestre/ano
    date_trunc('month', f.data_admissao)::date      as mes_admissao,
    date_trunc('month', f.data_demissao)::date      as mes_demissao

from funcionarios f
inner join empresas e on f.sk_empresa = e.sk_empresa
