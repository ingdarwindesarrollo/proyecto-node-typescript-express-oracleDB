# crear-proyecto.ps1
# ============================================================
# Crea desde cero un proyecto Node.js + TypeScript + Express + Oracle
# Requisitos: Node.js 18+, Docker con Oracle XE en localhost:1521
#
# Uso:
#   .\crear-proyecto.ps1 -Nombre "mi-api-oracle"
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Nombre
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Creando proyecto: $Nombre"                 -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Carpetas ---
Write-Host "--> Creando estructura de carpetas..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$Nombre/src/config"        | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/controllers"   | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/middlewares"   | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/routes"        | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/services"      | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/utils"         | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/logs"              | Out-Null
Set-Location $Nombre

# --- 2. package.json ---
Write-Host "--> Creando package.json..." -ForegroundColor Yellow
@"
{
    "name": "$Nombre",
    "version": "1.0.0",
    "main": "dist/app.js",
    "scripts": {
        "start":   "node dist/app.js",
        "dev":     "nodemon --exec ts-node src/app.ts",
        "build":   "tsc",
        "init-db": "ts-node init-db.ts"
    },
    "dependencies": {
        "cors": "2.8.6",
        "dotenv": "17.3.1",
        "express": "5.2.1",
        "express-validator": "7.3.1",
        "helmet": "8.1.0",
        "oracledb": "6.10.0",
        "winston": "3.19.0"
    },
    "devDependencies": {
        "@types/cors": "^2.8.19",
        "@types/express": "^5.0.6",
        "@types/node": "^25.5.0",
        "@types/oracledb": "^6.10.2",
        "nodemon": "^3.1.14",
        "ts-node": "^10.9.2",
        "typescript": "^5.9.3"
    }
}
"@ | Set-Content "package.json"

# --- 3. tsconfig.json ---
Write-Host "--> Creando tsconfig.json..." -ForegroundColor Yellow
@'
{
    "compilerOptions": {
        "target": "ES2020",
        "module": "commonjs",
        "lib": ["ES2020"],
        "outDir": "./dist",
        "rootDir": "./src",
        "strict": true,
        "esModuleInterop": true,
        "skipLibCheck": true,
        "forceConsistentCasingInFileNames": true,
        "resolveJsonModule": true
    },
    "include": ["src/**/*"],
    "exclude": ["node_modules", "dist"]
}
'@ | Set-Content "tsconfig.json"

# --- 4. .env ---
Write-Host "--> Creando .env..." -ForegroundColor Yellow
@'
DB_USER=system
DB_PASS=123456
DB_CONN=localhost/XEPDB1
'@ | Set-Content ".env"

# --- 5. .gitignore ---
@'
node_modules/
dist/
.env
logs/
'@ | Set-Content ".gitignore"

# --- 6. src/utils/logger.ts ---
Write-Host "--> Creando src/utils/logger.ts..." -ForegroundColor Yellow
@'
import { createLogger, format, transports } from 'winston';

const logger = createLogger({
    level: 'info',
    format: format.combine(
        format.timestamp(),
        format.printf(({ level, message, timestamp }) => {
            return `${timestamp} [${level.toUpperCase()}]: ${message}`;
        })
    ),
    transports: [
        new transports.Console(),
        new transports.File({ filename: 'logs/error.log', level: 'error' }),
        new transports.File({ filename: 'logs/combined.log' })
    ]
});

export default logger;
'@ | Set-Content "src/utils/logger.ts"

# --- 7. src/config/db.ts ---
Write-Host "--> Creando src/config/db.ts..." -ForegroundColor Yellow
@'
import oracledb from 'oracledb';
import dotenv from 'dotenv';

dotenv.config();

export async function initDB(): Promise<void> {
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

export async function getConnection(): Promise<oracledb.Connection> {
    return oracledb.getConnection();
}
'@ | Set-Content "src/config/db.ts"

# --- 8. src/services/user.service.ts ---
Write-Host "--> Creando src/services/user.service.ts..." -ForegroundColor Yellow
@'
import { getConnection } from '../config/db';

export interface User {
    id?: number;
    name: string;
    email: string;
}

export async function getAll(): Promise<unknown[]> {
    const conn = await getConnection();
    const result = await conn.execute(`SELECT * FROM users`);
    await conn.close();
    return result.rows ?? [];
}

export async function getById(id: number): Promise<unknown> {
    const conn = await getConnection();
    const result = await conn.execute(
        `SELECT * FROM users WHERE id = :id`,
        { id }
    );
    await conn.close();
    return result.rows?.[0];
}

export async function create(user: User): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `INSERT INTO users (name, email) VALUES (:name, :email)`,
        user as unknown as Record<string, string | number | undefined>,
        { autoCommit: true }
    );
    await conn.close();
}

export async function update(id: number, user: Partial<User>): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `UPDATE users SET name=:name, email=:email WHERE id=:id`,
        { ...user, id } as Record<string, string | number | undefined>,
        { autoCommit: true }
    );
    await conn.close();
}

export async function remove(id: number): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `DELETE FROM users WHERE id=:id`,
        { id },
        { autoCommit: true }
    );
    await conn.close();
}
'@ | Set-Content "src/services/user.service.ts"

# --- 9. src/controllers/user.controllers.ts ---
Write-Host "--> Creando src/controllers/user.controllers.ts..." -ForegroundColor Yellow
@'
import { Request, Response, NextFunction } from 'express';
import * as service from '../services/user.service';

export const getAll = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        res.json(await service.getAll());
    } catch (err) { next(err); }
};

export const getOne = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const data = await service.getById(Number(req.params.id));
        if (!data) {
            const error = new Error('Usuario no existe') as Error & { status: number };
            error.status = 404;
            next(error);
            return;
        }
        res.json(data);
    } catch (err) { next(err); }
};

export const create = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        await service.create(req.body);
        res.status(201).json({ message: 'Creado' });
    } catch (err) { next(err); }
};

export const update = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        await service.update(Number(req.params.id), req.body);
        res.json({ message: 'Actualizado' });
    } catch (err) { next(err); }
};

export const remove = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        await service.remove(Number(req.params.id));
        res.json({ message: 'Eliminado' });
    } catch (err) { next(err); }
};
'@ | Set-Content "src/controllers/user.controllers.ts"

# --- 10. src/middlewares/error.middleware.ts ---
Write-Host "--> Creando src/middlewares/error.middleware.ts..." -ForegroundColor Yellow
@'
import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';

interface AppError extends Error {
    status?: number;
}

function errorHandler(err: AppError, req: Request, res: Response, _next: NextFunction): void {
    let message = err.message;
    let status = err.status ?? 500;

    if (err.message.includes('ORA-00001')) {
        message = 'Registro duplicado';
        status = 400;
    }
    if (err.message.includes('ORA-00942')) {
        message = 'Tabla no existe';
        status = 500;
    }
    if (err.message.includes('ORA-02291')) {
        message = 'Violacion de clave foranea';
        status = 400;
    }

    logger.error(`${req.method} ${req.url} - ${message}`);

    res.status(status).json({
        success: false,
        message
    });
}

export default errorHandler;
'@ | Set-Content "src/middlewares/error.middleware.ts"

# --- 11. src/middlewares/user.validator.ts ---
Write-Host "--> Creando src/middlewares/user.validator.ts..." -ForegroundColor Yellow
@'
import { body, ValidationChain } from 'express-validator';

export const createUserValidator: ValidationChain[] = [
    body('name')
        .notEmpty().withMessage('Nombre requerido')
        .isLength({ min: 3 }).withMessage('Minimo 3 caracteres'),

    body('email')
        .isEmail().withMessage('Email invalido')
];
'@ | Set-Content "src/middlewares/user.validator.ts"

# --- 12. src/middlewares/validate.ts ---
Write-Host "--> Creando src/middlewares/validate.ts..." -ForegroundColor Yellow
@'
import { Request, Response, NextFunction } from 'express';
import { validationResult } from 'express-validator';

function validate(req: Request, res: Response, next: NextFunction): void {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
        res.status(400).json({
            success: false,
            errors: errors.array()
        });
        return;
    }

    next();
}

export default validate;
'@ | Set-Content "src/middlewares/validate.ts"

# --- 13. src/routes/user.routes.ts ---
Write-Host "--> Creando src/routes/user.routes.ts..." -ForegroundColor Yellow
@'
import { Router } from 'express';
import * as c from '../controllers/user.controllers';
import validate from '../middlewares/validate';
import { createUserValidator } from '../middlewares/user.validator';

const router = Router();

router.get('/',    c.getAll);
router.get('/:id', c.getOne);

router.post(
    '/',
    createUserValidator,
    validate,
    c.create
);

router.put('/:id',    c.update);
router.delete('/:id', c.remove);

export default router;
'@ | Set-Content "src/routes/user.routes.ts"

# --- 14. src/app.ts ---
Write-Host "--> Creando src/app.ts..." -ForegroundColor Yellow
@'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { initDB } from './config/db';
import userRoutes from './routes/user.routes';
import errorHandler from './middlewares/error.middleware';

const app = express();

app.use(cors());
app.use(helmet());
app.use(express.json());

app.use('/api/users', userRoutes);

initDB();

app.listen(3000, () => {
    console.log('Servidor en http://localhost:3000');
});

app.use(errorHandler);
'@ | Set-Content "src/app.ts"

# --- 15. init-db.ts ---
Write-Host "--> Creando init-db.ts..." -ForegroundColor Yellow
@'
import oracledb from 'oracledb';

async function init(): Promise<void> {
    let conn: oracledb.Connection | undefined;
    try {
        conn = await oracledb.getConnection({
            user: 'system',
            password: '123456',
            connectString: 'localhost/XEPDB1'
        });
        console.log('Conectado a Oracle');

        await conn.execute(`
            BEGIN
                EXECUTE IMMEDIATE '
                    CREATE TABLE users (
                        id    NUMBER GENERATED ALWAYS AS IDENTITY,
                        name  VARCHAR2(100),
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
'@ | Set-Content "init-db.ts"

# --- 16. Instalar dependencias ---
Write-Host ""
Write-Host "--> Instalando dependencias npm (puede tardar 1-2 minutos)..." -ForegroundColor Yellow
npm install

# --- 17. Crear tablas en Oracle ---
Write-Host ""
Write-Host "--> Creando tablas en Oracle..." -ForegroundColor Yellow
npm run init-db

# --- Resumen final ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  PROYECTO CREADO EXITOSAMENTE"              -ForegroundColor Green
Write-Host "  Carpeta: $Nombre"                          -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Comandos disponibles:" -ForegroundColor Yellow
Write-Host "    npm run dev    -> desarrollo (recarga automatica)" -ForegroundColor White
Write-Host "    npm run build  -> compila TypeScript a dist/"      -ForegroundColor White
Write-Host "    npm start      -> produccion (usa dist/)"          -ForegroundColor White
Write-Host "    npm run init-db -> (re)crea las tablas en Oracle"  -ForegroundColor White
Write-Host ""
Write-Host "  API disponible en: http://localhost:3000/api/users" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Para arrancar ahora:" -ForegroundColor Yellow
Write-Host "    npm run dev" -ForegroundColor White
Write-Host ""
