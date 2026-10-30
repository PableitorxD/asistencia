CREATE DATABASE IF NOT EXISTS globomatics;
USE globomatics;

CREATE TABLE IF NOT EXISTS tareas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    completada BOOLEAN DEFAULT FALSE
);

-- Datos de ejemplo iniciales (opcional)
INSERT INTO tareas (titulo, completada) VALUES ('Base de datos inicializada por cloud-init', true);
INSERT INTO tareas (titulo, completada) VALUES ('Servidor aprovisionado con Infraestructura como Codigo', true);