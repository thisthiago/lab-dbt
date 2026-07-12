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

### 0.1 Criar e ativar um ambiente virtual (venv) — **sempre façam isso primeiro**

Antes de instalar qualquer coisa, criem um ambiente virtual isolado só para este projeto. Isso evita dois problemas bem comuns: pacotes instalados no lugar errado (o Python "do usuário", que costuma não ficar visível no PATH) e conflito com outras instalações de dbt que já possam existir na máquina (inclusive o **dbt Fusion**, um motor novo e diferente do dbt-core que algumas pessoas já têm instalado sem saber, seja por engano seja pela extensão dbt do VS Code).

**Mac/Linux:**
```bash
cd caminho/para/o/projeto
python3 -m venv venv
source venv/bin/activate
```

**Windows (PowerShell):**
```powershell
cd caminho\para\o\projeto
python -m venv venv
.\venv\Scripts\Activate.ps1
```

> 💻 **Nota para quem está no Windows:** se a ativação falhar com um erro de "execução de scripts desabilitada", rode uma vez (peça para rodar como administrador, se pedir):
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```
> e tentem ativar de novo. (No cmd, em vez do `.ps1`, o comando seria `venv\Scripts\activate.bat`.)

### ✅ Checkpoint antes de continuar — não pulem isso

Depois de ativar, o início da linha do terminal **precisa** mostrar `(venv)`:

```
(venv) PS C:\Users\thiag\codes\teste-dbt>
```

**Se não aparecer `(venv)`, não sigam em frente** — a ativação não funcionou, e qualquer `pip install` rodado a partir daqui vai instalar os pacotes no lugar errado (fora do projeto), o que pode causar exatamente o mesmo problema de "comando não encontrado" que vimos durante os testes desta aula.

### 0.2 Instalar o dbt e as dependências

Com o `(venv)` confirmado, instalem tudo:

```bash
pip install dbt-core dbt-postgres pandas sqlalchemy psycopg2-binary
```

**O que cada pacote faz:**
- `dbt-core`: o motor do dbt (interpreta os arquivos `.sql` e `.yml` e gera SQL final).
- `dbt-postgres`: o "adaptador" que ensina o dbt a falar especificamente com PostgreSQL (existem adaptadores equivalentes para BigQuery, Snowflake, etc.).
- `pandas`, `sqlalchemy`, `psycopg2-binary`: usados pelo nosso script Python de carga de dados (`load_dw.py`), não pelo dbt em si.
- `psycopg2-binary` é a versão pré-compilada do driver do Postgres — por isso pedimos ela e não `psycopg2` puro, que exige compilador C instalado (principalmente chato no Windows). Não troquem por `psycopg2` sem necessidade.

Confirme que a instalação funcionou:
```bash
dbt --version
```
O resultado deve mostrar algo como `1.x.x` (a versão do dbt-core). **Se aparecer "dbt-fusion" em vez disso**, é sinal de que existe outra instalação de dbt na máquina tomando prioridade no PATH — nesse caso, chamem o professor/monitor antes de seguir, porque os comandos deste guia foram pensados para o dbt-core, não para o Fusion (que ainda está em beta e pode não suportar tudo que vamos usar, como o pacote `dbt-utils`).

> 💻 **Nota geral para quem está no Windows:** fora esses pontos, `dbt deps`, `dbt debug`, `dbt run`, `dbt build`, `--profiles-dir .` etc. funcionam exatamente igual no Windows, macOS e Linux — são comandos do próprio dbt, não do sistema operacional.

> ⚠️ **Lembrete para toda a aula:** o `venv` precisa ser **reativado toda vez que abrirem um terminal novo** (ele não fica ativo permanentemente). Sempre que for rodar um comando `dbt` ou `python`, confiram primeiro se o `(venv)` está aparecendo no início da linha.

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

### 0.3 Exemplo real do fluxo interativo (se alguém quiser testar por conta própria)

Se você rodar o `dbt init` (fora do projeto da aula, só para praticar), o terminal vai perguntar campo por campo. Um exemplo real de preenchimento, usando um banco Postgres local:

```
$ dbt init banco_horas_dbt

Which database would you like to use?
[1] postgres
Enter a number: 1
host (hostname for the instance): localhost
port [5432]: 5455
user (dev username): postgres
pass (dev password):
dbname (default database that dbt will build objects in): db_dw
schema (default schema that dbt will build objects in): public
threads (1 or more) [1]: 1

Profile banco_horas_dbt written to C:\Users\<usuario>\.dbt\profiles.yml ...
```

**O que cada campo significa:**
- **host**: `localhost` porque o Postgres está rodando na própria máquina (ex: via Docker).
- **port**: a porta em que o Postgres está exposto — aqui `5455` em vez da porta padrão `5432`, normalmente porque já existe outro Postgres rodando na `5432` (ex: uma instalação local) e o do curso foi mapeado numa porta diferente para não conflitar.
- **user** / **pass**: as credenciais de acesso ao banco.
- **dbname**: o banco de dados dentro do Postgres onde o dbt vai criar as tabelas/views.
- **schema**: o "namespace" padrão dentro do banco onde os objetos serão criados (isso pode ser sobrescrito depois pela macro `generate_schema_name.sql` que vamos criar na Etapa 2).
- **threads**: quantos modelos o dbt pode rodar em paralelo. `1` é mais lento, mas mais previsível para aprender — depois dá pra aumentar.

**Onde isso foi parar:** repare que o dbt escreveu o resultado em `C:\Users\<usuario>\.dbt\profiles.yml` — a pasta **oculta e global** do usuário, e não na raiz do projeto. Isso é o comportamento padrão do `dbt init`. Se essa conexão for só para um teste pessoal (fora do repositório da aula), tudo bem deixar assim. Mas se for para o projeto da disciplina, o ideal é copiar esse bloco gerado para o `profiles.yml` que já existe na raiz do repositório do curso, para manter a portabilidade explicada acima.

### ✅ Como testar se a conexão funcionou

Depois do `dbt init` (ou de configurar o `profiles.yml` manualmente), teste a conexão com:

```bash
dbt debug
```

Se você tiver salvo o profile na pasta global (como no exemplo acima), roda assim, sem flag. Se estiver usando um `profiles.yml` na raiz do projeto (como no repositório da aula), use:

```bash
dbt debug --profiles-dir .
```

**O que esperar:**
- Se tudo estiver certo, o final da saída mostra algo como `All checks passed!` — significa que o dbt conseguiu ler o `profiles.yml`, o `dbt_project.yml`, e efetivamente abrir uma conexão com o Postgres usando as credenciais informadas.
- Se der erro de conexão (ex: `connection refused`), geralmente é porque o Postgres não está rodando, ou a porta/host informados estão errados — vale conferir se o container/serviço do banco está de pé.
- Se der erro de autenticação (ex: `password authentication failed`), é usuário ou senha incorretos.
- Se der erro dizendo que o banco (`dbname`) não existe, é preciso criar esse banco no Postgres antes (ou usar o nome correto de um banco já existente).

### 0.4 Entendendo a estrutura de pastas que o `dbt init` cria

Assim que o comando roda, ele gera automaticamente esta árvore de pastas:

```
├───analyses
├───logs
├───macros
├───models
│   └───example
├───seeds
├───snapshots
└───tests
```

**O que cada uma faz:**

- **`analyses/`** — SQL solto que você quer que o dbt compile (resolvendo os `{{ }}` e macros), mas que **não** vira tabela/view no banco. Serve para rascunhos, queries ad-hoc, ou para gerar SQL que você vai colar em outro lugar.
- **`logs/`** — onde o dbt salva o log detalhado de cada execução (`dbt.log`). Útil para debugar quando um comando falha e a mensagem no terminal não é suficiente.
- **`macros/`** — as funções reutilizáveis em Jinja+SQL, como as que vamos criar na Etapa 2 deste guia (`generate_schema_name.sql`, `pii_macros.sql`).
- **`models/`** (com a subpasta `example/`) — o coração do projeto: é aqui que ficam os arquivos `.sql` que viram tabelas/views no banco. A pasta `example/` vem com 2-3 modelos de exemplo só para mostrar a sintaxe — **pode apagar** esses exemplos, porque no nosso projeto vamos organizar tudo em subpastas próprias (`staging/`, `intermediate/`, `marts/`, `analytics/`).
- **`seeds/`** — pasta para arquivos `.csv` que você quer carregar direto no banco via `dbt seed` (útil para tabelas pequenas e estáticas, tipo uma lista de estados/países). No nosso projeto **não vamos usar essa pasta**, porque quem carrega os dados brutos é o `load_dw.py`.
- **`snapshots/`** — para capturar o histórico de mudanças de uma tabela ao longo do tempo (Slowly Changing Dimensions). Também **não vamos usar** no nosso projeto — é um tópico mais avançado.
- **`tests/`** — onde ficam os testes singulares escritos manualmente em SQL, como os do Passo 8 deste guia (`assert_horas_trabalhadas_positivas.sql`).

> 💡 **No projeto da aula**, praticamente só `models/`, `macros/` e `tests/` são usados de fato — `analyses/`, `seeds/` e `snapshots/` ficam vazias e podem ser ignoradas sem problema.

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