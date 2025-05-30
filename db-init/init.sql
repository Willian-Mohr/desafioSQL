-- Criação de tabelas

CREATE TABLE department (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE title (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE professor (
    id SERIAL PRIMARY KEY,
    department_id INTEGER REFERENCES department(id),
    title_id INTEGER REFERENCES title(id)
);

CREATE TABLE subject (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE subject_prerequisite (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER REFERENCES subject(id),
    prerequisiteid INTEGER REFERENCES subject(id)
);

CREATE TABLE class (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER REFERENCES subject(id),
    year INTEGER,
    semester VARCHAR(10),
    code VARCHAR(20)
);

CREATE TABLE building (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE room (
    id SERIAL PRIMARY KEY,
    building_id INTEGER REFERENCES building(id)
);

CREATE TABLE class_schedule (
    id SERIAL PRIMARY KEY,
    class_id INTEGER REFERENCES class(id),
    room_id INTEGER REFERENCES room(id),
    day_of_week VARCHAR(10),
    start_time TIME,
    end_time TIME
);

-- Massa de dados

INSERT INTO department (name) VALUES ('Matemática'), ('Computação'), ('Física');

INSERT INTO title (name) VALUES ('Doutor'), ('Mestre');

INSERT INTO professor (department_id, title_id)
VALUES (1, 1), (2, 2);

INSERT INTO subject (subject_id, code, name)
VALUES (1, 'MAT101', 'Cálculo I'),
       (2, 'CSC101', 'Introdução à Programação'),
       (3, 'FIS101', 'Física I');

INSERT INTO subject_prerequisite (subject_id, prerequisiteid)
VALUES (3, 1);

INSERT INTO class (subject_id, year, semester, code)
VALUES (1, 2024, '1', 'C1-2024'),
       (2, 2024, '1', 'IP1-2024'),
       (3, 2024, '2', 'F1-2024'),
       (1, 2024, '1', 'C1-2024B'),
       (2, 2024, '1', 'IP1-2024B');

INSERT INTO building (name) VALUES ('Bloco A'), ('Bloco B');

INSERT INTO room (building_id)
VALUES (1), (2);

INSERT INTO class_schedule (class_id, room_id, day_of_week, start_time, end_time)
VALUES (1, 1, 'Monday', '08:00', '10:00'),
       (2, 2, 'Wednesday', '10:00', '12:00'),
       (1, 1, 'Monday', '10:00', '12:00'),
       (2, 1, 'Tuesday', '08:00', '10:00'),
       (3, 2, 'Wednesday', '14:00', '16:00'),
       (2, 2, 'Thursday', '16:00', '18:00');
