import oracledb from 'oracledb';

async function init(): Promise<void> {
    let conn: oracledb.Connection | undefined;
    try {
        conn = await oracledb.getConnection({
            user: 'system',
            password: '123456',
            connectString: 'localhost/XEPDB1'
        });
        console.log('Conectado');

        await conn.execute(`
            BEGIN
                EXECUTE IMMEDIATE '
                    CREATE TABLE users (
                        id NUMBER GENERATED ALWAYS AS IDENTITY,
                        name VARCHAR2(100),
                        email VARCHAR2(100),
                        PRIMARY KEY (id)
                    )
                ';
            EXCEPTION
                WHEN OTHERS THEN
                    IF SQLCODE != -955 THEN RAISE; END IF;
            END;
        `);
        console.log('Tabla users lista');
    } catch (err) {
        console.error(err);
    } finally {
        if (conn) await conn.close();
    }
}

init();
