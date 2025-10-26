import {
    removeFromQueue,
    deleteUserStatus,
    deleteUserSocket,
    getUserStatus,
    getGameRoom,
    updateGameRoom,
    setUserStatus,
} from '../utils/redisClient.js';
import { GameStatus, calculateResult, saveGameResult } from '../services/gameService.js';

/**
 * Handler for player disconnection
 */
const disconnectHandler = async (io, socket) => {
    const userId = socket.user.uid;

    try {
        console.log(`User disconnecting: ${userId} (socket: ${socket.id})`);

        // Get user status
        const userStatus = await getUserStatus(userId);

        if (userStatus === 'queued') {
            // Remove from matchmaking queue
            await removeFromQueue(userId);
            console.log(`Removed ${userId} from matchmaking queue`);
        } else if (userStatus?.startsWith('in_game:')) {
            // Handle game disconnection
            const gameId = userStatus.replace('in_game:', '');
            await handleGameDisconnect(io, gameId, userId);
        }

        // Clean up user data
        await deleteUserStatus(userId);
        await deleteUserSocket(userId);

        console.log(`User ${userId} cleanup completed`);

    } catch (error) {
        console.error('Error in disconnectHandler:', error);
    }
};

/**
 * Handle player disconnection from active game
 */
const handleGameDisconnect = async (io, gameId, userId) => {
    try {
        const gameState = await getGameRoom(gameId);

        if (!gameState) {
            console.log(`Game ${gameId} not found for disconnect`);
            return;
        }

        // Only handle if game is active
        if (gameState.status !== GameStatus.ACTIVE) {
            return;
        }

        // Determine which player disconnected
        const isPlayer1 = userId === gameState.player1.uid;
        const opponentId = isPlayer1 ? gameState.player2.uid : gameState.player1.uid;

        // Award win to opponent by forfeit
        const winner = isPlayer1 ? 'player2' : 'player1';

        const finalState = {
            ...gameState,
            phase: 'result',
            status: GameStatus.FINISHED,
            winner,
            isTie: false,
            message: `${isPlayer1 ? gameState.player1.name : gameState.player2.name} disconnected. ${isPlayer1 ? gameState.player2.name : gameState.player1.name} wins!`,
        };

        // Update game state
        await updateGameRoom(gameId, {
            phase: finalState.phase,
            status: finalState.status,
            winner: finalState.winner,
            isTie: finalState.isTie,
            message: finalState.message,
        });

        // Save result to database
        await saveGameResult(finalState);

        // Update opponent status
        await setUserStatus(opponentId, 'online');

        // Notify opponent
        io.to(gameId).emit('player_disconnected', {
            gameId,
            disconnectedPlayer: userId,
            winner: finalState.winner,
            message: finalState.message,
        });

        io.to(gameId).emit('game_over', {
            gameId,
            winner: finalState.winner,
            isTie: false,
            message: finalState.message,
            player1: finalState.player1,
            player2: finalState.player2,
            reason: 'disconnect',
        });

        console.log(`Game ${gameId} ended due to player disconnect`);

    } catch (error) {
        console.error('Error handling game disconnect:', error);
    }
};

export default disconnectHandler;
