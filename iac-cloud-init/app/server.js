const express = require('express');
const mariadb = require('mariadb');
const path = require('path');
const os = require('os');

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const pool = mariadb.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'globo',
    password: process.env.DB_PASSWORD || 'secreto123',
    database: process.env.DB_NAME || 'globomatics',
    connectionLimit: 5
});

// Endpoint para obtener tareas y estado
app.get('/api/tareas', async (req, res) => {
    let conn;
    try {
        conn = await pool.getConnection();
        const rows = await conn.query("SELECT * FROM tareas");
        res.json({
            servidor: os.hostname(),
            ambiente: process.env.AMBIENTE || 'dev',
            baseDatos: process.env.DB_HOST || 'localhost',
            tareas: rows
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        if (conn) conn.release();
    }
});

// Endpoint para agregar tareas
app.post('/api/tareas', async (req, res) => {
    let conn;
    try {
        conn = await pool.getConnection();
        const { titulo } = req.body;
        await conn.query("INSERT INTO tareas (titulo, completada) VALUES (?, ?)", [titulo, false]);
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        if (conn) conn.release();
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor corriendo en puerto ${PORT}`);
});