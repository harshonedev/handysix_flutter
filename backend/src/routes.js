import express from 'express';
import { login } from './controllers/auth_controller.js';


const router = express.Router();

router.post('/users/login', login);
router.get('/users/:id', getUserById);

// websocket routes



export default router;

