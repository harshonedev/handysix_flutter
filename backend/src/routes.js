import express from 'express';
import { getUserById, login } from './controllers/auth_controller.js';


const router = express.Router();

// Auth routes
router.post('/user/login', login);
router.get('/user/:id', getUserById);

export default router;

