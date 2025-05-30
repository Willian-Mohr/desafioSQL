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
    trunc(SUM(EXTRACT(EPOCH FROM (cs.end_time - cs.start_time)) / 3600), 2) AS total_hours
FROM 
    professor p
JOIN subject s ON s.id IN (
    SELECT subject_id 
    FROM class 
    WHERE subject_id = s.id
)
JOIN class c ON c.subject_id = s.id
JOIN class_schedule cs ON cs.class_id = c.id
GROUP BY 
    p.id;
```

#### Explicação detalhada

- `p.id AS professor_id`: Retorna o ID do professor.
- `cs.end_time - cs.start_time`: Calcula a duração da aula.
- `EXTRACT(EPOCH FROM (...))`: Converte a duração para segundos.
- `... / 3600`: Converte segundos para horas.
- `SUM(...)`: Soma todas as durações de aulas associadas a cada professor.
- `JOIN subject s ON s.id IN (
  SELECT subject_id
  FROM class
  WHERE subject_id = s.id
  )`: O filtro está dizendo "junte o subject com ele mesmo se ele existir em class" — o que é redundante, pois já está em uso.
- `JOIN class c ON c.subject_id = s.id`: Relaciona disciplinas (subject) com suas ofertas de aula (class).
- `JOIN class_schedule cs ON cs.class_id = c.id`: Junta a tabela de horários para obter o tempo de aula real.
- `GROUP BY p.id`: Agrupa por professor.

##### Exemplo de resultado

| professor_id | total_hours |
|--------------|-------------|
| 1            | 4           |
| 2            | 2           |
| ...          | ...         |

---

### 2. Lista de horários ocupados por sala

```sql
SELECT 
  r.id AS room_id,
  cs.day_of_week,
  cs.start_time,
  cs.end_time,
  'ocupado' AS status
FROM 
  room r
JOIN class_schedule cs ON cs.room_id = r.id;
```

#### Explicação detalhada

- `r.id AS room_id`: Exibe o ID da sala.
- `JOIN class_schedule cs ON cs.room_id = r.id`: Junta todos os horários já ocupados daquela sala.
- `cs.day_of_week`: Indica o dia da semana em que a sala está ocupada (1 = segunda, 2 = terça, etc).
- `cs.start_time, cs.end_time`: Horário de início e fim do uso da sala.
- `'OCUPADO' AS status`: Marca a linha como OCUPADO.

##### Exemplo de resultado

| room_id | day_of_week | start_time | end_time | status   |
|---------|-------------|------------|----------|----------|
| 1       | 2           | 08:00      | 10:00    | OCUPADO  |
| 2       | 3           | 10:00      | 12:00    | OCUPADO  |
| ...     | ...         | ...        | ...      | ...      |

---

### 3. Lista de horários livres por sala

```sql
WITH horarios AS (
  SELECT 
    r.id AS room_id,
    d.dia AS day_of_week,
    h.horario_inicio AS start_time,
    h.horario_fim AS end_time
  FROM 
    room r,
    (VALUES ('Monday'), ('Tuesday'), ('Wednesday'), ('Thursday'), ('Friday')) AS d(dia),
    (VALUES 
      ('08:00'::time, '10:00'::time),
      ('10:00'::time, '12:00'::time),
      ('12:00'::time, '14:00'::time),
      ('14:00'::time, '16:00'::time),
      ('16:00'::time, '18:00'::time)
    ) AS h(horario_inicio, horario_fim)
),
ocupados AS (
  SELECT 
    room_id,
    day_of_week,
    start_time,
    end_time
  FROM class_schedule
)
SELECT 
  h.room_id,
  h.day_of_week,
  h.start_time,
  h.end_time,
  'livre' AS status
FROM horarios h
LEFT JOIN ocupados o ON 
  h.room_id = o.room_id AND 
  h.day_of_week = o.day_of_week AND 
  h.start_time = o.start_time AND 
  h.end_time = o.end_time
WHERE o.room_id IS NULL;
```

#### Explicação detalhada

- Essa consulta utiliza duas CTEs (Common Table Expressions): `horarios:` gera todos os horários possíveis para cada sala, de segunda a sexta  `ocupados:` pega os horários efetivamente utilizados conforme a tabela class_schedule.
- Depois faz um LEFT JOIN para filtrar os horários que não aparecem como ocupados.
- Primeira CTE – horarios: 
```sql 
WITH horarios AS (
  SELECT 
    r.id AS room_id,
    d.dia AS day_of_week,
    h.horario_inicio AS start_time,
    h.horario_fim AS end_time
  FROM 
    room r,
    (VALUES ('Monday'), ('Tuesday'), ('Wednesday'), ('Thursday'), ('Friday')) AS d(dia),
    (VALUES 
      ('08:00'::time, '10:00'::time),
      ('10:00'::time, '12:00'::time),
      ('12:00'::time, '14:00'::time),
      ('14:00'::time, '16:00'::time),
      ('16:00'::time, '18:00'::time)
    ) AS h(horario_inicio, horario_fim)
)
```
O que faz: Gera uma combinação cartesiana entre:
- Todas as salas (room r)
- Todos os dias úteis (segunda a sexta)
- Todos os blocos horários de 2 horas (das 08h às 18h)

Resultado:
- Você terá uma tabela horarios contendo todas as combinações possíveis de sala + dia da semana + horário padrão.

- Segunda CTE – horarios:
```sql 
ocupados AS (
  SELECT 
    room_id,
    day_of_week,
    start_time,
    end_time
  FROM class_schedule
)
```
O que faz: Simplesmente traz todos os horários que estão ocupados conforme class_schedule.

- Consulta final – encontrar os livres
```sql 
SELECT 
  h.room_id,
  h.day_of_week,
  h.start_time,
  h.end_time,
  'livre' AS status
FROM horarios h
LEFT JOIN ocupados o ON 
  h.room_id = o.room_id AND 
  h.day_of_week = o.day_of_week AND 
  h.start_time = o.start_time AND 
  h.end_time = o.end_time
WHERE o.room_id IS NULL;
```
O que faz: 
- Tenta juntar cada horário possível (de horarios) com os horários ocupados (ocupados).
- Onde não houver correspondência (o.room_id IS NULL), quer dizer que aquele bloco está livre.

Resultado:
- A consulta retorna apenas os horários livres, já que os ocupados são descartados com o WHERE.


##### Exemplo de resultado

| room_id | day_of_week | start_time | end_time | status |
|---------|-------------|------------|----------|--------|
| 1       | 2           | 10:00      | 12:00    | LIVRE  |
| 1       | 3           | 08:00      | 10:00    | LIVRE  |
| ...     | ...         | ...        | ...      | ...    |

---

## Observações

- Os horários livres podem ser ajustados mudando o horário ou intervalo em `WITH horarios`.
- Dias da semana vão de 1 (segunda) a 5 (sexta).
- Massa de dados, usuários e configurações podem ser adaptados conforme necessidade.

---
