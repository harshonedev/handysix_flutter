import { getUserById } from '../services/userService.js';
import {
    addToQueue,
    getQueueLength,
    popFromQueue,
    setUserStatus,
    getUserStatus,
    getUserSocket,
    saveGameRoom,
    setUserSocket,
} from '../utils/redisClient.js';
import { createGameState, GamePhase } from '../services/gameService.js';

/**
 * Handler for matchmaking - finds opponent and creates game
 */
const findGameHandler = async (io, socket) => {
    const userId = socket.user.uid;

    try {
        // 1. Check if user is already in a game or queue
        const userStatus = await getUserStatus(userId);

        if (userStatus === 'queued' || userStatus?.startsWith('in_game:')) {
            console.log(`User ${userId} is already ${userStatus}. Ignoring find_game.`);
            socket.emit('matchmaking_error', {
                message: 'You are already in a queue or game.'
            });
            return;
        }

        console.log(`User ${userId} is looking for a game...`);

        // 2. Add user to the matchmaking queue
        await addToQueue(userId);
        await setUserStatus(userId, 'queued');

        socket.emit('matchmaking_status', {
            message: 'Searching for opponent...',
            status: 'queued'
        });

        // 3. Check if there are enough players to start a match
        const queueLength = await getQueueLength();

        if (queueLength >= 2) {
            console.log('Match found! Creating game...');

            // 4. Pop two players from the queue
            const player1_uid = await popFromQueue();
            const player2_uid = await popFromQueue();

            // 5. Get the socket IDs for both players
            const player1SocketId = await getUserSocket(player1_uid);
            const player2SocketId = await getUserSocket(player2_uid);

            // Find the actual socket objects
            const player1Socket = io.sockets.sockets.get(player1SocketId);
            const player2Socket = io.sockets.sockets.get(player2SocketId);

            // Check if sockets still exist
            if (!player1Socket || !player2Socket) {
                console.log('Matchmaking failed, one player disconnected.');

                // Push users back into queue if they are still connected
                if (player1Socket) {
                    await addToQueue(player1_uid);
                    await setUserStatus(player1_uid, 'queued');
                }
                if (player2Socket) {
                    await addToQueue(player2_uid);
                    await setUserStatus(player2_uid, 'queued');
                }
                return;
            }

            // 6. Fetch user data from database
            const player1Data = await getUserById(player1_uid);
            const player2Data = await getUserById(player2_uid);

            if (!player1Data || !player2Data) {
                console.error('Failed to fetch user data');
                socket.emit('matchmaking_error', {
                    message: 'Failed to create game. Please try again.'
                });
                return;
            }

            // 7. Create the initial game state
            const gameState = createGameState(player1Data, player2Data);

            // 8. Store the game state in Redis
            const gameDataForRedis = {
                ...gameState,
                player1: JSON.stringify(gameState.player1),
                player2: JSON.stringify(gameState.player2),
            };

            await saveGameRoom(gameState.id, gameDataForRedis);

            // 9. Update user statuses to "in_game"
            await setUserStatus(player1_uid, `in_game:${gameState.id}`);
            await setUserStatus(player2_uid, `in_game:${gameState.id}`);

            // 10. Create a Socket.io room and add both players
            player1Socket.join(gameState.id);
            player2Socket.join(gameState.id);

            // 11. Emit 'game_matched' to both players
            io.to(gameState.id).emit('game_matched', {
                gameId: gameState.id,
                phase: gameState.phase,
                player1: gameState.player1,
                player2: gameState.player2,
                whoBattingFirst: gameState.whoBattingFirst,
                message: gameState.message,
                status: 'matched',
            });

            console.log(`Game ${gameState.id} created for ${player1_uid} and ${player2_uid}`);

            // 12. Start game countdown after 3 seconds
            setTimeout(() => {
                io.to(gameState.id).emit('game_start_countdown', {
                    gameId: gameState.id,
                    countdown: 3,
                    message: 'Game starting soon...',
                });
            }, 1000);
        }
    } catch (error) {
        console.error('Error in findGameHandler:', error);
        socket.emit('matchmaking_error', {
            message: 'An error occurred while searching for a game.'
        });
    }
};

export default findGameHandler;
