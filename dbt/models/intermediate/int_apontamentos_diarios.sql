-- =============================================================================
-- models/intermediate/int_apontamentos_diarios.sql (PASSO 3b)
-- =============================================================================
-- Objetivo: Transformar os apontamentos brutos (registros de entrada/saída)
--           em uma visão diária por funcionário, calculando as horas trabalhadas.
--
-- Lógica de pareamento de batidas:
--   1. Separar entradas e saídas
--   2. Numerar cada entrada/saída em ordem cronológica por funcionário/dia
--   3. Parear: 1ª entrada com 1ª saída, 2ª entrada com 2ª saída, etc.
--   4. Calcular duração de cada par (em horas)
--   5. Somar todas as durações do dia = horas_trabalhadas
--
-- Exemplo:
--   08:00 Entrada  (seq=1) ] → 4h
--   12:00 Saída    (seq=1) ]
--   13:00 Entrada  (seq=2) ] → 5h
--   18:00 Saída    (seq=2) ]
--   Total = 9h trabalhadas
-- =============================================================================

with admin_apontamentos as (

    select * from {{ ref('stg_admin__apontamentos') }}

),

motoristas_apontamentos as (

    select * from {{ ref('stg_motoristas__apontamentos') }}

),

-- Unifica todos os apontamentos dos dois sistemas
todos as (

    select * from admin_apontamentos
    union all
    select * from motoristas_apontamentos

),

-- Enumera cada ENTRADA por funcionário e dia (seq=1 = primeira entrada do dia)
entradas as (

    select
        funcionario_id,
        sistema_origem,
        data_apontamento,
        data_hora,
        row_number() over (
            partition by funcionario_id, sistema_origem, data_apontamento
            order by data_hora
        ) as seq

    from todos
    where tipo = 'Entrada'

),

-- Enumera cada SAÍDA por funcionário e dia
saidas as (

    select
        funcionario_id,
        sistema_origem,
        data_apontamento,
        data_hora,
        row_number() over (
            partition by funcionario_id, sistema_origem, data_apontamento
            order by data_hora
        ) as seq

    from todos
    where tipo = 'Saída'

),

-- Pareia entradas com saídas pelo número de sequência
pares as (

    select
        e.funcionario_id,
        e.sistema_origem,
        e.data_apontamento,
        e.data_hora                                             as hora_entrada,
        s.data_hora                                             as hora_saida,
        -- Duração do par em horas (divide segundos por 3600)
        extract(epoch from (s.data_hora - e.data_hora)) / 3600.0
                                                                as horas_periodo

    from entradas e
    inner join saidas s
        on  e.funcionario_id    = s.funcionario_id
        and e.sistema_origem    = s.sistema_origem
        and e.data_apontamento  = s.data_apontamento
        and e.seq               = s.seq  -- garante que pareia 1ª com 1ª, 2ª com 2ª

),

-- Agrega os pares do dia em um único registro diário
diario as (

    select
        funcionario_id,
        sistema_origem,
        data_apontamento,
        min(hora_entrada)                           as primeira_entrada,
        max(hora_saida)                             as ultima_saida,
        round(sum(horas_periodo)::numeric, 2)       as horas_trabalhadas,
        count(*)                                    as num_pares_batida

    from pares
    group by funcionario_id, sistema_origem, data_apontamento

)

select * from diario
