# =============================================================================
# macros/generate_schema_name.sql — Customização do schema dbt
# =============================================================================
# Por padrão, o dbt concatena o schema do profile com o +schema do modelo,
# gerando nomes como "public_staging". Esta macro substitui esse comportamento
# para usar apenas o schema customizado (ex: "staging", "marts", "analytics").
#
# Documentação: https://docs.getdbt.com/docs/build/custom-schemas
# =============================================================================

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {# Se não tem schema customizado, usa o schema padrão do profile #}
        {{ default_schema }}
    {%- else -%}
        {# Usa o schema customizado diretamente (sem concatenar com o default) #}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
