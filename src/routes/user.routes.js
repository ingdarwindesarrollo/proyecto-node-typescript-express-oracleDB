const router = require('express').Router();
const c = require('../controllers/user.controllers');
const validate = require('../middlewares/validate');
const { createUserValidator } = require('../middlewares/user.validator');

router.get('/',    c.getAll);
router.get('/:id', c.getOne);

router.post(
    '/',
    createUserValidator,
    validate,
    c.create
);

router.put('/:id',    c.update);
router.delete('/:id', c.delete);

module.exports = router;
