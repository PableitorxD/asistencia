CREATE DATABASE IF NOT EXISTS globomatics;
USE globomatics;

CREATE TABLE IF NOT EXISTS tareas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    completada BOOLEAN NOT NULL DEFAULT FALSE,
    creada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO tareas (id, titulo, completada) VALUES 
(1, 'Base de datos inicializada por cloud-init', TRUE),
(2, 'Servidor aprovisionado con Infraestructura como Codigo', TRUE),
(3, 'Agregar una tarea nueva desde la pagina', FALSE);