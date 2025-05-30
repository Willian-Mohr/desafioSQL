# Universidade - Sistema de Horários com PostgreSQL e pgAdmin

Projeto exemplo de controle acadêmico: gestão de professores, turmas, horários e salas, com Docker, PostgreSQL e pgAdmin.

---

## Pré-requisitos

- Docker e Docker Compose instalados
- Portas 5432 (PostgreSQL) e 5050 (pgAdmin) livres
- Sistema operacional Linux, Mac ou Windows

---

## Como subir o ambiente

1. Clone este repositório ou copie os arquivos do projeto.
2. No terminal, execute:
    ```sh
    docker compose up -d
    ```
3. O ambiente será iniciado com:
   - PostgreSQL já populado
   - pgAdmin pronto para uso

---

## Acessando o pgAdmin

1. Acesse: [http://localhost:5050](http://localhost:5050)
2. Login:
   - **Email:** `admin@admin.com`
   - **Senha:** `admin`
3. O servidor já estará configurado como `postgres-db`.
4. Acesse o banco chamado `universidade` pelo painel esquerdo.

---

## Estrutura do banco de dados

- **DEPARTMENT**: Departamentos acadêmicos
- **TITLE**: Titulação dos professores
- **PROFESSOR**: Professores
- **BUILDING**: Prédios
- **ROOM**: Salas de aula
- **SUBJECT**: Disciplinas
- **SUBJECT_PREREQUISITE**: Pré-requisitos entre disciplinas
- **CLASS**: Turmas (cada uma ligada a professor e disciplina)
- **CLASS_SCHEDULE**: Horários e salas das turmas

O banco é criado automaticamente, e populado com dados de exemplo.

---

## Consultas importantes

### 1. Quantidade de horas que cada professor tem comprometido em aulas

```sql
SELECT
    p.id AS professor_id,
    p.name AS professor_name,
    COALESCE(SUM(EXTRACT(EPOCH FROM (cs.end_time - cs.start_time))/3600), 0) AS total_hours
FROM
    PROFESSOR p
LEFT JOIN CLASS c ON c.professor_id = p.id
LEFT JOIN CLASS_SCHEDULE cs ON cs.class_id = c.id
GROUP BY
    p.id, p.name
ORDER BY
    total_hours DESC, professor_name;
```

#### Explicação detalhada

- `p.id AS professor_id, p.name AS professor_name`: Exibe o ID e o nome do professor.
- `LEFT JOIN CLASS c ON c.professor_id = p.id`: Junta as turmas que cada professor leciona. O `LEFT JOIN` garante que professores sem turmas cadastradas também apareçam.
- `LEFT JOIN CLASS_SCHEDULE cs ON cs.class_id = c.id`: Junta os horários de cada turma do professor. `LEFT JOIN` garante que professores/turmas sem horários agendados também apareçam.
- `cs.end_time - cs.start_time`: Calcula a duração de cada aula.
- `EXTRACT(EPOCH FROM (...))`: Converte a duração para segundos.
- `... / 3600`: Converte segundos para horas.
- `SUM(...)`: Soma as horas de todas as aulas do professor.
- `COALESCE(..., 0)`: Se o professor não tiver aulas, mostra zero no lugar de NULL.
- `GROUP BY p.id, p.name`: Agrupa por professor.
- `ORDER BY total_hours DESC, professor_name`: Mostra primeiro quem tem mais horas de aula.

##### Exemplo de resultado

| professor_id | professor_name   | total_hours |
|--------------|-----------------|-------------|
| 1            | João Silva      | 4           |
| 2            | Maria Oliveira  | 2           |
| ...          | ...             | ...         |

---

### 2. Lista de horários ocupados por sala

```sql
SELECT
    r.id AS room_id,
    r.name AS room_name,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    'OCUPADO' AS status
FROM
    ROOM r
JOIN CLASS_SCHEDULE cs ON cs.room_id = r.id
ORDER BY
    r.id, cs.day_of_week, cs.start_time;
```

#### Explicação detalhada

- `r.id AS room_id, r.name AS room_name`: Exibe o ID e nome da sala.
- `JOIN CLASS_SCHEDULE cs ON cs.room_id = r.id`: Junta todos os horários já ocupados daquela sala.
- `cs.day_of_week`: Indica o dia da semana em que a sala está ocupada (1 = segunda, 2 = terça, etc).
- `cs.start_time, cs.end_time`: Horário de início e fim do uso da sala.
- `'OCUPADO' AS status`: Marca a linha como OCUPADO.
- `ORDER BY ...`: Ordena a lista por sala, dia e horário.

##### Exemplo de resultado

| room_id | room_name | day_of_week | start_time | end_time | status   |
|---------|-----------|-------------|------------|----------|----------|
| 1       | A101      | 2           | 08:00      | 10:00    | OCUPADO  |
| 2       | A102      | 3           | 10:00      | 12:00    | OCUPADO  |
| ...     | ...       | ...         | ...        | ...      | ...      |

---

### 3. Lista de horários livres por sala

```sql
WITH horas AS (
    SELECT 
        (generate_series(
            '2024-01-01 08:00'::timestamp, 
            '2024-01-01 16:00'::timestamp, 
            '2 hour'::interval
        ))::time AS start_time
),
dias AS (
    SELECT generate_series(1, 6) AS day_of_week
)
SELECT
    r.id AS room_id,
    r.name AS room_name,
    d.day_of_week,
    h.start_time,
    (h.start_time + interval '2 hour') AS end_time,
    'LIVRE' AS status
FROM
    ROOM r
CROSS JOIN dias d
CROSS JOIN horas h
WHERE NOT EXISTS (
    SELECT 1 FROM CLASS_SCHEDULE cs
    WHERE cs.room_id = r.id
      AND cs.day_of_week = d.day_of_week
      AND (h.start_time, h.start_time + interval '2 hour')
          OVERLAPS (cs.start_time, cs.end_time)
)
ORDER BY
    r.id, d.day_of_week, h.start_time;
```

#### Explicação detalhada

- `WITH horas AS (...)`: Cria blocos de horários possíveis no expediente (ex: 08:00, 10:00, 12:00, 14:00, 16:00), cada um com 2h.
- `WITH dias AS (...)`: Cria os dias da semana (1 a 6, ou seja, segunda a sábado).
- `CROSS JOIN`: Gera todas as combinações de sala, dia e horário possível.
- `WHERE NOT EXISTS (...)`:
   - Para cada combinação, verifica se **não há nenhuma aula agendada** naquele horário, naquele dia e sala.
   - Usa o operador `OVERLAPS` para detectar conflitos de horário (verifica se o bloco livre se sobrepõe a algum horário ocupado).
- `'LIVRE' AS status`: Marca o bloco como livre.
- `ORDER BY ...`: Ordena por sala, dia e horário.

##### Exemplo de resultado

| room_id | room_name | day_of_week | start_time | end_time | status |
|---------|-----------|-------------|------------|----------|--------|
| 1       | A101      | 2           | 10:00      | 12:00    | LIVRE  |
| 1       | A101      | 3           | 08:00      | 10:00    | LIVRE  |
| ...     | ...       | ...         | ...        | ...      | ...    |

---

### 4. Lista de horários livres e ocupados juntos (com status)

```sql
WITH horas AS (
    SELECT 
        (generate_series(
            '2024-01-01 08:00'::timestamp, 
            '2024-01-01 16:00'::timestamp, 
            '2 hour'::interval
        ))::time AS start_time
),
dias AS (
    SELECT generate_series(1, 6) AS day_of_week
)
SELECT
    r.id AS room_id,
    r.name AS room_name,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    'OCUPADO' AS status
FROM
    ROOM r
JOIN CLASS_SCHEDULE cs ON cs.room_id = r.id

UNION ALL

SELECT
    r.id AS room_id,
    r.name AS room_name,
    d.day_of_week,
    h.start_time,
    (h.start_time + interval '2 hour') AS end_time,
    'LIVRE' AS status
FROM
    ROOM r
CROSS JOIN dias d
CROSS JOIN horas h
WHERE NOT EXISTS (
    SELECT 1 FROM CLASS_SCHEDULE cs
    WHERE cs.room_id = r.id
      AND cs.day_of_week = d.day_of_week
      AND (h.start_time, h.start_time + interval '2 hour')
          OVERLAPS (cs.start_time, cs.end_time)
)
ORDER BY
    room_id, day_of_week, start_time, status DESC;
```

#### Explicação detalhada

- Utiliza as mesmas CTEs `horas` e `dias` para gerar horários e dias possíveis. (CTE significa Common Table Expression (ou, em português, "Expressão de Tabela Comum"))
- O primeiro `SELECT ... 'OCUPADO' ...` traz todos os horários ocupados.
- O segundo `SELECT ... 'LIVRE' ...` traz todos os blocos livres (com a mesma lógica da consulta anterior).
- `UNION ALL` une as duas listas em uma só.
- O operador `OVERLAPS` permite identificar se os intervalos de tempo se cruzam.
- O resultado mostra cada horário possível de cada sala, indicando se está livre ou ocupado.
- Ordenação deixa fácil ver a situação por sala, dia e horário.

##### Exemplo de resultado

| room_id | room_name | day_of_week | start_time | end_time | status   |
|---------|-----------|-------------|------------|----------|----------|
| 1       | A101      | 2           | 08:00      | 10:00    | OCUPADO  |
| 1       | A101      | 2           | 10:00      | 12:00    | LIVRE    |
| ...     | ...       | ...         | ...        | ...      | ...      |

---

## Observações

- Os horários livres podem ser ajustados mudando o horário ou intervalo em `generate_series`.
- Dias da semana vão de 1 (segunda) a 6 (sábado).
- Massa de dados, usuários e configurações podem ser adaptados conforme necessidade.

---
