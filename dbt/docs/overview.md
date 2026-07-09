{% docs __overview__ %}

# 📊 Lab dbt MBA — Sistema de Ponto Eletrônico

Bem-vindo à documentação do projeto **lab-dbt-mba**!

Este projeto foi construído como **guia didático** para alunos de MBA aprendendo
modelagem dimensional e dbt. Ele transforma dados transacionais de um sistema de
ponto eletrônico em um Data Warehouse analítico.

---

## 🏗️ Arquitetura de Dados

```
[db_admin]          [db_motoristas]
     │                    │
     └──────── FDW ────────┘
                  │
              [db_dw]
          ┌────────────────────────────┐
          │  raw_admin / raw_motoristas │  ← Foreign Tables (via postgres_fdw)
          ├────────────────────────────┤
          │  staging.*                  │  ← Limpeza e padronização
          ├────────────────────────────┤
          │  marts.*                    │  ← Fatos e Dimensões
          ├────────────────────────────┤
          │  analytics.*               │  ← Visões para o analista de RH
          └────────────────────────────┘
```

## 📁 Camadas do Projeto

| Camada | Schema | Materialização | Propósito |
|--------|--------|---------------|-----------|
| Sources | `raw_admin` / `raw_motoristas` | Foreign Tables | Fontes OLTP via FDW |
| Staging | `staging` | View | Limpeza, renomear, tipagem |
| Intermediate | (ephemeral) | CTE inline | Transformações complexas |
| Marts | `marts` | Table | Dimensões e Fatos do DW |
| Analytics | `analytics` | View | Visões prontas para RH |

## 🎯 Visões Analíticas Disponíveis

- **analytic_horas_mensais** — Consolidação mensal de jornada
- **analytic_banco_horas** — Saldo acumulado de horas extras
- **analytic_atrasos_por_funcionario** — Ranking de pontualidade
- **analytic_absenteismo_departamento** — Taxa de faltas por área
- **analytic_ferias_vencidas** — Passivo trabalhista de férias
- **analytic_ajustes_ponto_ranking** — Padrões de ajuste de ponto
- **analytic_headcount_mensal** — Evolução histórica de headcount
- **analytic_turnover_mensal** — Taxa de rotatividade
- **analytic_antiguidade_funcionarios** — Distribuição de tempo de casa
- **analytic_custo_hora_departamento** — Custo/hora por departamento
- **analytic_distribuicao_salarial** — Análise estatística de salários
- **vw_funcionarios_anonimizados** — Dados anonimizados (LGPD)

{% enddocs %}
