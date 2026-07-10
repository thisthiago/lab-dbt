# 📦 Projeto dbt — Lab MBA: Modelagem Dimensional

> **Guia didático SIMPLIFICADO** para aprender modelagem dimensional e dbt na prática,
> usando um sistema de Ponto Eletrônico como caso real em uma aula de 1 hora.

---

## 🏗️ Arquitetura do Projeto

```
┌──────────────────────────────────────────────┐
│           SISTEMAS TRANSACIONAIS (OLTP)       │
│  postgres-sistemas (porta 5454)               │
│  ┌──────────────┐    ┌─────────────────────┐  │
│  │   db_admin   │    │   db_motoristas     │  │
│  └──────────────┘    └─────────────────────┘  │
└──────────────────────────────────────────────┘
                         │
               [Script Python (Pandas) — EL]
                         │
┌──────────────────────────────────────────────┐
│              DATA WAREHOUSE (OLAP)            │
│           postgres-dw (porta 5455)            │
│                   db_dw                       │
│                                               │
│  raw_admin.*       raw_motoristas.*           │
│  (foreign tables)  (foreign tables)           │
│         │                 │                   │
│         └──── dbt run ────┘                   │
│                    │                          │
│         ┌──────────▼──────────┐               │
│         │   staging.*  (VIEW) │               │
│         └──────────┬──────────┘               │
│                    │ ephemeral CTEs            │
│         ┌──────────▼──────────┐               │
│         │   marts.*  (TABLE)  │               │
│         │  dim_funcionario    │               │
│         │  dim_data           │               │
│         │  fato_ponto         │               │
│         └──────────┬──────────┘               │
│                    │                          │
│         ┌──────────▼──────────┐               │
│         │  analytics.* (VIEW) │               │
│         │  3 visões de RH     │               │
│         └─────────────────────┘               │
└──────────────────────────────────────────────┘
```

---

## 📂 Estrutura de Arquivos (Caminho Feliz)

```
dbt/
├── dbt_project.yml, profiles.yml, packages.yml, load_dw.py
├── models/
│   ├── sources/_sources.yml
│   ├── staging/ (4 sqls básicos)
│   ├── intermediate/ (int_funcionarios_unificados, int_apontamentos_diarios)
│   ├── marts/ (dim_funcionario, dim_data, fato_ponto)
│   └── analytics/ (horas_mensais, absenteismo_departamento, vw_funcionarios_anonimizados)
├── macros/ (generate_schema_name, pii_macros)
└── tests/ (2 testes singulares)
```

## 🚀 Como Executar

```bash
# Instalar dependências do dbt e do script Python
pip install pandas sqlalchemy psycopg2-binary
dbt deps

# Executar a carga bruta (Extrai do OLTP, joga no DW)
python load_dw.py

# Rodar os modelos do dbt (Transformação)
dbt build

# Ver a documentação no navegador
dbt docs generate && dbt docs serve
```
