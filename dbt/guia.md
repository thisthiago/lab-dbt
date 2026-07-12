# 🚀 Guia Passo a Passo: Construindo seu Primeiro Projeto dbt

Este guia foi desenhado para você que tem **zero experiência com dbt**. Ele vai te pegar pela mão e mostrar exatamente **quais arquivos criar, onde criá-los e qual o objetivo de cada um**, na ordem exata de implementação.

A ideia é que você construa o Data Warehouse camada por camada, do básico ao avançado. Vamos começar!

---

## 🏗️ Passo 0: Inicializando o Projeto (Como Criar do Zero)

Se você estivesse criando este projeto completamente do zero, a forma oficial de iniciar é seguindo estas etapas no terminal:

**1. Instalar o dbt (Core e Adaptador do Postgres)**
Primeiro, é necessário instalar o núcleo do dbt (`dbt-core`) e o adaptador específico para o seu banco de dados (`dbt-postgres`), além das bibliotecas que usaremos no nosso script de carga.

```bash
pip install dbt-core dbt-postgres pandas sqlalchemy psycopg2-binary
```

Você pode verificar se a instalação deu certo rodando:
```bash
dbt --version
```

**2. Iniciar o projeto (dbt init)**
Com o dbt instalado, rodamos o comando oficial de inicialização:

```bash
dbt init meu_projeto_dbt
```

**O que esse comando faz?**
1. Ele faz perguntas interativas no terminal (ex: qual banco de dados usar? No nosso caso, seria `postgres`).
2. Ele pede os dados de conexão do banco e os salva em um arquivo global oculto chamado `profiles.yml` (geralmente em `~/.dbt/profiles.yml` ou `C:\Users\usuario\.dbt\profiles.yml`).
3. Ele cria toda a estrutura inicial de pastas (`models/`, `macros/`, `tests/` e o arquivo `dbt_project.yml`).

> **A Dica de Ouro para Projetos e Git:**
> Para facilitar o uso do repositório em aula e evitar que cada aluno precise configurar arquivos ocultos em suas próprias máquinas, nós **trazemos o arquivo `profiles.yml` para a raiz do projeto**.
> Ao fazer isso, os alunos podem apenas clonar o repositório e executar os comandos usando a flag `--profiles-dir .` (ex: `dbt debug --profiles-dir .`), que obriga o dbt a ler as credenciais da pasta atual, tornando o projeto 100% portátil!

---

## 🛠️ Passo 1: Configuração do Projeto e Conexão

Antes de escrever qualquer transformação de dados, precisamos configurar o ambiente do dbt para ele saber onde conectar e como se comportar.

1. **`load_dw.py`** (na raiz da pasta `dbt/`)
   - **O que é:** Um script Python usando a biblioteca Pandas. No mercado real, as ferramentas de engenharia de dados extraem dados dos sistemas e carregam no Data Warehouse (EL - Extract, Load). Este script simula isso, puxando os dados de funcionários e apontamentos e salvando na área "raw" do DW.
   - **Ação:** Instale as bibliotecas (`pip install pandas sqlalchemy psycopg2-binary dbt-postgres`) e execute `python load_dw.py` para popular o DW antes do dbt entrar em ação.

2. **`dbt_project.yml`** (na raiz da pasta `dbt/`)
   - **O que é:** O coração do projeto dbt. Aqui você define o nome do projeto (`name`), diz em qual schema padrão cada pasta vai gravar seus dados (`marts`, `staging`) e como elas serão materializadas (se vão virar `view` ou `table` no banco).

3. **`profiles.yml`** (na raiz da pasta `dbt/`)
   - **O que é:** O arquivo de credenciais. Ensina o dbt a se conectar no seu PostgreSQL. Ele precisa saber o `host` (localhost), a porta (5455), usuário e senha.

4. **`packages.yml`** (na raiz da pasta `dbt/`)
   - **O que é:** O dbt permite instalar pacotes de terceiros (como bibliotecas no Python). Aqui vamos declarar o `dbt-utils`, que nos dá funções prontas (macros) para facilitar a vida, como geradores de chaves e calendário.
   - **Ação:** Após criar, rode o comando `dbt deps` no terminal.

---

## 🧩 Passo 2: Macros (Funções Reutilizáveis)

Macros são pedaços de código SQL que escrevemos uma vez e reutilizamos várias vezes. Pense nelas como as funções do Excel.

1. **`macros/generate_schema_name.sql`**
   - **O que é:** Por padrão, o dbt junta o nome do seu schema principal com o da pasta (ex: `public_marts`). Esta macro ensina o dbt a criar schemas limpos, chamando apenas `marts`, `staging`, etc.

2. **`macros/pii_macros.sql`**
   - **O que é:** Aqui vamos colocar nossas funções de conformidade com a LGPD. Macros como `anonimizar_nome` e `hash_pii` (para criptografar o CPF). Usaremos isso lá na frente!

---

## 📥 Passo 3: Declarando as Fontes (Sources)

O dbt precisa saber quais tabelas já existem no banco antes dele começar a trabalhar.

1. **`models/sources/_sources.yml`**
   - **O que é:** É um mapeamento. Vamos listar as tabelas `funcionario` e `apontamento` que vêm do schema `raw_admin` e `raw_motoristas`.
   - **Por que fazer isso?** Para podermos usar a sintaxe `{{ source('nome_do_sistema', 'nome_da_tabela') }}` em vez de chumbarmos o nome do schema nos códigos, garantindo o rastreamento da linhagem dos dados.

---

## 🧹 Passo 4: Camada Staging (A Limpeza)

A regra de ouro do dbt é: **nunca faça join e limpeza na mesma tabela**. A Staging é uma cópia 1:1 da fonte, apenas para limpar e renomear colunas para um padrão (snake_case). Elas serão materializadas como *Views*.

Crie os 4 arquivos `.sql` dentro da pasta `models/staging/`:
1. **`stg_admin__funcionarios.sql`**
2. **`stg_admin__apontamentos.sql`**
3. **`stg_motoristas__funcionarios.sql`**
4. **`stg_motoristas__apontamentos.sql`**

E, para fechar a camada, crie a documentação:
5. **`models/staging/_staging.yml`**
   - **O que é:** Documenta o que significa cada coluna dessas views criadas e adiciona **testes automáticos** (garantir que o ID não seja nulo e seja único).

---

## 🔄 Passo 5: Camada Intermediate (O Motor)

Aqui os dados dos dois sistemas se encontram. É onde a complexidade mora. Elas não gravam tabelas no banco (são `ephemeral`), servem apenas como "ponte" organizadora.

Crie dentro de `models/intermediate/`:
1. **`int_funcionarios_unificados.sql`**
   - **O que é:** Junta (UNION) os motoristas com os administrativos em um listão único e cria uma chave única para cada um (Surrogate Key).
2. **`int_apontamentos_diarios.sql`**
   - **O que é:** Transforma os apontamentos brutos. Aqui a lógica une a linha de "Entrada" com a linha de "Saída" para calcular quantas horas a pessoa trabalhou no dia.
3. **`models/intermediate/_intermediate.yml`**
   - Para documentar e testar.

---

## 🌟 Passo 6: Camada Marts (O Data Warehouse)

Estas são as tabelas finais de uso do negócio. Elas gravam fisicamente (`table`) no banco para serem ultrarrápidas. Nós usamos Modelagem Dimensional (Fatos e Dimensões).

Crie dentro de `models/marts/`:
1. **`dim_funcionario.sql`**
   - **O que é:** Tabela descritiva de "Quem". Puxa o listão de funcionários e enriquece calculando a idade e o tempo de empresa de cada um.
2. **`dim_data.sql`**
   - **O que é:** Tabela de calendário (Dias, Mês, Ano). Gerada via macro.
3. **`fato_ponto.sql`**
   - **O que é:** A tabela de eventos (o "O quê"). Aqui juntamos as horas diárias calculadas com as dimensões para sabermos exatamente as horas extras e atrasos de cada funcionário em cada dia.
4. **`models/marts/_marts.yml`**
   - Sempre documentando e amarrando relacionamentos (Foreign Keys).

---

## 📊 Passo 7: Camada Analytics (Visões do RH)

Onde entregamos valor imediato para o analista de RH.

Crie dentro de `models/analytics/`:
1. **`analytic_horas_mensais.sql`**
   - Agrupa a `fato_ponto` por mês, somando o saldo de horas de cada funcionário.
2. **`analytic_absenteismo_departamento.sql`**
   - Calcula a taxa de faltas cruzando quem bateu ponto contra os dias úteis possíveis.
3. **`vw_funcionarios_anonimizados.sql`**
   - Aplica as macros de LGPD (lá do Passo 2) sobre a `dim_funcionario`.
4. **`models/analytics/_analytics.yml`**
   - Documenta e explica cada visão.

---

## 🧪 Passo 8: Testes Singulares

Além dos testes simples no `.yml` (como não nulo), podemos escrever SQLs que testam lógicas complexas. O teste passa se a query retornar 0 linhas.

Crie em `tests/`:
1. **`assert_horas_trabalhadas_positivas.sql`**
   - Query que procura na `fato_ponto` por horas trabalhadas negativas (um cenário impossível que indicaria bug no cálculo).
2. **`assert_fato_ponto_sem_duplicatas.sql`**
   - Garante que não há 2 linhas do mesmo funcionário no mesmo dia.

---

## 📖 Passo 9: Documentação Geral

1. **`docs/overview.md`**
   - **O que é:** É a capa do seu catálogo de dados! Quando o dbt gerar o site de documentação, o que você escrever em markdown aqui, será a tela de boas-vindas do portal.

---

## ▶️ Passo 10: Colocando tudo para rodar!

Abra o seu terminal na pasta `dbt/` e rode na seguinte ordem:

1. Instale o dbt-postgres e dependências rodando: `pip install pandas sqlalchemy psycopg2-binary dbt-postgres`
2. `dbt deps` (Instala pacotes do packages.yml)
3. `python load_dw.py` (Copia os dados da base de produção para a base do DW)
4. `dbt build` (Cria todas as tabelas no banco de dados e roda todos os testes, na ordem exata que elas dependem uma da outra).
5. `dbt docs generate && dbt docs serve` (Gera o portal web com todo o dicionário de dados e a linhagem desenhada e abre no seu navegador!).

**Parabéns! Você construiu um Data Warehouse completo!** 🎉
