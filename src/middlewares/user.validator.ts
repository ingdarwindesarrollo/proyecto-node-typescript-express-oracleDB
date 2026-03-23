import { body, ValidationChain } from 'express-validator';

export const createUserValidator: ValidationChain[] = [
    body('name')
        .notEmpty().withMessage('Nombre requerido')
        .isLength({ min: 3 }).withMessage('Minimo 3 caracteres'),

    body('email')
        .isEmail().withMessage('Email invalido')
];
