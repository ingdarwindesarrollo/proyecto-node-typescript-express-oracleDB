const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');

const { initDB }     = require('./config/db');
const userRoutes     = require('./routes/user.routes');
const errorHandler   = require('./middlewares/error.middleware');

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
