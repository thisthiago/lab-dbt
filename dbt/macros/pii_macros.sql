# =============================================================================
# macros/pii_macros.sql — Macros para tratamento de dados sensíveis (LGPD)
# =============================================================================
# Conjunto de macros para anonimização e hashing de dados pessoais.
# Usadas na view vw_funcionarios_anonimizados para demonstrar compliance LGPD.
#
# Macros disponíveis:
#   - hash_pii(campo)        → SHA-256 do valor (não reversível)
#   - anonimizar_cpf(campo)  → Mascara os primeiros 9 dígitos do CPF
#   - anonimizar_nome(campo) → Mantém apenas a primeira letra de cada palavra
# =============================================================================

{# =========================================================== #}
{# hash_pii: Aplica SHA-256 em um campo sensível               #}
{# Resultado: string hexadecimal de 64 caracteres              #}
{# Uso: {{ hash_pii('cpf') }}                                   #}
{# =========================================================== #}
{% macro hash_pii(campo) %}
    encode(sha256({{ campo }}::bytea), 'hex')
{% endmacro %}


{# =========================================================== #}
{# anonimizar_cpf: Mascara os 9 primeiros dígitos do CPF       #}
{# Exemplo: 123.456.789-00 → ***.***.***-00                    #}
{# Uso: {{ anonimizar_cpf('cpf') }}                             #}
{# =========================================================== #}
{% macro anonimizar_cpf(campo) %}
    regexp_replace({{ campo }}, '\d{3}\.\d{3}\.\d{3}', '***.***.**')
{% endmacro %}


{# =========================================================== #}
{# anonimizar_nome: Mantém apenas a 1ª letra de cada palavra   #}
{# Exemplo: "João Silva Santos" → "J*** S*** S***"             #}
{# Uso: {{ anonimizar_nome('nome') }}                           #}
{# =========================================================== #}
{% macro anonimizar_nome(campo) %}
    regexp_replace(
        initcap({{ campo }}),
        '(\S)\S+(\s|$)',
        '\1***\2',
        'g'
    )
{% endmacro %}
