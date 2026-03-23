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
