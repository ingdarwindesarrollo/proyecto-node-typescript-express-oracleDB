const logger = require('../utils/logger');

function errorHandler(err, req, res, next) {
    let message = err.message;
    let status = err.status || 500;

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

module.exports = errorHandler;
