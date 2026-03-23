const oracledb = require('oracledb');
require('dotenv').config();

async function initDB() {
    try {
        await oracledb.createPool({
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            connectString: process.env.DB_CONN,
            poolMin: 1,
            poolMax: 5
        });
        console.log('Oracle conectado');
    } catch (err) {
        console.error(err);
    }
}

async function getConnection() {
    return await oracledb.getConnection();
}

module.exports = { initDB, getConnection };
