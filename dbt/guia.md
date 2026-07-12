# 🚀 Guia Passo a Passo: Construindo seu Primeiro Projeto dbt

Este guia foi desenhado para quem tem **zero experiência com dbt**. Ele mostra, na **ordem exata de execução**, quais arquivos criar, onde criá-los, para que servem e quais comandos rodar em cada etapa.

**A lógica do projeto:** vamos construir o Data Warehouse **camada por camada**, do dado bruto até a visão final de negócio:

```
Fontes (raw) → Staging (limpeza) → Intermediate (regras de negócio) → Marts (fatos e dimensões) → Analytics (visões prontas)
```

---

## 🧭 Antes de começar: como este guia funciona

Cada etapa abaixo tem três partes:
- **📄 Arquivo(s):** o que criar e onde.
- **💡 O que é / por que existe:** a explicação conceitual.
- **⌨️ Comando:** o que rodar no terminal *naquele momento* (quando existir).

Sempre que houver um comando, rode-o **antes de seguir para a próxima etapa** — isso evita acumular erros.

---

## 🏗️ Etapa 0 — Preparando o ambiente

### 0.1 Instalar o dbt e as dependências

```bash
pip install dbt-core dbt-postgres pandas sqlalchemy psycopg2-binary
```

**O que cada pacote faz:**
- `dbt-core`: o motor do dbt (interpreta os arquivos `.sql` e `.yml` e gera SQL final).
- `dbt-postgres`: o "adaptador" que ensina o dbt a falar especificamente com PostgreSQL (existem adaptadores equivalentes para BigQuery, Snowflake, etc.).
- `pandas`, `sqlalchemy`, `psycopg2-binary`: usados pelo nosso script Python de carga de dados (`load_dw.py`), não pelo dbt em si.

Confirme que a instalação funcionou:
```bash
dbt --version
```

> 💻 **Nota para quem está no Windows:**
> - Se o comando `pip` não for reconhecido, tente `python -m pip install ...` no lugar de `pip install ...` (garante que está usando o pip da mesma instalação do Python que está no PATH).
> - Se estiverem usando um ambiente virtual (`venv`) e a ativação falhar no PowerShell com um erro de "execução de scripts desabilitada", rode uma vez (como administrador, se pedir):
>   ```powershell
>   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
>   ```
>   e tentem ativar de novo com `.\venv\Scripts\Activate.ps1` (no cmd seria `venv\Scripts\activate.bat`).
> - `psycopg2-binary` é a versão pré-compilada do driver do Postgres — por isso pedimos ela e não `psycopg2` puro, que exige compilador C instalado no Windows. Não troquem por `psycopg2` sem necessidade.
> - Fora esses pontos, `dbt deps`, `dbt debug`, `dbt run`, `dbt build`, `--profiles-dir .` etc. funcionam exatamente igual no Windows, macOS e Linux — são comandos do próprio dbt, não do sistema operacional.

### 0.2 Entendendo o `dbt init` (contexto — vocês não vão rodar isso na aula)

Em um projeto criado do zero, o comando oficial de inicialização é:
```bash
dbt init meu_projeto_dbt
```

Esse comando:
1. Faz perguntas interativas no terminal (ex: qual banco de dados usar → `postgres`).
2. Pede os dados de conexão e os salva em um arquivo **oculto e global**, geralmente em `~/.dbt/profiles.yml` (Mac/Linux) ou `C:\Users\usuario\.dbt\profiles.yml` (Windows).
3. Cria a estrutura inicial de pastas: `models/`, `macros/`, `tests/` e o arquivo `dbt_project.yml`.

> **💡 Por que estamos explicando isso se vocês não vão rodar?**
> Porque o projeto da aula **já vem pronto** — mas com uma diferença proposital em relação ao padrão: para que todo mundo consiga clonar o repositório e rodar sem precisar configurar arquivos ocultos na própria máquina, **trazemos o `profiles.yml` para a raiz do projeto**. Por isso, sempre que formos rodar um comando dbt, vamos usar a flag `--profiles-dir .`, que diz ao dbt "procure as credenciais na pasta atual, não na pasta oculta do sistema". Isso torna o projeto 100% portátil entre máquinas.

---

## 🛠️ Etapa 1 — Configuração do projeto e conexão

Objetivo: deixar o dbt sabendo *onde* conectar e *como* se comportar, antes de escrever qualquer transformação.

### 📄 `dbt_project.yml` (raiz da pasta `dbt/`)
**💡 O que é:** o coração do projeto. Define o nome do projeto (`name`), em qual schema cada pasta de modelos vai gravar (`staging`, `marts`, etc.) e como cada camada será materializada (`view` ou `table`).

### 📄 `profiles.yml` (raiz da pasta `dbt/`)
**💡 O que é:** o arquivo de credenciais. Ensina o dbt a se conectar ao PostgreSQL: `host` (localhost), porta (5455), usuário e senha.

### 📄 `packages.yml` (raiz da pasta `dbt/`)
**💡 O que é:** assim como no Python temos bibliotecas, o dbt permite instalar pacotes de terceiros. Aqui declaramos o `dbt-utils`, que traz macros prontas (geradores de chave, funções de calendário, etc.).

**⌨️ Comando (rodar assim que o `packages.yml` existir):**
```bash
dbt deps --profiles-dir .
```
Isso baixa e instala os pacotes listados dentro de uma pasta `dbt_packages/`.

### 📄 `load_dw.py` (raiz da pasta `dbt/`)
**💡 O que é:** um script Python (usando Pandas) que simula o processo de **EL (Extract, Load)** que, no mercado real, é feito por ferramentas de engenharia de dados. Ele extrai os dados de funcionários e apontamentos das bases de origem e carrega na área **raw** do Data Warehouse — ou seja, é o que "alimenta" o banco antes do dbt entrar em ação.

**⌨️ Comando:**
```bash
python load_dw.py
```

### ✅ Checkpoint da Etapa 1
Ao final desta etapa, o banco de dados já deve ter os dados brutos carregados, e o dbt já deve conseguir se conectar. Teste com:
```bash
dbt debug --profiles-dir .
```
Se aparecer `All checks passed!`, pode seguir em frente.

---

## 🧩 Etapa 2 — Macros (funções reutilizáveis)

Macros são pedaços de código SQL escritos uma vez e reutilizados várias vezes — pense neles como funções do Excel.

### 📄 `macros/generate_schema_name.sql`
**💡 O que é:** por padrão, o dbt concatena o schema principal com o nome da pasta (ex: `public_marts`). Esta macro ensina o dbt a criar schemas "limpos", chamados apenas `marts`, `staging`, etc.

### 📄 `macros/pii_macros.sql`
**💡 O que é:** funções de conformidade com a LGPD, como `anonimizar_nome` e `hash_pii` (para criptografar o CPF). Serão usadas mais adiante, na camada Analytics.

*(Nenhum comando novo nesta etapa — as macros só passam a valer quando forem chamadas dentro de outros modelos.)*

---

## 📥 Etapa 3 — Declarando as fontes (Sources)

### 📄 `models/sources/_sources.yml`
**💡 O que é:** um mapeamento das tabelas que **já existem** no banco (vindas do `load_dw.py`), como `funcionario` e `apontamento`, presentes nos schemas `raw_admin` e `raw_motoristas`.

**Por que isso importa:** a partir de agora, em vez de escrever o nome do schema "na unha" dentro do SQL, usamos a sintaxe:
```sql
{{ source('nome_do_sistema', 'nome_da_tabela') }}
```
Isso garante o rastreamento da linhagem dos dados (o dbt consegue desenhar de onde cada tabela final se originou).

---

## 🧹 Etapa 4 — Camada Staging (a limpeza)

**Regra de ouro do dbt:** nunca faça `JOIN` e limpeza na mesma tabela. A Staging é uma cópia 1:1 da fonte, servindo só para limpar e renomear colunas para um padrão único (`snake_case`). Por serem leves, são materializadas como **Views**.

### 📄 Criar em `models/staging/`:
1. `stg_admin__funcionarios.sql`
2. `stg_admin__apontamentos.sql`
3. `stg_motoristas__funcionarios.sql`
4. `stg_motoristas__apontamentos.sql`

### 📄 `models/staging/_staging.yml`
**💡 O que é:** documenta o significado de cada coluna das views acima e adiciona **testes automáticos** (ex: garantir que o ID não seja nulo e seja único).

### ✅ Checkpoint da Etapa 4
```bash
dbt run --select staging --profiles-dir .
```
Isso constrói **só** as views de staging, sem tocar no resto — bom para validar essa camada isoladamente antes de seguir.

---

## 🔄 Etapa 5 — Camada Intermediate (o motor)

Aqui os dados dos dois sistemas se encontram, e é onde mora a maior parte da complexidade de negócio. Essas tabelas **não gravam nada no banco** (são `ephemeral`) — servem apenas de "ponte" organizadora entre a Staging e a Marts.

### 📄 Criar em `models/intermediate/`:
1. **`int_funcionarios_unificados.sql`** — junta (`UNION`) motoristas e administrativos em um único "listão" e cria uma chave única (Surrogate Key) para cada pessoa.
2. **`int_apontamentos_diarios.sql`** — transforma os apontamentos brutos: une a linha de "Entrada" com a linha de "Saída" para calcular quantas horas a pessoa trabalhou naquele dia.
3. **`_intermediate.yml`** — documentação e testes desta camada.

---

## 🌟 Etapa 6 — Camada Marts (o Data Warehouse)

Estas são as tabelas finais de uso do negócio, gravadas fisicamente (`table`) para consultas rápidas. Usamos **Modelagem Dimensional** (Fatos e Dimensões).

### 📄 Criar em `models/marts/`:
1. **`dim_funcionario.sql`** — a dimensão "Quem". Puxa o listão unificado e enriquece com idade e tempo de empresa de cada funcionário.
2. **`dim_data.sql`** — dimensão de calendário (dia, mês, ano), gerada via macro.
3. **`fato_ponto.sql`** — a tabela de eventos (o "O quê"). Junta as horas diárias calculadas na Intermediate com as dimensões, para sabermos exatamente horas extras e atrasos de cada funcionário em cada dia.
4. **`_marts.yml`** — documentação, testes e relacionamentos (chaves estrangeiras) entre fato e dimensões.

### ✅ Checkpoint da Etapa 6
```bash
dbt run --select marts --profiles-dir .
```

---

## 📊 Etapa 7 — Camada Analytics (visões do RH)

Aqui entregamos valor direto para quem vai consumir os dados no dia a dia — o analista de RH.

### 📄 Criar em `models/analytics/`:
1. **`analytic_horas_mensais.sql`** — agrupa a `fato_ponto` por mês, somando o saldo de horas de cada funcionário.
2. **`analytic_absenteismo_departamento.sql`** — calcula a taxa de faltas cruzando quem bateu ponto contra os dias úteis possíveis.
3. **`vw_funcionarios_anonimizados.sql`** — aplica as macros de LGPD (da Etapa 2) sobre a `dim_funcionario`.
4. **`_analytics.yml`** — documentação de cada visão.

---

## 🧪 Etapa 8 — Testes singulares

Além dos testes simples do `.yml` (não nulo, único), podemos escrever SQLs que testam regras de negócio mais complexas. **O teste passa se a query retornar 0 linhas** (ou seja, "não encontrei nenhum caso de erro").

### 📄 Criar em `tests/`:
1. **`assert_horas_trabalhadas_positivas.sql`** — procura na `fato_ponto` horas trabalhadas negativas (cenário impossível que indicaria bug no cálculo).
2. **`assert_fato_ponto_sem_duplicatas.sql`** — garante que não existem 2 linhas do mesmo funcionário no mesmo dia.

---

## 📖 Etapa 9 — Documentação geral

### 📄 `docs/overview.md`
**💡 O que é:** a capa do catálogo de dados. O texto em markdown escrito aqui vira a tela de boas-vindas do portal de documentação gerado pelo dbt.

---

## ▶️ Etapa 10 — Rodando tudo (execução final)

Com todos os arquivos criados, abra o terminal **dentro da pasta `dbt/`** e rode, **nesta ordem**:

| # | Comando | O que faz |
|---|---------|-----------|
| 1 | `pip install pandas sqlalchemy psycopg2-binary dbt-postgres` | Garante que todas as dependências estão instaladas |
| 2 | `dbt deps --profiles-dir .` | Instala os pacotes declarados em `packages.yml` (ex: `dbt-utils`) |
| 3 | `python load_dw.py` | Copia os dados da base de origem para a área raw do DW |
| 4 | `dbt build --profiles-dir .` | Constrói **todas** as tabelas/views, na ordem correta de dependência, e roda todos os testes |
| 5 | `dbt docs generate --profiles-dir .` | Gera o dicionário de dados e o diagrama de linhagem |
| 6 | `dbt docs serve --profiles-dir .` | Abre o portal de documentação no navegador |

> 💡 **Por que sempre `--profiles-dir .`?** Porque, como vimos na Etapa 0, o `profiles.yml` deste projeto está na raiz (e não na pasta oculta padrão do dbt). Essa flag avisa o dbt para procurar as credenciais ali.

> 💡 **Diferença entre `dbt run` e `dbt build`:** `dbt run` só executa os modelos (cria as tabelas/views). `dbt build` faz isso **e também** roda os testes automaticamente, na ordem de dependência — por isso é o comando recomendado no final.

---

## 🎉 Resultado esperado

Se tudo rodou sem erros, vocês terão:
- Um Data Warehouse completo, organizado em camadas (Staging → Intermediate → Marts → Analytics).
- Testes automáticos garantindo a qualidade dos dados.
- Um portal de documentação navegável, com a linhagem completa de cada tabela.

**Parabéns, vocês construíram um Data Warehouse do zero com dbt!** 🎉
