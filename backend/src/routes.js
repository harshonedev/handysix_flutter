import express from 'express';
import { login } from './controllers/auth_controller.js';
import { getGameState } from './controllers/game_controller.js';


const router = express.Router();

// Auth routes
router.post('/user/login', login);
router.get('/user/:id', getUserById);

// Game routes (WebSocket related)
router.get('/game/:roomId/state', getGameState);

export default router;

