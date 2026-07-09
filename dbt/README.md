# 📦 Projeto dbt — Lab MBA: Modelagem Dimensional

> **Guia didático** para aprender modelagem dimensional e dbt na prática,
> usando um sistema de Ponto Eletrônico como caso real.

---

## 📚 O que é o dbt?

**dbt (data build tool)** é uma ferramenta de transformação de dados que funciona
dentro do seu Data Warehouse. Com dbt você:

- Escreve transformações em **SQL puro** (nada de Python ou Spark)
- Organiza os modelos em **camadas** (staging → marts → analytics)
- Testa a **qualidade dos dados** automaticamente
- Gera **documentação** do catálogo de dados com um comando
- Controla a **linhagem** (qual tabela originou qual)

> 💡 dbt não move dados — ele **transforma** dados que já estão no banco.
> Você escreve SQL, ele cuida do `CREATE`, `DROP`, `INSERT`.

---

## 🏗️ Arquitetura do Projeto

```
┌──────────────────────────────────────────────┐
│           SISTEMAS TRANSACIONAIS (OLTP)       │
│  postgres-sistemas (porta 5454)               │
│  ┌──────────────┐    ┌─────────────────────┐  │
│  │   db_admin   │    │   db_motoristas     │  │
│  │ (funcionários│    │   (motoristas da    │  │
│  │  adm/estag.) │    │    logística)       │  │
│  └──────────────┘    └─────────────────────┘  │
└──────────────────────────────────────────────┘
                         │
               [postgres_fdw — FDW]
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
│         │  dim_empresa        │               │
│         │  dim_funcionario    │               │
│         │  dim_data           │               │
│         │  fato_ponto         │               │
│         │  fato_ferias        │               │
│         └──────────┬──────────┘               │
│                    │                          │
│         ┌──────────▼──────────┐               │
│         │  analytics.* (VIEW) │               │
│         │  11 visões de RH    │               │
│         └─────────────────────┘               │
└──────────────────────────────────────────────┘
```

---

## 📂 Estrutura de Arquivos (Ordem de Implementação)

```
dbt/
│
│  # ── CONFIGURAÇÃO (implementar primeiro)
├── dbt_project.yml      ← Config principal: nome, schemas, materializações
├── profiles.yml         ← Conexão com o banco (user, host, port, dbname)
├── packages.yml         ← Dependências externas (dbt-utils)
├── setup_fdw.sql        ← Script SQL para configurar o FDW (rodar UMA VEZ)
│
│  # ── MACROS (funções reutilizáveis SQL)
├── macros/
│   ├── generate_schema_name.sql  ← Customiza nomes de schema (sem prefixo)
│   └── pii_macros.sql            ← hash_pii, anonimizar_cpf, anonimizar_nome
│
│  # ── MODELS (a essência do dbt)
├── models/
│   │
│   │  # PASSO 1: Declarar fontes
│   ├── sources/
│   │   └── _sources.yml          ← Registra tabelas OLTP no catálogo
│   │
│   │  # PASSO 2: Staging (limpeza e renomeação)
│   ├── staging/
│   │   ├── _staging.yml          ← Docs e testes da staging
│   │   ├── stg_admin__empresas.sql
│   │   ├── stg_admin__funcionarios.sql
│   │   ├── stg_admin__apontamentos.sql
│   │   ├── stg_admin__ferias.sql
│   │   ├── stg_admin__ajustes.sql
│   │   ├── stg_motoristas__funcionarios.sql
│   │   ├── stg_motoristas__apontamentos.sql
│   │   └── stg_motoristas__ferias.sql
│   │
│   │  # PASSO 3: Intermediate (transformações complexas)
│   ├── intermediate/
│   │   ├── _intermediate.yml
│   │   ├── int_funcionarios_unificados.sql  ← UNION admin + motoristas
│   │   └── int_apontamentos_diarios.sql     ← Parea entrada/saída → horas/dia
│   │
│   │  # PASSO 4: Marts — o Data Warehouse propriamente dito
│   ├── marts/
│   │   ├── _marts.yml
│   │   ├── dim_empresa.sql       ← Dimensão de empresas
│   │   ├── dim_funcionario.sql   ← Dimensão de funcionários (enriquecida)
│   │   ├── dim_data.sql          ← Dimensão de tempo (gerada pelo dbt)
│   │   ├── fato_ponto.sql        ← Fato: ponto diário por funcionário
│   │   └── fato_ferias.sql       ← Fato: períodos de férias
│   │
│   │  # PASSO 5: Analytics — visões prontas para o analista de RH
│   └── analytics/
│       ├── _analytics.yml
│       ├── analytic_horas_mensais.sql
│       ├── analytic_banco_horas.sql
│       ├── analytic_atrasos_por_funcionario.sql
│       ├── analytic_absenteismo_departamento.sql
│       ├── analytic_ferias_vencidas.sql
│       ├── analytic_ajustes_ponto_ranking.sql
│       ├── analytic_headcount_mensal.sql
│       ├── analytic_turnover_mensal.sql
│       ├── analytic_antiguidade_funcionarios.sql
│       ├── analytic_custo_hora_departamento.sql
│       ├── analytic_distribuicao_salarial.sql
│       └── vw_funcionarios_anonimizados.sql
│
│  # PASSO 6: Testes singulares
├── tests/
│   ├── assert_horas_trabalhadas_positivas.sql
│   └── assert_fato_ponto_sem_duplicatas.sql
│
│  # Documentação da página inicial do catálogo
└── docs/
    └── overview.md
```

---

## 🚀 Como Configurar e Executar

### Pré-requisitos

```bash
# Python 3.8+
pip install dbt-postgres

# Verifique a instalação
dbt --version
```

### Passo 1 — Subir os containers Docker

```bash
# Na raiz do projeto (onde está o docker-compose.yml)
docker-compose up -d

# Aguarde o data-generator terminar (pode levar alguns minutos)
docker logs data-generator --follow
```

### Passo 2 — Configurar o FDW (UMA ÚNICA VEZ)

O FDW permite que `db_dw` leia dados de `db_admin` e `db_motoristas`:

```bash
# Navegue até a pasta dbt
cd dbt

# Execute o script de configuração do FDW
psql -h localhost -p 5455 -U postgres -d db_dw -f setup_fdw.sql
```

> ⚠️ **Importante**: O script FDW só precisa ser executado uma vez.
> Se recriar o container `postgres-dw`, execute novamente.

### Passo 3 — Instalar dependências dbt

```bash
# Dentro da pasta dbt/
dbt deps
```

### Passo 4 — Validar conexão

```bash
dbt debug
```

Saída esperada: `All checks passed!`

### Passo 5 — Executar os modelos

```bash
# Executa TODOS os modelos na ordem correta (respeitando dependências)
dbt run

# Executar apenas uma camada específica
dbt run --select staging
dbt run --select marts
dbt run --select analytics

# Executar um modelo específico
dbt run --select dim_funcionario

# Executar um modelo e todos que dependem dele
dbt run --select fato_ponto+

# Executar um modelo e todas as suas dependências upstream
dbt run --select +fato_ponto
```

### Passo 6 — Executar os testes

```bash
# Todos os testes (schema tests + singular tests)
dbt test

# Testes de uma camada específica
dbt test --select staging
dbt test --select marts

# Apenas os testes singulares customizados
dbt test --select test_type:singular

# Ver detalhes de um teste que falhou
dbt test --select assert_horas_trabalhadas_positivas
```

### Passo 7 — Gerar e visualizar a documentação

```bash
# Gera o catálogo de dados (cria arquivos em target/)
dbt docs generate

# Abre um servidor web com a documentação
dbt docs serve
# → Acesse: http://localhost:8080
```

> A documentação inclui:
> - **Catálogo**: descrição de todos os modelos e colunas
> - **Lineage Graph**: grafo de dependências visual (clique em "Lineage" no menu)
> - **Testes**: status de todos os testes

---

## 📖 Explicação de Cada Arquivo

### `dbt_project.yml`
Arquivo de configuração principal. Define:
- **name**: nome do projeto (usado em refs e logs)
- **profile**: qual profile do `profiles.yml` usar
- **model-paths**: onde o dbt busca os modelos SQL
- **+materialized**: como cada camada é materializada (view, table, ephemeral)
- **+schema**: em qual schema do banco cada camada será criada

### `profiles.yml`
Configuração de conexão com o banco de dados. Contém:
- **type**: dialeto SQL (postgres, bigquery, snowflake, etc.)
- **host / port / dbname**: onde está o banco
- **threads**: quantos modelos rodar em paralelo

> ⚠️ Em produção, use variáveis de ambiente no lugar de credenciais hardcoded.

### `packages.yml`
Dependências de pacotes dbt. O projeto usa:
- **dbt_utils**: macros como `generate_surrogate_key` e `date_spine`

### `setup_fdw.sql`
Script SQL (não é modelo dbt) que configura o PostgreSQL Foreign Data Wrapper.
Cria "espelhos" das tabelas de `db_admin` e `db_motoristas` dentro de `db_dw`.

### `_sources.yml`
Declara as fontes de dados no catálogo do dbt. Permite:
- Usar `{{ source('admin', 'funcionario') }}` nos modelos
- Rodar testes nas tabelas de origem
- Ver a linhagem a partir da fonte

### Modelos `stg_*.sql`
Camada de **staging**: limpeza mínima dos dados brutos.
- Renomeia colunas para snake_case consistente
- Adiciona `sistema_origem` para rastrear de qual banco veio
- Sem lógica de negócio — apenas estrutura

### Modelos `int_*.sql`
Camada **intermediate**: transformações complexas reutilizáveis.
- `int_funcionarios_unificados`: UNION ALL de admin + motoristas com surrogate key
- `int_apontamentos_diarios`: pareia batidas e calcula horas/dia
- Materializado como **ephemeral** (CTE inline, sem tabela no banco)

### Modelos `dim_*.sql` e `fato_*.sql`
Camada **marts**: o Data Warehouse propriamente dito.
- **Dimensões**: entidades descritivas (quem, o quê, quando, onde)
- **Fatos**: eventos mensuráveis (o ponto batido, as férias tiradas)
- Materializados como **table** (performance para BI)

### Modelos `analytic_*.sql` e `vw_*.sql`
Camada **analytics**: visões prontas para o analista de RH.
- Construídas sobre as tabelas do `marts`
- Materializadas como **view** (sempre refletem os dados atuais)

---

## 🧪 Tipos de Testes no dbt

### Schema Tests (definidos em `.yml`)
```yaml
columns:
  - name: funcionario_id
    tests:
      - unique        # sem duplicatas
      - not_null      # sem nulos
  - name: status
    tests:
      - accepted_values:
          values: ['Ativo', 'Demitido']
  - name: sk_empresa
    tests:
      - relationships:
          to: ref('dim_empresa')
          field: sk_empresa
```

### Singular Tests (arquivos `.sql` em `tests/`)
```sql
-- O teste FALHA se a query retornar qualquer linha
select * from {{ ref('fato_ponto') }}
where horas_trabalhadas <= 0
```

---

## 🔐 Anonimização de Dados (LGPD)

O projeto inclui macros para tratamento de dados sensíveis:

```sql
-- Hash SHA-256 (não reversível)
{{ hash_pii('cpf') }}
-- Resultado: 'a3f5c9...' (64 caracteres hex)

-- Máscara de nome
{{ anonimizar_nome('nome') }}
-- 'João Silva Santos' → 'J*** S*** S***'

-- Máscara de CPF
{{ anonimizar_cpf('cpf') }}
-- '123.456.789-00' → '***.***.***-00'
```

A view `vw_funcionarios_anonimizados` aplica todas essas técnicas,
permitindo que analistas externos trabalhem com dados de RH sem
ver informações pessoais identificáveis.

---

## 🔍 Comandos Úteis

```bash
# Compilar SQL sem executar (ver o SQL gerado)
dbt compile --select fato_ponto

# Ver o SQL compilado de um modelo
cat target/compiled/lab_dbt_mba/models/marts/fato_ponto.sql

# Limpar arquivos gerados
dbt clean

# Listar todos os modelos e seus tipos
dbt ls

# Listar apenas os modelos de uma camada
dbt ls --select staging

# Executar run + test juntos
dbt build

# Executar apenas modelos modificados (comparando com estado anterior)
dbt run --select state:modified

# Analisar a linhagem de um modelo
dbt ls --select +fato_ponto+   # upstream e downstream
```

---

## 📊 Visões Analíticas para o Analista de RH

| Visão | Problema que Resolve | Insight Principal |
|-------|---------------------|-------------------|
| `analytic_horas_mensais` | OLTP só tem batidas brutas | Saldo de horas por mês |
| `analytic_banco_horas` | OLTP não tem banco de horas | Crédito/débito acumulado |
| `analytic_atrasos_por_funcionario` | OLTP não classifica "atraso" | Ranking de pontualidade |
| `analytic_absenteismo_departamento` | OLTP não calcula taxa de falta | % de dias ausentes |
| `analytic_ferias_vencidas` | OLTP não alerta sobre passivo | Risco legal por funcionário |
| `analytic_ajustes_ponto_ranking` | OLTP não agrega padrões | Quem mais solicita ajuste |
| `analytic_headcount_mensal` | OLTP só mostra situação atual | Evolução histórica de equipe |
| `analytic_turnover_mensal` | OLTP não calcula rotatividade | Taxa de saída por área |
| `analytic_antiguidade_funcionarios` | OLTP não classifica veteranos | Risco de perda de conhecimento |
| `analytic_custo_hora_departamento` | OLTP não cruza salário × horas | Custo real por hora |
| `analytic_distribuicao_salarial` | OLTP não tem estatísticas | Bandas salariais (P25/P75) |
| `vw_funcionarios_anonimizados` | LGPD requer proteção de PII | Dados sem CPF/nome real |

---

## 🌐 Links Úteis

- [dbt Documentation](https://docs.getdbt.com)
- [dbt-utils Package](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/)
- [Best Practices — dbt](https://docs.getdbt.com/guides/best-practices)
- [PostgreSQL FDW](https://www.postgresql.org/docs/current/postgres-fdw.html)
- [LGPD — Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
