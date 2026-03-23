const service = require('../services/user.service');

exports.getAll = async (req, res, next) => {
    try {
        res.json(await service.getAll());
    } catch (err) { next(err); }
};

exports.getOne = async (req, res, next) => {
    try {
        const data = await service.getById(req.params.id);
        if (!data) {
            const error = new Error('Usuario no existe');
            error.status = 404;
            return next(error);
        }
        res.json(data);
    } catch (err) { next(err); }
};

exports.create = async (req, res, next) => {
    try {
        await service.create(req.body);
        res.status(201).json({ message: 'Creado' });
    } catch (err) { next(err); }
};

exports.update = async (req, res, next) => {
    try {
        await service.update(req.params.id, req.body);
        res.json({ message: 'Actualizado' });
    } catch (err) { next(err); }
};

exports.delete = async (req, res, next) => {
    try {
        await service.remove(req.params.id);
        res.json({ message: 'Eliminado' });
    } catch (err) { next(err); }
};
