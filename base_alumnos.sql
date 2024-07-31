DROP DATABASE IF EXISTS gestion_alumnos;
CREATE DATABASE gestion_alumnos;
USE gestion_alumnos;

-- Creación de tablas
CREATE TABLE departamentos (
    departamento_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

CREATE TABLE grados (
    grado_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

CREATE TABLE estudiantes (
    estudiante_id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15),
    direccion VARCHAR(255),
    ciudad VARCHAR(100),
    estado VARCHAR(100),
    codigo_postal VARCHAR(10),
    fecha_inscripcion DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profesores (
    profesor_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15),
    departamento_id INT,
    FOREIGN KEY (departamento_id) REFERENCES departamentos(departamento_id)
);

CREATE TABLE cursos (
    curso_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    creditos INT NOT NULL,
    departamento_id INT,
    FOREIGN KEY (departamento_id) REFERENCES departamentos(departamento_id)
);

CREATE TABLE inscripciones (
    inscripcion_id INT AUTO_INCREMENT PRIMARY KEY,
    estudiante_id INT,
    curso_id INT,
    fecha_inscripcion DATETIME DEFAULT CURRENT_TIMESTAMP,
    calificacion DECIMAL(4,2),
    FOREIGN KEY (estudiante_id) REFERENCES estudiantes(estudiante_id),
    FOREIGN KEY (curso_id) REFERENCES cursos(curso_id)
);

-- Inserción de datos de ejemplo
INSERT INTO departamentos (nombre, descripcion) VALUES
('Matemáticas', 'Departamento de Matemáticas'),
('Ciencias', 'Departamento de Ciencias'),
('Humanidades', 'Departamento de Humanidades');

INSERT INTO grados (nombre, descripcion) VALUES
('Licenciatura', 'Grado de Licenciatura'),
('Maestría', 'Grado de Maestría'),
('Doctorado', 'Grado de Doctorado');

INSERT INTO estudiantes (estudiante_id, nombre, apellido, fecha_nacimiento, email, telefono, direccion, ciudad, estado, codigo_postal) VALUES
(1, 'Juan', 'Pérez', '1995-01-01', 'juan.perez@example.com', '555-1234', 'Calle Falsa 123', 'Ciudad', 'Estado', '12345'),
(2, 'María', 'González', '1993-03-15', 'maria.gonzalez@example.com', '555-5678', 'Avenida Siempre Viva 456', 'Ciudad', 'Estado', '54321');

INSERT INTO profesores (nombre, apellido, email, telefono, departamento_id) VALUES
('Carlos', 'Martínez', 'carlos.martinez@example.com', '555-9876', 1),
('Ana', 'López', 'ana.lopez@example.com', '555-6543', 2);

INSERT INTO cursos (nombre, descripcion, creditos, departamento_id) VALUES
('Álgebra', 'Curso de Álgebra Básica', 5, 1),
('Física', 'Curso de Física General', 4, 2),
('Literatura', 'Introducción a la Literatura', 3, 3);

INSERT INTO inscripciones (estudiante_id, curso_id, calificacion) VALUES
(1, 1, 8.5),
(1, 2, 7.0),
(2, 3, 9.0);

-- Cambiar delimitador para definir funciones almacenadas
DELIMITER //

-- Funciones almacenadas
CREATE FUNCTION obtener_promedio_calificaciones(estudiante_id INT) RETURNS DECIMAL(4, 2)
BEGIN
    DECLARE promedio DECIMAL(4, 2);
    SELECT AVG(calificacion) INTO promedio
    FROM inscripciones
    WHERE estudiante_id = estudiante_id;
    RETURN IFNULL(promedio, 0);
END//

CREATE FUNCTION obtener_cantidad_cursos_profesor(profesor_id INT) RETURNS INT
BEGIN
    DECLARE cantidad INT;
    SELECT COUNT(*) INTO cantidad
    FROM cursos
    WHERE departamento_id = (SELECT departamento_id FROM profesores WHERE profesor_id = profesor_id);
    RETURN cantidad;
END//

-- Vistas
CREATE VIEW resumen_estudiantes_inscripciones AS
SELECT e.estudiante_id, e.nombre AS estudiante_nombre, e.apellido AS estudiante_apellido,
       c.nombre AS curso_nombre, i.calificacion
FROM estudiantes e
JOIN inscripciones i ON e.estudiante_id = i.estudiante_id
JOIN cursos c ON i.curso_id = c.curso_id;

CREATE VIEW cursos_por_departamento AS
SELECT d.nombre AS departamento_nombre, c.nombre AS curso_nombre, c.creditos
FROM departamentos d
JOIN cursos c ON d.departamento_id = c.departamento_id;

-- Procedimientos Almacenados
CREATE PROCEDURE inscribir_estudiante(
    IN p_estudiante_id INT,
    IN p_curso_id INT
)
BEGIN
    INSERT INTO inscripciones (estudiante_id, curso_id) VALUES (p_estudiante_id, p_curso_id);
END//

CREATE PROCEDURE actualizar_calificacion(
    IN p_estudiante_id INT,
    IN p_curso_id INT,
    IN p_calificacion DECIMAL(4,2)
)
BEGIN
    UPDATE inscripciones
    SET calificacion = p_calificacion
    WHERE estudiante_id = p_estudiante_id AND curso_id = p_curso_id;
END//

-- Trigger para actualizar el estado de los estudiantes a "graduado" después de una inserción
CREATE TRIGGER actualizar_estado_graduado_insert
AFTER INSERT ON inscripciones
FOR EACH ROW
BEGIN
    DECLARE cursos_completados INT;
    
    -- Contar el número de cursos con calificación >= 6 para el estudiante
    SELECT COUNT(*)
    INTO cursos_completados
    FROM inscripciones
    WHERE estudiante_id = NEW.estudiante_id AND calificacion >= 6;
    
    -- Si el estudiante ha completado 5 o más cursos, actualizar su estado a "graduado"
    IF cursos_completados >= 5 THEN
        UPDATE estudiantes
        SET estado = 'graduado'
        WHERE estudiante_id = NEW.estudiante_id;
    END IF;
END//

-- Trigger para actualizar el estado de los estudiantes a "graduado" después de una actualización
CREATE TRIGGER actualizar_estado_graduado_update
AFTER UPDATE ON inscripciones
FOR EACH ROW
BEGIN
    DECLARE cursos_completados INT;
    
    -- Contar el número de cursos con calificación >= 6 para el estudiante
    SELECT COUNT(*)
    INTO cursos_completados
    FROM inscripciones
    WHERE estudiante_id = NEW.estudiante_id AND calificacion >= 6;
    
    -- Si el estudiante ha completado 5 o más cursos, actualizar su estado a "graduado"
    IF cursos_completados >= 5 THEN
        UPDATE estudiantes
        SET estado = 'graduado'
        WHERE estudiante_id = NEW.estudiante_id;
    END IF;
END//

-- Restaurar delimitador predeterminado
DELIMITER ;
