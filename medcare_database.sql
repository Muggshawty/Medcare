-- ============================================================
--  MedCare – Banco de Dados Relacional
--  Banco: PostgreSQL
--  Criado para: Gestão de Clínicas MedCare
-- ============================================================


-- ============================================================
--  [DDL] CRIAÇÃO DAS TABELAS
-- ============================================================

-- 1. Especialidades
CREATE TABLE especialidades (
    id   SERIAL       PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE
);

-- 2. Médicos
CREATE TABLE medicos (
    id               SERIAL          PRIMARY KEY,
    especialidade_id INTEGER         NOT NULL,
    nome             VARCHAR(150)    NOT NULL,
    crm              VARCHAR(20)     NOT NULL UNIQUE,
    valor_consulta   NUMERIC(10, 2)  NOT NULL CHECK (valor_consulta > 0),
    CONSTRAINT fk_medico_especialidade
        FOREIGN KEY (especialidade_id) REFERENCES especialidades(id)
);

-- 3. Pacientes
CREATE TABLE pacientes (
    id               SERIAL       PRIMARY KEY,
    nome             VARCHAR(150) NOT NULL,
    email            VARCHAR(200) NOT NULL UNIQUE,
    cpf              CHAR(11)     NOT NULL UNIQUE
                                  CHECK (LENGTH(cpf) = 11),
    data_nascimento  DATE         NOT NULL,
    data_cadastro    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 4. Consultas
CREATE TABLE consultas (
    id          SERIAL       PRIMARY KEY,
    medico_id   INTEGER      NOT NULL,
    paciente_id INTEGER      NOT NULL,
    data_hora   TIMESTAMPTZ  NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'Agendada'
                             CHECK (status IN ('Agendada', 'Realizada', 'Cancelada')),
    CONSTRAINT fk_consulta_medico
        FOREIGN KEY (medico_id)   REFERENCES medicos(id),
    CONSTRAINT fk_consulta_paciente
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
);

-- 5. Exames da Consulta (tabela associativa)
CREATE TABLE exames_consulta (
    id          SERIAL         PRIMARY KEY,
    consulta_id INTEGER        NOT NULL,
    nome_exame  VARCHAR(200)   NOT NULL,
    valor_exame NUMERIC(10, 2) NOT NULL CHECK (valor_exame >= 0),
    CONSTRAINT fk_exame_consulta
        FOREIGN KEY (consulta_id) REFERENCES consultas(id)
);


-- ============================================================
--  [DML] CARGA DE DADOS INICIAIS
-- ============================================================

-- Especialidades
INSERT INTO especialidades (nome) VALUES
    ('Cardiologia'),
    ('Pediatria'),
    ('Dermatologia');

-- Médicos
INSERT INTO medicos (especialidade_id, nome, crm, valor_consulta) VALUES
    (1, 'Dr. Roberto Alves',  'CRM-SP-12345', 450.00),
    (2, 'Dra. Fernanda Lima', 'CRM-RJ-67890', 320.00),
    (3, 'Dr. Paulo Mendes',   'CRM-MG-11223', 280.00);

-- Pacientes
INSERT INTO pacientes (nome, email, cpf, data_nascimento) VALUES
    ('Carlos Silva',   'carlos.silva@email.com',   '12345678901', '1985-03-15'),
    ('Ana Souza',      'ana.souza@email.com',       '98765432100', '1992-07-22'),
    ('Bruno Ferreira', 'bruno.ferreira@email.com',  '11122233344', '1978-11-05');

-- Consultas
INSERT INTO consultas (medico_id, paciente_id, data_hora, status) VALUES
    (1, 1, '2025-08-10 09:00:00-03', 'Realizada'),   -- Carlos / Roberto / Cardiologia
    (2, 1, '2025-08-20 14:30:00-03', 'Agendada'),    -- Carlos / Fernanda / Pediatria
    (3, 2, '2025-08-15 10:00:00-03', 'Realizada'),   -- Ana    / Paulo   / Dermatologia
    (1, 3, '2025-08-25 16:00:00-03', 'Cancelada');   -- Bruno  / Roberto / Cardiologia

-- Exames (vinculados às consultas 1 e 3)
INSERT INTO exames_consulta (consulta_id, nome_exame, valor_exame) VALUES
    (1, 'Eletrocardiograma',  150.00),
    (1, 'Hemograma Completo',  80.00),
    (3, 'Teste do Pezinho',    60.00),
    (3, 'Ultrassonografia',   200.00);


-- ============================================================
--  [DQL] RELATÓRIOS ESTRATÉGICOS
-- ============================================================

-- Q1: Médicos ordenados pelo valor da consulta (mais caro → mais barato)
-- Exibe: nome do médico, CRM, especialidade e valor da consulta
SELECT
    m.nome                          AS medico,
    m.crm,
    e.nome                          AS especialidade,
    m.valor_consulta
FROM medicos m
JOIN especialidades e ON e.id = m.especialidade_id
ORDER BY m.valor_consulta DESC;

/*
 Resultado esperado:
 medico               | crm           | especialidade | valor_consulta
 Dr. Roberto Alves    | CRM-SP-12345  | Cardiologia   | 450.00
 Dra. Fernanda Lima   | CRM-RJ-67890  | Pediatria     | 320.00
 Dr. Paulo Mendes     | CRM-MG-11223  | Dermatologia  | 280.00
*/


-- Q2: Todas as consultas do paciente "Carlos Silva"
-- Exibe: ID da consulta, data/hora, médico, especialidade e status
SELECT
    c.id                            AS consulta_id,
    c.data_hora,
    m.nome                          AS medico,
    e.nome                          AS especialidade,
    c.status
FROM consultas c
JOIN medicos m       ON m.id = c.medico_id
JOIN especialidades e ON e.id = m.especialidade_id
JOIN pacientes p     ON p.id = c.paciente_id
WHERE p.nome = 'Carlos Silva'
ORDER BY c.data_hora;

/*
 Resultado esperado:
 consulta_id | data_hora            | medico             | especialidade | status
 1           | 2025-08-10 09:00...  | Dr. Roberto Alves  | Cardiologia   | Realizada
 2           | 2025-08-20 14:30...  | Dra. Fernanda Lima | Pediatria     | Agendada
*/


-- Q3: Valor total por consulta (valor da consulta + soma dos exames)
-- Exibe: ID da consulta, paciente, médico e valor total calculado
SELECT
    c.id                                                    AS consulta_id,
    p.nome                                                  AS paciente,
    m.nome                                                  AS medico,
    m.valor_consulta + COALESCE(SUM(ex.valor_exame), 0)    AS valor_total
FROM consultas c
JOIN pacientes p          ON p.id = c.paciente_id
JOIN medicos m            ON m.id = c.medico_id
LEFT JOIN exames_consulta ex ON ex.consulta_id = c.id
GROUP BY
    c.id,
    p.nome,
    m.nome,
    m.valor_consulta
ORDER BY c.id;

/*
 Resultado esperado:
 consulta_id | paciente        | medico             | valor_total
 1           | Carlos Silva    | Dr. Roberto Alves  | 680.00   (450 + 150 + 80)
 2           | Carlos Silva    | Dra. Fernanda Lima | 320.00   (320 + 0)
 3           | Ana Souza       | Dr. Paulo Mendes   | 540.00   (280 + 60 + 200)
 4           | Bruno Ferreira  | Dr. Roberto Alves  | 450.00   (450 + 0)
*/


-- Q4: Médicos com valor de consulta superior a R$ 300,00
SELECT
    m.nome                          AS medico,
    m.crm,
    e.nome                          AS especialidade,
    m.valor_consulta
FROM medicos m
JOIN especialidades e ON e.id = m.especialidade_id
WHERE m.valor_consulta > 300.00
ORDER BY m.valor_consulta DESC;

/*
 Resultado esperado:
 medico              | crm           | especialidade | valor_consulta
 Dr. Roberto Alves   | CRM-SP-12345  | Cardiologia   | 450.00
 Dra. Fernanda Lima  | CRM-RJ-67890  | Pediatria     | 320.00
*/


-- Q5: Total faturado por especialidade (apenas consultas 'Realizada')
-- Considera: valor da consulta + exames de cada consulta realizada
SELECT
    e.nome                                                       AS especialidade,
    SUM(m.valor_consulta + COALESCE(ex.total_exames, 0))         AS total_faturado
FROM consultas c
JOIN medicos m        ON m.id = c.medico_id
JOIN especialidades e ON e.id = m.especialidade_id
LEFT JOIN (
    SELECT consulta_id, SUM(valor_exame) AS total_exames
    FROM exames_consulta
    GROUP BY consulta_id
) ex ON ex.consulta_id = c.id
WHERE c.status = 'Realizada'
GROUP BY e.nome
ORDER BY total_faturado DESC;

/*
 Resultado esperado:
 especialidade  | total_faturado
 Cardiologia    | 680.00
 Dermatologia   | 540.00
*/
