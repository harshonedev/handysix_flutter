import findGameHandler from './findGameHandler.js';
import playerMoveHandler from './playerMoveHandler.js';
import disconnectHandler from './disconnectHandler.js';
import cancelMatchmakingHandler from './cancelMatchmakingHandler.js';
import { pauseGameHandler, resumeGameHandler } from './pauseResumeHandler.js';
import { setUserSocket, setUserStatus } from '../utils/redisClient.js';

/**
 * Main handler for all game-related socket events
 */
const gameEventsHandler = (io, socket) => {
    console.log(`Game handler initialized for socket: ${socket.id}`);

    const userId = socket.user.uid;

    // Store user socket mapping
    setUserSocket(userId, socket.id);
    setUserStatus(userId, 'online');

    console.log(`User ${userId} connected with socket ${socket.id}`);

    // Matchmaking events
    socket.on('find_game', () => {
        console.log(`[find_game] User ${userId}`);
        findGameHandler(io, socket);
    });

    socket.on('cancel_matchmaking', () => {
        console.log(`[cancel_matchmaking] User ${userId}`);
        cancelMatchmakingHandler(io, socket);
    });

    // Game events
    socket.on('player_move', (data) => {
        console.log(`[player_move] User ${userId}, Move: ${data.move}`);
        playerMoveHandler(io, socket, data);
    });
    // Disconnection
    socket.on('disconnect', () => {
        console.log(`[disconnect] User ${userId}, Socket: ${socket.id}`);
        disconnectHandler(io, socket);
    });
};

export default gameEventsHandler;