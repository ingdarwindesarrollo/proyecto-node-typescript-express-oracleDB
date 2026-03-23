# Guía Técnica Completa — API REST con Node.js · TypeScript · Express · Oracle

> **Para quién es esta guía:** Desarrolladores que comienzan desde cero.  
> **Objetivo:** Construir y entender completamente una API REST profesional con Node.js, TypeScript, Express y Oracle Database (corriendo en Docker), paso a paso, línea por línea.

---

## Tabla de Contenidos

1. [Requisitos previos](#1-requisitos-previos)
2. [Oracle en Docker — paso a paso](#2-oracle-en-docker--paso-a-paso)
3. [Qué es cada tecnología y por qué se usa](#3-qué-es-cada-tecnología-y-por-qué-se-usa)
4. [Estructura del proyecto](#4-estructura-del-proyecto)
5. [Inicializar el proyecto y dependencias](#5-inicializar-el-proyecto-y-dependencias)
6. [Archivo `.env`](#6-archivo-env)
7. [Archivo `tsconfig.json` — línea por línea](#7-archivo-tsconfigjson--línea-por-línea)
8. [Archivo `package.json` — línea por línea](#8-archivo-packagejson--línea-por-línea)
9. [Código fuente — cada archivo línea por línea](#9-código-fuente--cada-archivo-línea-por-línea)
   - [src/utils/logger.ts](#srcutilsloggerts)
   - [src/config/db.ts](#srcconfigdbts)
   - [src/services/user.service.ts](#srcservicesuserservicets)
   - [src/controllers/user.controllers.ts](#srccontrollersusercontrollersts)
   - [src/middlewares/error.middleware.ts](#srcmiddlewareserrormiddlewarets)
   - [src/middlewares/user.validator.ts](#srcmiddlewaresuservalidatorts)
   - [src/middlewares/validate.ts](#srcmiddlewaresvalidatets)
   - [src/routes/user.routes.ts](#srcroutesuserroutests)
   - [src/app.ts](#srcappts)
   - [init-db.ts](#init-dbts)
10. [Cómo correr el proyecto](#10-cómo-correr-el-proyecto)
11. [Probar la API](#11-probar-la-api)
12. [Agregar nuevas tablas y entidades](#12-agregar-nuevas-tablas-y-entidades)
13. [Agregar nuevas APIs (endpoints)](#13-agregar-nuevos-endpoints-a-una-api-existente)
14. [Script PowerShell — crea el proyecto completo con un comando](#14-script-powershell--crea-el-proyecto-completo-con-un-comando)

---

## 1. Requisitos previos

Antes de empezar, instala en tu máquina:

| Herramienta | Versión mínima | Para qué sirve | Link de descarga |
|---|---|---|---|
| Node.js | 18 LTS | Ejecutar JavaScript/TypeScript en el servidor | https://nodejs.org |
| Docker Desktop | 4.x | Correr Oracle sin instalarlo en Windows | https://www.docker.com/products/docker-desktop |
| VS Code | cualquier | Editor de código | https://code.visualstudio.com |
| PowerShell | 5.1+ | Ya viene con Windows 10/11 | — |

Verifica que están instalados abriendo PowerShell y ejecutando:

```powershell
node -v        # debe mostrar v18.x.x o superior
npm -v         # debe mostrar 9.x o superior
docker -v      # debe mostrar Docker version 24.x o superior
```

---

## 2. Oracle en Docker — paso a paso

> **¿Por qué Docker?** Oracle Database requiere una instalación compleja. Con Docker se levanta en minutos sin tocar el sistema operativo.

### Paso 2.1 — Descargar la imagen de Oracle XE

```powershell
docker pull gvenzl/oracle-xe:21-slim
```

- `docker pull` → descarga una imagen desde Docker Hub  
- `gvenzl/oracle-xe` → imagen no oficial pero muy popular de Oracle XE (Express Edition — gratuita)  
- `21-slim` → Oracle 21c en versión ligera (slim = sin herramientas extra)

### Paso 2.2 — Crear y levantar el contenedor

```powershell
docker run -d `
  --name oracle-xe `
  -p 1521:1521 `
  -e ORACLE_PASSWORD=123456 `
  gvenzl/oracle-xe:21-slim
```

Cada parámetro explicado:

| Parámetro | Qué hace |
|---|---|
| `-d` | Corre en segundo plano (detached) |
| `--name oracle-xe` | Nombre del contenedor para referenciarlo fácilmente |
| `-p 1521:1521` | Publica el puerto 1521 del contenedor al 1521 de tu PC. Oracle escucha en 1521 |
| `-e ORACLE_PASSWORD=123456` | Contraseña del usuario `system` (administrador). **Cámbiala en producción** |
| `gvenzl/oracle-xe:21-slim` | La imagen a utilizar |

### Paso 2.3 — Esperar a que Oracle arranque

La primera vez, Oracle tarda 2-5 minutos en inicializarse. Verifica el estado:

```powershell
docker logs -f oracle-xe
```

Espera hasta ver este mensaje en los logs:
```
DATABASE IS READY TO USE!
```

Presiona `Ctrl+C` para salir de los logs.

### Paso 2.4 — Verificar el contenedor corriendo

```powershell
docker ps
```

Debes ver una línea con `oracle-xe` y estado `Up`.

### Paso 2.5 — Datos de conexión resultantes

Con estos pasos tu Oracle queda así:

| Campo | Valor |
|---|---|
| Host | `localhost` |
| Puerto | `1521` |
| Servicio | `XEPDB1` (base de datos pluggable por defecto) |
| Usuario admin | `system` |
| Contraseña | `123456` |
| ConnectString completa | `localhost/XEPDB1` |

> **A partir de aquí, Oracle está listo para recibir conexiones desde Node.js.**

---

## 3. Qué es cada tecnología y por qué se usa

### Node.js
Motor de JavaScript fuera del navegador. Permite escribir el servidor en JavaScript/TypeScript. Es muy rápido para operaciones de red gracias a su modelo de entrada/salida no bloqueante.

### TypeScript
Superset de JavaScript que agrega **tipos de datos**. Beneficios:
- El editor detecta errores antes de ejecutar el código
- El código se autodocumenta (se sabe qué tipo recibe cada función)
- Refactoring más seguro

TypeScript se **compila** a JavaScript antes de ejecutarse. `tsc` es el compilador.

### Express
Framework minimalista para Node.js que facilita crear servidores HTTP, definir rutas, y manejar peticiones/respuestas.

### oracledb
Driver oficial de Oracle para Node.js. Permite ejecutar SQL desde código TypeScript/JavaScript.

### dotenv
Lee variables de entorno desde un archivo `.env`. Útil para no escribir contraseñas o configuraciones en el código fuente.

### cors
Middleware que configura qué dominios externos pueden llamar a tu API. Necesario cuando el frontend está en un origen diferente (ej. React en localhost:5173 llamando al backend en localhost:3000).

### helmet
Middleware de seguridad que agrega cabeceras HTTP que protegen contra ataques comunes (XSS, clickjacking, etc.).

### express-validator
Librería para validar los datos que llegan en el body de las peticiones HTTP antes de procesarlos.

### winston
Logger profesional para Node.js. Escribe logs en consola y en archivos. Más potente que `console.log`.

### nodemon
Herramienta de desarrollo que reinicia el servidor automáticamente cuando detecta cambios en los archivos.

### ts-node
Ejecuta archivos TypeScript directamente sin necesidad de compilarlos primero. Solo se usa en desarrollo.

---

## 4. Estructura del proyecto

```
proyecto/
│
├── src/                          ← Todo el código fuente TypeScript
│   ├── app.ts                    ← Punto de entrada. Configura y arranca Express
│   ├── config/
│   │   └── db.ts                 ← Conexión y pool de Oracle
│   ├── controllers/
│   │   └── user.controllers.ts   ← Recibe req/res, llama al service
│   ├── middlewares/
│   │   ├── error.middleware.ts   ← Manejo global de errores
│   │   ├── user.validator.ts     ← Reglas de validación para usuarios
│   │   └── validate.ts           ← Ejecuta las validaciones y responde si hay error
│   ├── routes/
│   │   └── user.routes.ts        ← Define las URLs de la API de usuarios
│   ├── services/
│   │   └── user.service.ts       ← Lógica de negocio + consultas SQL
│   └── utils/
│       └── logger.ts             ← Logger centralizado con winston
│
├── logs/                         ← Archivos de log generados en tiempo de ejecución
├── dist/                         ← Código JavaScript compilado (generado por tsc)
├── init-db.ts                    ← Script para crear la tabla en Oracle
├── .env                          ← Variables de entorno (NO subir a git)
├── tsconfig.json                 ← Configuración del compilador TypeScript
└── package.json                  ← Dependencias y scripts del proyecto
```

### Patrón de arquitectura: **Capas (Layered Architecture)**

```
HTTP Request
     ↓
  Router           → Define la URL y el método HTTP
     ↓
  Middleware        → Valida los datos de entrada
     ↓
  Controller        → Recibe req/res, delega al service
     ↓
  Service           → Lógica de negocio, ejecuta SQL
     ↓
  Database (Oracle) → Almacena y devuelve datos
     ↑
  (respuesta sube por el mismo camino)
```

Cada capa tiene **una sola responsabilidad**. Esto hace el código fácil de leer, mantener y probar.

---

## 5. Inicializar el proyecto y dependencias

### Paso 5.1 — Crear la carpeta del proyecto

```powershell
mkdir mi-api-oracle
cd mi-api-oracle
```

### Paso 5.2 — Inicializar npm

```powershell
npm init -y
```

- `npm init` → crea el archivo `package.json`  
- `-y` → acepta todos los valores por defecto sin preguntar

### Paso 5.3 — Instalar dependencias de producción

```powershell
npm install cors dotenv express express-validator helmet oracledb winston
```

Son las librerías que el servidor necesita para funcionar en producción:

| Librería | Por qué se instala |
|---|---|
| `cors` | Permite peticiones desde otros orígenes (frontend) |
| `dotenv` | Lee el archivo `.env` con credenciales |
| `express` | Framework HTTP |
| `express-validator` | Valida los datos del body |
| `helmet` | Añade headers de seguridad |
| `oracledb` | Driver para hablar con Oracle |
| `winston` | Logs en archivos y consola |

### Paso 5.4 — Instalar dependencias de desarrollo

```powershell
npm install --save-dev typescript ts-node nodemon @types/node @types/express @types/cors @types/oracledb
```

Solo se usan durante el desarrollo:

| Librería | Por qué se instala |
|---|---|
| `typescript` | El compilador TypeScript (`tsc`) |
| `ts-node` | Ejecuta `.ts` sin compilar (para desarrollo) |
| `nodemon` | Reinicia el servidor al guardar cambios |
| `@types/node` | Tipos TypeScript para las APIs de Node.js (fs, path, process...) |
| `@types/express` | Tipos TypeScript para Express (Request, Response, Router...) |
| `@types/cors` | Tipos TypeScript para cors |
| `@types/oracledb` | Tipos TypeScript para oracledb |

> **¿Qué es `@types/...`?** Muchas librerías están escritas en JavaScript puro y no incluyen información de tipos. Los paquetes `@types/xxx` son archivos `.d.ts` que le dicen a TypeScript cómo se llaman las funciones y qué parámetros reciben.

### Paso 5.5 — Crear la carpeta de logs

```powershell
mkdir logs
```

Winston necesita que esta carpeta exista antes de crear los archivos de log.

---

## 6. Archivo `.env`

Crea un archivo llamado **exactamente** `.env` en la raíz del proyecto:

```env
DB_USER=system
DB_PASS=123456
DB_CONN=localhost/XEPDB1
```

- **`DB_USER`** → Usuario de Oracle. `system` es el usuario administrador creado por Docker.
- **`DB_PASS`** → La contraseña que pusiste en `ORACLE_PASSWORD` al crear el contenedor.
- **`DB_CONN`** → La cadena de conexión. Formato: `host/nombre_servicio`. El servicio `XEPDB1` es el nombre de la base de datos pluggable que Oracle XE crea por defecto.

> **IMPORTANTE:** Agrega `.env` a tu `.gitignore` para nunca subir contraseñas a repositorios:
> ```
> echo ".env" >> .gitignore
> ```

---

## 7. Archivo `tsconfig.json` — línea por línea

```json
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
```

| Opción | Qué hace y por qué |
|---|---|
| `"target": "ES2020"` | El JavaScript generado usará sintaxis de ES2020. Node.js 18+ lo entiende perfectamente. |
| `"module": "commonjs"` | Los archivos `.js` generados usan `require()`/`module.exports`. Node.js tradicional entiende CommonJS. |
| `"lib": ["ES2020"]` | Le dice al compilador qué APIs de JavaScript están disponibles (Promise, Array.flat, etc.) |
| `"outDir": "./dist"` | Los archivos `.js` compilados se guardan en la carpeta `dist/`. |
| `"rootDir": "./src"` | Todos los archivos `.ts` fuente viven en `src/`. El compilador respeta esa estructura al generar `dist/`. |
| `"strict": true` | Activa todas las verificaciones estrictas de TypeScript. Detecta más errores. Siempre actívalo. |
| `"esModuleInterop": true` | Permite usar `import express from 'express'` en vez de `import * as express from 'express'`. Sin esto, muchos imports de librerías comunes fallan. |
| `"skipLibCheck": true` | No verifica los tipos dentro de `node_modules`. Acelera la compilación y evita errores en librerías de terceros. |
| `"forceConsistentCasingInFileNames": true` | Evita bugs en Linux (case-sensitive) cuando en Windows los nombres de archivo no distinguen mayúsculas. |
| `"resolveJsonModule": true` | Permite hacer `import data from './data.json'` si alguna vez se necesita. |
| `"include": ["src/**/*"]` | Solo compila archivos dentro de `src/`. |
| `"exclude": ["node_modules", "dist"]` | Nunca compila las dependencias ni el output ya generado. |

---

## 8. Archivo `package.json` — línea por línea

```json
{
    "name": "types_script_servernodeexpressoracle",
    "version": "1.0.0",
    "main": "dist/app.js",
    "scripts": {
        "start":   "node dist/app.js",
        "dev":     "nodemon --exec ts-node src/app.ts",
        "build":   "tsc",
        "init-db": "ts-node init-db.ts"
    },
    "dependencies": { ... },
    "devDependencies": { ... }
}
```

| Campo/Script | Qué hace y cuándo se usa |
|---|---|
| `"main": "dist/app.js"` | El punto de entrada cuando alguien hace `require('tu-paquete')`. También documenta que en producción se ejecuta el JS compilado. |
| `"start"` | **Producción.** Ejecuta el JavaScript ya compilado. Primero hay que correr `build`. |
| `"dev"` | **Desarrollo.** nodemon observa cambios y relanza `ts-node src/app.ts` al detectarlos. Sin compilar. |
| `"build"` | Compila todo el TypeScript de `src/` a `dist/`. Se usa antes de subir a producción. |
| `"init-db"` | Crea las tablas en Oracle. Se corre **una sola vez** cuando el proyecto es nuevo. |

---

## 9. Código fuente — cada archivo línea por línea

---

### `src/utils/logger.ts`

```typescript
import { createLogger, format, transports } from 'winston';
```
Importa tres cosas de `winston`:
- `createLogger` → función que crea un logger
- `format` → objeto con funciones para dar formato a los logs
- `transports` → define dónde se escriben los logs (consola, archivo, red, etc.)

```typescript
const logger = createLogger({
```
Crea el logger y lo guarda en la constante `logger`. Se exportará al final.

```typescript
    level: 'info',
```
Nivel mínimo de logs a registrar. Hay 7 niveles (de menor a mayor gravedad): `silly`, `debug`, `verbose`, `info`, `warn`, `error`. Con `info` se ignoran los niveles inferiores (silly, debug, verbose).

```typescript
    format: format.combine(
        format.timestamp(),
        format.printf(({ level, message, timestamp }) => {
            return `${timestamp} [${level.toUpperCase()}]: ${message}`;
        })
    ),
```
Define cómo se ve cada línea de log:
- `format.combine(...)` → aplica varios formatos en cadena
- `format.timestamp()` → agrega la fecha/hora a cada log
- `format.printf(...)` → plantilla personalizada para el texto. Produce líneas como: `2026-03-22T10:00:00 [INFO]: Servidor en http://localhost:3000`

```typescript
    transports: [
        new transports.Console(),
        new transports.File({ filename: 'logs/error.log', level: 'error' }),
        new transports.File({ filename: 'logs/combined.log' })
    ]
```
Define **tres destinos** para los logs:
1. **Console** → muestra logs en la terminal
2. **File error.log** → solo guarda logs de nivel `error` o superior en `logs/error.log`
3. **File combined.log** → guarda **todos** los logs en `logs/combined.log`

```typescript
export default logger;
```
Exporta el logger como exportación por defecto. Otros archivos lo importarán con `import logger from '../utils/logger'`.

---

### `src/config/db.ts`

```typescript
import oracledb from 'oracledb';
import dotenv from 'dotenv';
```
Importa el driver de Oracle y la librería para leer variables de entorno.

```typescript
dotenv.config();
```
Lee el archivo `.env` y carga sus variables en `process.env`. Debe llamarse **antes** de usar `process.env.DB_USER`, etc.

```typescript
export async function initDB(): Promise<void> {
```
Función asíncrona exportada que inicializa el **pool de conexiones**.  
- `async` → puede usar `await` dentro  
- `Promise<void>` → devuelve una promesa que no resuelve ningún valor (solo completa o falla)

```typescript
    try {
        await oracledb.createPool({
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            connectString: process.env.DB_CONN,
            poolMin: 1,
            poolMax: 5
        });
```
Crea un **pool de conexiones** a Oracle.  
Un pool es un conjunto de conexiones abiertas y reutilizables. Esto es mucho más eficiente que abrir y cerrar una conexión nueva por cada petición HTTP.

- `user/password/connectString` → credenciales leídas del `.env`
- `poolMin: 1` → mantener al menos 1 conexión siempre abierta
- `poolMax: 5` → máximo 5 conexiones simultáneas. Si llegan 6 peticiones a la vez, la sexta espera a que se libere una.

```typescript
        console.log('Oracle conectado');
    } catch (err) {
        console.error(err);
    }
}
```
Si el pool se crea bien → imprime el mensaje. Si falla (Oracle apagado, credenciales incorrectas) → captura el error y lo imprime sin detener el proceso.

```typescript
export async function getConnection(): Promise<oracledb.Connection> {
    return oracledb.getConnection();
}
```
Función exportada que toma una conexión disponible del pool.  
- Devuelve `oracledb.Connection` → el tipo TypeScript de una conexión Oracle
- Los servicios llaman esta función para obtener una conexión, ejecutar SQL y luego devolverla al pool con `conn.close()`

---

### `src/services/user.service.ts`

```typescript
import { getConnection } from '../config/db';
```
Importa la función para obtener una conexión del pool.

```typescript
export interface User {
    id?: number;
    name: string;
    email: string;
}
```
Define la forma (shape) de un usuario con TypeScript.  
- `interface` → describe la estructura de un objeto
- `id?: number` → el `?` lo hace **opcional** (no se envía al crear un usuario, Oracle lo genera automáticamente)
- `name: string` → obligatorio, texto
- `email: string` → obligatorio, texto

```typescript
export async function getAll(): Promise<unknown[]> {
    const conn = await getConnection();
    const result = await conn.execute(`SELECT * FROM users`);
    await conn.close();
    return result.rows ?? [];
}
```
Obtiene todos los usuarios:
1. `getConnection()` → toma una conexión del pool
2. `conn.execute(...)` → ejecuta el SQL y guarda el resultado
3. `conn.close()` → **devuelve la conexión al pool** (muy importante, si no se hace el pool se agota)
4. `result.rows ?? []` → devuelve las filas o un array vacío si `rows` es `null`

```typescript
export async function getById(id: number): Promise<unknown> {
    const conn = await getConnection();
    const result = await conn.execute(
        `SELECT * FROM users WHERE id = :id`,
        { id }
    );
    await conn.close();
    return result.rows?.[0];
}
```
Obtiene un usuario por su ID:
- `:id` → parámetro bind. **Nunca** concatenar variables al SQL directamente (vulnerable a SQL Injection)
- `{ id }` → objeto que mapea el parámetro `:id` al valor de la variable `id`
- `result.rows?.[0]` → devuelve la primera fila o `undefined` si no existe

```typescript
export async function create(user: User): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `INSERT INTO users (name, email) VALUES (:name, :email)`,
        user as unknown as Record<string, string | number | undefined>,
        { autoCommit: true }
    );
    await conn.close();
}
```
Crea un nuevo usuario:
- Los parámetros `:name` y `:email` se vinculan desde el objeto `user`
- `as unknown as Record<...>` → cast de tipo necesario para satisfacer el tipado estricto de `@types/oracledb`
- `{ autoCommit: true }` → confirma la transacción automáticamente. Sin esto, el INSERT quedaría pendiente y se descartaría al cerrar la conexión

```typescript
export async function update(id: number, user: Partial<User>): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `UPDATE users SET name=:name, email=:email WHERE id=:id`,
        { ...user, id } as Record<string, string | number | undefined>,
        { autoCommit: true }
    );
    await conn.close();
}
```
Actualiza un usuario:
- `Partial<User>` → todos los campos son opcionales (permite actualizaciones parciales futuras)
- `{ ...user, id }` → combina las propiedades del usuario con el `id` del parámetro en un solo objeto

```typescript
export async function remove(id: number): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `DELETE FROM users WHERE id=:id`,
        { id },
        { autoCommit: true }
    );
    await conn.close();
}
```
Elimina un usuario por ID. Misma estructura que las anteriores.

---

### `src/controllers/user.controllers.ts`

Los controllers son el puente entre la petición HTTP y el service. Nunca ejecutan SQL directamente.

```typescript
import { Request, Response, NextFunction } from 'express';
```
Importa los tipos de Express:
- `Request` → objeto con todo sobre la petición (body, params, headers, etc.)
- `Response` → objeto para enviar la respuesta al cliente
- `NextFunction` → función para pasar el control al siguiente middleware (o al error handler)

```typescript
import * as service from '../services/user.service';
```
Importa **todas** las exportaciones del service bajo el nombre `service`. Así se llama `service.getAll()`, `service.create()`, etc.

```typescript
export const getAll = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        res.json(await service.getAll());
    } catch (err) { next(err); }
};
```
Handler para `GET /api/users`:
- Llama al service, convierte el resultado a JSON y lo envía
- Si hay un error → `next(err)` lo pasa al **error middleware global** (definido en `error.middleware.ts`)
- `Promise<void>` → Express 5 requiere que los handlers async devuelvan `Promise<void>`

```typescript
export const getOne = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const data = await service.getById(Number(req.params.id));
```
- `req.params.id` → el valor `{id}` de la URL `/api/users/:id` llega como string
- `Number(...)` → convierte el string a número para pasarlo al service

```typescript
        if (!data) {
            const error = new Error('Usuario no existe') as Error & { status: number };
            error.status = 404;
            next(error);
            return;
        }
```
Si el service devuelve `undefined` (usuario no encontrado):
- Crea un Error con la propiedad `status` = 404
- Lo pasa al error middleware con `next(error)`
- `return` para no continuar ejecutando código después

```typescript
export const create = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        await service.create(req.body);
        res.status(201).json({ message: 'Creado' });
    } catch (err) { next(err); }
};
```
- `req.body` → el JSON que envió el cliente en el body de la petición POST
- `res.status(201)` → código HTTP 201 = "Created" (recurso creado exitosamente)

---

### `src/middlewares/error.middleware.ts`

```typescript
interface AppError extends Error {
    status?: number;
}
```
Extiende la clase Error estándar de JavaScript agregando `status?: number` opcional. Así se puede hacer `error.status = 404` en los controllers.

```typescript
function errorHandler(err: AppError, req: Request, res: Response, _next: NextFunction): void {
```
Express reconoce un **error handler** porque tiene **4 parámetros** (el primero es el error).  
- `_next` → el guión bajo indica que el parámetro no se usa pero debe estar declarado para que Express lo reconozca como handler de error

```typescript
    let message = err.message;
    let status = err.status ?? 500;
```
- `??` (nullish coalescing) → usa `err.status` si existe, de lo contrario usa `500` (Internal Server Error)

```typescript
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
```
Intercepta errores específicos de Oracle y los convierte a mensajes amigables:
- `ORA-00001` → violación de UNIQUE constraint (ej. email duplicado)
- `ORA-00942` → tabla no existe (ej. se borró o no se corrió init-db)
- `ORA-02291` → violación de clave foránea (ej. se intenta insertar con un ID que no existe en otra tabla)

```typescript
    logger.error(`${req.method} ${req.url} - ${message}`);
    res.status(status).json({ success: false, message });
```
- Registra el error en los logs con método HTTP y URL afectada
- Responde al cliente con un JSON estructurado

---

### `src/middlewares/user.validator.ts`

```typescript
import { body, ValidationChain } from 'express-validator';
```
- `body` → función para crear reglas de validación sobre el `req.body`
- `ValidationChain` → el tipo TypeScript de una regla de validación

```typescript
export const createUserValidator: ValidationChain[] = [
    body('name')
        .notEmpty().withMessage('Nombre requerido')
        .isLength({ min: 3 }).withMessage('Minimo 3 caracteres'),

    body('email')
        .isEmail().withMessage('Email invalido')
];
```
Array de validaciones para crear un usuario:
- `body('name').notEmpty()` → el campo `name` debe existir y no estar vacío
- `.withMessage('...')` → mensaje de error si la validación falla
- `.isLength({ min: 3 })` → mínimo 3 caracteres
- `body('email').isEmail()` → debe tener formato de email válido

---

### `src/middlewares/validate.ts`

```typescript
function validate(req: Request, res: Response, next: NextFunction): void {
    const errors = validationResult(req);
```
`validationResult(req)` recopila todos los errores que generaron las validaciones del middleware anterior.

```typescript
    if (!errors.isEmpty()) {
        res.status(400).json({
            success: false,
            errors: errors.array()
        });
        return;
    }
    next();
}
```
- Si hay errores → responde con `400 Bad Request` y la lista de errores. La petición no llega al controller.
- Si no hay errores → `next()` pasa el control al siguiente handler (el controller).

---

### `src/routes/user.routes.ts`

```typescript
import { Router } from 'express';
```
`Router` es una mini-aplicación Express que agrupa rutas relacionadas.

```typescript
const router = Router();
```
Crea el router de usuarios.

```typescript
router.get('/',    c.getAll);
router.get('/:id', c.getOne);
```
- `GET /` → llama a `getAll`  
- `GET /:id` → `:id` es un parámetro dinámico accesible por `req.params.id`

```typescript
router.post(
    '/',
    createUserValidator,  // 1° ejecuta las validaciones
    validate,             // 2° comprueba si hubo errores
    c.create              // 3° solo llega aquí si los datos son válidos
);
```
Los middlewares en Express se ejecutan en orden de izquierda a derecha (o de arriba a abajo). Si `validate` detecta errores, responde y la cadena se corta — `c.create` nunca se ejecuta.

```typescript
router.put('/:id',    c.update);
router.delete('/:id', c.remove);

export default router;
```
Rutas para actualizar y eliminar. Se exporta para que `app.ts` lo monte.

---

### `src/app.ts`

```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
```
Importa los tres pilares del servidor: el framework, CORS y seguridad de headers.

```typescript
import { initDB } from './config/db';
import userRoutes from './routes/user.routes';
import errorHandler from './middlewares/error.middleware';
```
Importa las partes propias del proyecto.

```typescript
const app = express();
```
Crea la aplicación Express. `app` es el objeto central al que se le agrega todo.

```typescript
app.use(cors());
app.use(helmet());
app.use(express.json());
```
Registra middlewares globales (se aplican a **todas** las rutas):
- `cors()` → permite peticiones desde cualquier origen. En producción se debe configurar para solo permitir el dominio del frontend.
- `helmet()` → agrega ~14 headers de seguridad automáticamente
- `express.json()` → parsea el body de peticiones con `Content-Type: application/json`. Sin esto `req.body` sería `undefined`.

```typescript
app.use('/api/users', userRoutes);
```
Monta el router de usuarios en el prefijo `/api/users`. Todas las rutas definidas en `user.routes.ts` se vuelven:
- `/api/users/` → GET getAll, POST create
- `/api/users/:id` → GET getOne, PUT update, DELETE remove

```typescript
initDB();
```
Llama a la función para crear el pool de conexiones a Oracle. Es una llamada `async` pero se llama sin `await` intencionalmente — si Oracle falla, el servidor sigue arrancando y el error se imprime en consola.

```typescript
app.listen(3000, () => {
    console.log('Servidor en http://localhost:3000');
});
```
Pone a escuchar el servidor en el puerto 3000. El callback se ejecuta cuando el servidor está listo.

```typescript
app.use(errorHandler);
```
Registra el error handler **al final**. Express detecta que tiene 4 parámetros y lo usa para capturar cualquier error que se haya pasado con `next(err)` en cualquier ruta.

---

### `init-db.ts`

Este script se corre **una sola vez** para crear las tablas en Oracle. Se ejecuta directamente con `ts-node`, sin el servidor corriendo.

```typescript
import oracledb from 'oracledb';
```
Importa el driver directamente. No usa el pool porque el pool no ha sido creado aún.

```typescript
async function init(): Promise<void> {
    let conn: oracledb.Connection | undefined;
```
`conn` empieza como `undefined`. Si la conexión falla antes de crearse, el bloque `finally` no intentará cerrarla.

```typescript
    conn = await oracledb.getConnection({
        user: 'system',
        password: '123456',
        connectString: 'localhost/XEPDB1'
    });
```
Abre una conexión directa (no pool) con credenciales hardcodeadas. Esto está bien solo para scripts de inicialización. Las credenciales de producción van en el `.env`.

```typescript
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
```
Bloque PL/SQL (lenguaje procedimental de Oracle):
- `BEGIN...END` → bloque anónimo PL/SQL
- `EXECUTE IMMEDIATE` → ejecuta SQL dinámico dentro del bloque PL/SQL
- `NUMBER GENERATED ALWAYS AS IDENTITY` → equivalente al `AUTO_INCREMENT` de MySQL. Oracle genera el ID automáticamente.
- `VARCHAR2(100)` → texto de hasta 100 caracteres
- El bloque `EXCEPTION` captura el error `ORA-00955` (la tabla ya existe) y lo ignora. Si es cualquier otro error, lo relanza (`RAISE`). Esto hace el script **idempotente** (se puede correr varias veces sin errores).

```typescript
    } finally {
        if (conn) await conn.close();
    }
```
El bloque `finally` se ejecuta **siempre**, haya error o no. Garantiza que la conexión se cierre y los recursos se liberen.

---

## 10. Cómo correr el proyecto

### Primera vez (setup completo)

```powershell
# 1. Clonar o crear el proyecto
cd mi-api-oracle

# 2. Instalar dependencias
npm install

# 3. Crear las tablas en Oracle (solo la primera vez)
npm run init-db

# 4. Arrancar en modo desarrollo
npm run dev
```

### Comandos disponibles

| Comando | Cuándo usar |
|---|---|
| `npm run dev` | Desarrollo diario. Recarga automáticamente al guardar. |
| `npm run build` | Antes de subir a producción. Compila TS → JS en `dist/` |
| `npm start` | Producción. Ejecuta el JS compilado. |
| `npm run init-db` | Solo la primera vez, o si se borra la base de datos. |

---

## 11. Probar la API

Usa Postman, Insomnia, o el cliente HTTP de VS Code (extensión REST Client).

### Obtener todos los usuarios

```http
GET http://localhost:3000/api/users
```

### Obtener un usuario por ID

```http
GET http://localhost:3000/api/users/1
```

### Crear un usuario

```http
POST http://localhost:3000/api/users
Content-Type: application/json

{
    "name": "Juan Perez",
    "email": "juan@ejemplo.com"
}
```

### Actualizar un usuario

```http
PUT http://localhost:3000/api/users/1
Content-Type: application/json

{
    "name": "Juan Actualizado",
    "email": "juan.nuevo@ejemplo.com"
}
```

### Eliminar un usuario

```http
DELETE http://localhost:3000/api/users/1
```

---

## 12. Agregar nuevas tablas y entidades

Para agregar, por ejemplo, una entidad **Producto**, sigue estos pasos:

### Paso A — Agregar la tabla en `init-db.ts`

Agrega el bloque de creación de tabla dentro de la función `init()`:

```typescript
await conn.execute(`
    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE products (
                id      NUMBER GENERATED ALWAYS AS IDENTITY,
                name    VARCHAR2(200),
                price   NUMBER(10,2),
                PRIMARY KEY (id)
            )
        ';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -955 THEN RAISE; END IF;
    END;
`);
console.log('Tabla products lista');
```

Luego corre `npm run init-db` nuevamente.

### Paso B — Crear el service en `src/services/product.service.ts`

```typescript
import { getConnection } from '../config/db';

export interface Product {
    id?: number;
    name: string;
    price: number;
}

export async function getAll(): Promise<unknown[]> {
    const conn = await getConnection();
    const result = await conn.execute(`SELECT * FROM products`);
    await conn.close();
    return result.rows ?? [];
}

export async function getById(id: number): Promise<unknown> {
    const conn = await getConnection();
    const result = await conn.execute(
        `SELECT * FROM products WHERE id = :id`, { id }
    );
    await conn.close();
    return result.rows?.[0];
}

export async function create(product: Product): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `INSERT INTO products (name, price) VALUES (:name, :price)`,
        product as unknown as Record<string, string | number | undefined>,
        { autoCommit: true }
    );
    await conn.close();
}

export async function update(id: number, product: Partial<Product>): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `UPDATE products SET name=:name, price=:price WHERE id=:id`,
        { ...product, id } as Record<string, string | number | undefined>,
        { autoCommit: true }
    );
    await conn.close();
}

export async function remove(id: number): Promise<void> {
    const conn = await getConnection();
    await conn.execute(
        `DELETE FROM products WHERE id=:id`, { id }, { autoCommit: true }
    );
    await conn.close();
}
```

### Paso C — Crear el controller en `src/controllers/product.controllers.ts`

```typescript
import { Request, Response, NextFunction } from 'express';
import * as service from '../services/product.service';

export const getAll = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { res.json(await service.getAll()); }
    catch (err) { next(err); }
};

export const getOne = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const data = await service.getById(Number(req.params.id));
        if (!data) {
            const error = new Error('Producto no existe') as Error & { status: number };
            error.status = 404;
            next(error); return;
        }
        res.json(data);
    } catch (err) { next(err); }
};

export const create = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { await service.create(req.body); res.status(201).json({ message: 'Creado' }); }
    catch (err) { next(err); }
};

export const update = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { await service.update(Number(req.params.id), req.body); res.json({ message: 'Actualizado' }); }
    catch (err) { next(err); }
};

export const remove = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { await service.remove(Number(req.params.id)); res.json({ message: 'Eliminado' }); }
    catch (err) { next(err); }
};
```

### Paso D — Crear el validator en `src/middlewares/product.validator.ts`

```typescript
import { body, ValidationChain } from 'express-validator';

export const createProductValidator: ValidationChain[] = [
    body('name').notEmpty().withMessage('Nombre requerido'),
    body('price').isNumeric().withMessage('Precio debe ser un número')
                 .isFloat({ min: 0 }).withMessage('Precio no puede ser negativo')
];
```

### Paso E — Crear las rutas en `src/routes/product.routes.ts`

```typescript
import { Router } from 'express';
import * as c from '../controllers/product.controllers';
import validate from '../middlewares/validate';
import { createProductValidator } from '../middlewares/product.validator';

const router = Router();

router.get('/',     c.getAll);
router.get('/:id',  c.getOne);
router.post('/', createProductValidator, validate, c.create);
router.put('/:id',    c.update);
router.delete('/:id', c.remove);

export default router;
```

### Paso F — Montar las rutas en `src/app.ts`

Agrega dos líneas al archivo:

```typescript
// Importa el nuevo router (junto a los otros imports)
import productRoutes from './routes/product.routes';

// Monta el router (junto a los otros app.use)
app.use('/api/products', productRoutes);
```

**¡Listo!** La nueva API de productos queda disponible en `http://localhost:3000/api/products`.

---

## 13. Agregar nuevos endpoints a una API existente

Supón que quieres agregar un endpoint para buscar usuarios por email:

### En el service (`user.service.ts`)

```typescript
export async function getByEmail(email: string): Promise<unknown> {
    const conn = await getConnection();
    const result = await conn.execute(
        `SELECT * FROM users WHERE email = :email`,
        { email }
    );
    await conn.close();
    return result.rows?.[0];
}
```

### En el controller (`user.controllers.ts`)

```typescript
export const getByEmail = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const data = await service.getByEmail(req.query.email as string);
        if (!data) {
            const error = new Error('Usuario no encontrado') as Error & { status: number };
            error.status = 404;
            next(error); return;
        }
        res.json(data);
    } catch (err) { next(err); }
};
```

### En las rutas (`user.routes.ts`)

```typescript
// Agregar esta línea junto a las otras rutas GET
router.get('/search', c.getByEmail);
```

Uso: `GET http://localhost:3000/api/users/search?email=juan@ejemplo.com`

> **Nota:** La ruta `/search` debe ir **antes** de `/:id`, porque si va después, Express podría interpretar "search" como un ID.

---

## 14. Script PowerShell — crea el proyecto completo con un comando

Guarda el siguiente script como `crear-proyecto.ps1` en cualquier carpeta y ejecútalo con:

```powershell
.\crear-proyecto.ps1 -Nombre "mi-api-oracle"
```

```powershell
# crear-proyecto.ps1
# Uso: .\crear-proyecto.ps1 -Nombre "nombre-del-proyecto"
# Requisitos: Node.js, Docker con Oracle XE corriendo en localhost:1521

param(
    [Parameter(Mandatory=$true)]
    [string]$Nombre
)

Write-Host "==> Creando proyecto: $Nombre" -ForegroundColor Cyan

# --- 1. Carpetas ---
New-Item -ItemType Directory -Force -Path "$Nombre/src/config"        | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/controllers"   | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/middlewares"   | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/routes"        | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/services"      | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/src/utils"         | Out-Null
New-Item -ItemType Directory -Force -Path "$Nombre/logs"              | Out-Null
Set-Location $Nombre

# --- 2. package.json ---
@'
{
    "name": "PROJECT_NAME",
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
'@ -replace 'PROJECT_NAME', $Nombre | Set-Content "package.json"

# --- 3. tsconfig.json ---
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
@'
import { createLogger, format, transports } from "winston";

const logger = createLogger({
    level: "info",
    format: format.combine(
        format.timestamp(),
        format.printf(({ level, message, timestamp }) => {
            return `${timestamp} [${level.toUpperCase()}]: ${message}`;
        })
    ),
    transports: [
        new transports.Console(),
        new transports.File({ filename: "logs/error.log", level: "error" }),
        new transports.File({ filename: "logs/combined.log" })
    ]
});

export default logger;
'@ | Set-Content "src/utils/logger.ts"

# --- 7. src/config/db.ts ---
@'
import oracledb from "oracledb";
import dotenv from "dotenv";

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
        console.log("Oracle conectado");
    } catch (err) {
        console.error(err);
    }
}

export async function getConnection(): Promise<oracledb.Connection> {
    return oracledb.getConnection();
}
'@ | Set-Content "src/config/db.ts"

# --- 8. src/services/user.service.ts ---
@'
import { getConnection } from "../config/db";

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
    const result = await conn.execute(`SELECT * FROM users WHERE id = :id`, { id });
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
    await conn.execute(`DELETE FROM users WHERE id=:id`, { id }, { autoCommit: true });
    await conn.close();
}
'@ | Set-Content "src/services/user.service.ts"

# --- 9. src/controllers/user.controllers.ts ---
@'
import { Request, Response, NextFunction } from "express";
import * as service from "../services/user.service";

export const getAll = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { res.json(await service.getAll()); }
    catch (err) { next(err); }
};

export const getOne = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const data = await service.getById(Number(req.params.id));
        if (!data) {
            const error = new Error("Usuario no existe") as Error & { status: number };
            error.status = 404;
            next(error); return;
        }
        res.json(data);
    } catch (err) { next(err); }
};

export const create = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { await service.create(req.body); res.status(201).json({ message: "Creado" }); }
    catch (err) { next(err); }
};

export const update = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { await service.update(Number(req.params.id), req.body); res.json({ message: "Actualizado" }); }
    catch (err) { next(err); }
};

export const remove = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { await service.remove(Number(req.params.id)); res.json({ message: "Eliminado" }); }
    catch (err) { next(err); }
};
'@ | Set-Content "src/controllers/user.controllers.ts"

# --- 10. src/middlewares/error.middleware.ts ---
@'
import { Request, Response, NextFunction } from "express";
import logger from "../utils/logger";

interface AppError extends Error {
    status?: number;
}

function errorHandler(err: AppError, req: Request, res: Response, _next: NextFunction): void {
    let message = err.message;
    let status = err.status ?? 500;

    if (err.message.includes("ORA-00001")) { message = "Registro duplicado"; status = 400; }
    if (err.message.includes("ORA-00942")) { message = "Tabla no existe"; status = 500; }
    if (err.message.includes("ORA-02291")) { message = "Violacion de clave foranea"; status = 400; }

    logger.error(`${req.method} ${req.url} - ${message}`);
    res.status(status).json({ success: false, message });
}

export default errorHandler;
'@ | Set-Content "src/middlewares/error.middleware.ts"

# --- 11. src/middlewares/user.validator.ts ---
@'
import { body, ValidationChain } from "express-validator";

export const createUserValidator: ValidationChain[] = [
    body("name")
        .notEmpty().withMessage("Nombre requerido")
        .isLength({ min: 3 }).withMessage("Minimo 3 caracteres"),
    body("email")
        .isEmail().withMessage("Email invalido")
];
'@ | Set-Content "src/middlewares/user.validator.ts"

# --- 12. src/middlewares/validate.ts ---
@'
import { Request, Response, NextFunction } from "express";
import { validationResult } from "express-validator";

function validate(req: Request, res: Response, next: NextFunction): void {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        res.status(400).json({ success: false, errors: errors.array() });
        return;
    }
    next();
}

export default validate;
'@ | Set-Content "src/middlewares/validate.ts"

# --- 13. src/routes/user.routes.ts ---
@'
import { Router } from "express";
import * as c from "../controllers/user.controllers";
import validate from "../middlewares/validate";
import { createUserValidator } from "../middlewares/user.validator";

const router = Router();

router.get("/",    c.getAll);
router.get("/:id", c.getOne);
router.post("/", createUserValidator, validate, c.create);
router.put("/:id",    c.update);
router.delete("/:id", c.remove);

export default router;
'@ | Set-Content "src/routes/user.routes.ts"

# --- 14. src/app.ts ---
@'
import express from "express";
import cors from "cors";
import helmet from "helmet";

import { initDB } from "./config/db";
import userRoutes from "./routes/user.routes";
import errorHandler from "./middlewares/error.middleware";

const app = express();

app.use(cors());
app.use(helmet());
app.use(express.json());

app.use("/api/users", userRoutes);

initDB();

app.listen(3000, () => {
    console.log("Servidor en http://localhost:3000");
});

app.use(errorHandler);
'@ | Set-Content "src/app.ts"

# --- 15. init-db.ts ---
@'
import oracledb from "oracledb";

async function init(): Promise<void> {
    let conn: oracledb.Connection | undefined;
    try {
        conn = await oracledb.getConnection({
            user: "system",
            password: "123456",
            connectString: "localhost/XEPDB1"
        });
        console.log("Conectado a Oracle");

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
        console.log("Tabla users lista");
    } catch (err) {
        console.error(err);
    } finally {
        if (conn) await conn.close();
    }
}

init();
'@ | Set-Content "init-db.ts"

# --- 16. Instalar dependencias ---
Write-Host "==> Instalando dependencias..." -ForegroundColor Cyan
npm install

# --- 17. Crear tablas en Oracle ---
Write-Host "==> Creando tablas en Oracle..." -ForegroundColor Cyan
npm run init-db

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " Proyecto listo: $Nombre"              -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host " Comandos disponibles:"                -ForegroundColor Yellow
Write-Host "   npm run dev    -> modo desarrollo"  -ForegroundColor White
Write-Host "   npm run build  -> compilar"         -ForegroundColor White
Write-Host "   npm start      -> produccion"       -ForegroundColor White
Write-Host ""
Write-Host " API disponible en: http://localhost:3000/api/users" -ForegroundColor Cyan
```

### Cómo usar el script

```powershell
# 1. Guarda el script como crear-proyecto.ps1
# 2. Asegúrate de que Oracle Docker está corriendo (docker ps)
# 3. Ejecuta:
.\crear-proyecto.ps1 -Nombre "mi-api-oracle"

# 4. Una vez creado, entra a la carpeta y arráncalo:
cd mi-api-oracle
npm run dev
```

> Si PowerShell bloquea la ejecución de scripts, corre primero:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## Resumen rápido de errores comunes

| Error | Causa probable | Solución |
|---|---|---|
| `ORA-12541: TNS no listener` | Oracle no está corriendo | `docker start oracle-xe` |
| `ORA-01017: invalid credentials` | Usuario/contraseña incorrectos en `.env` | Verifica `.env` |
| `ORA-00942: table or view does not exist` | No corriste init-db | `npm run init-db` |
| `Cannot find module 'oracledb'` | No instalaste dependencias | `npm install` |
| `EADDRINUSE: address already in use :3000` | Puerto 3000 ocupado | Cierra el proceso que usa el puerto o cambia el puerto en `app.ts` |
| `error TS...` al compilar | Error de tipos en el código | Lee el mensaje, la línea indicada tiene un error de tipado |
