-- DEPARTAMENTO
CREATE TABLE DEPARTMENT (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- TITLE (títulos dos professores)
CREATE TABLE TITLE (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- PROFESSOR
CREATE TABLE PROFESSOR (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INT REFERENCES DEPARTMENT(id),
    title_id INT REFERENCES TITLE(id)
);

-- BUILDING
CREATE TABLE BUILDING (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- ROOM
CREATE TABLE ROOM (
    id SERIAL PRIMARY KEY,
    building_id INT REFERENCES BUILDING(id),
    name VARCHAR(100) NOT NULL
);

-- SUBJECT
CREATE TABLE SUBJECT (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    department_id INT REFERENCES DEPARTMENT(id)
);

-- SUBJECT_PREREQUISITE
CREATE TABLE SUBJECT_PREREQUISITE (
    id SERIAL PRIMARY KEY,
    subject_id INT REFERENCES SUBJECT(id),
    prerequisite_id INT REFERENCES SUBJECT(id)
);

-- CLASS
CREATE TABLE CLASS (
    id SERIAL PRIMARY KEY,
    subject_id INT REFERENCES SUBJECT(id),
    professor_id INT REFERENCES PROFESSOR(id),
    year INT NOT NULL,
    semester INT NOT NULL,
    code VARCHAR(20)
);

-- CLASS_SCHEDULE
CREATE TABLE CLASS_SCHEDULE (
    id SERIAL PRIMARY KEY,
    class_id INT REFERENCES CLASS(id),
    room_id INT REFERENCES ROOM(id),
    day_of_week INT NOT NULL,         -- 1=Domingo ... 7=Sábado
    start_time TIME NOT NULL,
    end_time TIME NOT NULL
);

-- DEPARTMENT
INSERT INTO DEPARTMENT (name) VALUES ('Computação'), ('Matemática');

-- TITLE
INSERT INTO TITLE (name) VALUES ('Doutor'), ('Mestre'), ('Especialista');

-- PROFESSOR
INSERT INTO PROFESSOR (name, department_id, title_id) VALUES
('João Silva', 1, 1),
('Maria Oliveira', 1, 2),
('Carlos Souza', 2, 1),
('Ana Paula', 2, 3);

-- BUILDING
INSERT INTO BUILDING (name) VALUES ('Prédio A'), ('Prédio B');

-- ROOM
INSERT INTO ROOM (building_id, name) VALUES
(1, 'A101'), (1, 'A102'), (2, 'B201'), (2, 'B202');

-- SUBJECT
INSERT INTO SUBJECT (code, name, department_id) VALUES
('COMP101', 'Algoritmos', 1),
('COMP102', 'Estruturas de Dados', 1),
('MATH101', 'Cálculo I', 2),
('MATH102', 'Álgebra Linear', 2);

-- SUBJECT_PREREQUISITE
INSERT INTO SUBJECT_PREREQUISITE (subject_id, prerequisite_id) VALUES
(2, 1), -- Estruturas de Dados precisa de Algoritmos
(4, 3); -- Álgebra Linear precisa de Cálculo I

-- CLASS
INSERT INTO CLASS (subject_id, professor_id, year, semester, code) VALUES
(1, 1, 2024, 1, 'T01'),
(2, 2, 2024, 1, 'T01'),
(3, 3, 2024, 1, 'T01'),
(4, 4, 2024, 1, 'T01');

-- CLASS_SCHEDULE
-- João Silva em Algoritmos (A101 - Segunda 8h às 10h)
INSERT INTO CLASS_SCHEDULE (class_id, room_id, day_of_week, start_time, end_time) VALUES
(1, 1, 2, '08:00', '10:00'),
-- Maria Oliveira em Estruturas de Dados (A102 - Terça 10h às 12h)
(2, 2, 3, '10:00', '12:00'),
-- Carlos Souza em Cálculo I (B201 - Quarta 13h às 15h)
(3, 3, 4, '13:00', '15:00'),
-- Ana Paula em Álgebra Linear (B202 - Quinta 08h às 10h)
(4, 4, 5, '08:00', '10:00');
