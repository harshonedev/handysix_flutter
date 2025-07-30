import express from 'express';
import { login } from './controllers/auth_controller.js';


const router = express.Router();

router.post('/login', login);


// websocket routes



export default router;

