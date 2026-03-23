const { getConnection } = require('../config/db');

async function getAll() {
    const conn = await getConnection();
    const res = await conn.execute(`SELECT * FROM users`);
    await conn.close();
    return res.rows;
}

async function getById(id) {
    const conn = await getConnection();
    const res = await conn.execute(
        `SELECT * FROM users WHERE id = :id`,
        { id }
    );
    await conn.close();
    return res.rows[0];
}

async function create(user) {
    const conn = await getConnection();
    await conn.execute(
        `INSERT INTO users (name, email) VALUES (:name, :email)`,
        user,
        { autoCommit: true }
    );
    await conn.close();
}

async function update(id, user) {
    const conn = await getConnection();
    await conn.execute(
        `UPDATE users SET name=:name, email=:email WHERE id=:id`,
        { ...user, id },
        { autoCommit: true }
    );
    await conn.close();
}

async function remove(id) {
    const conn = await getConnection();
    await conn.execute(
        `DELETE FROM users WHERE id=:id`,
        { id },
        { autoCommit: true }
    );
    await conn.close();
}

module.exports = { getAll, getById, create, update, remove };
