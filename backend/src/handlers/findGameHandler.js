import { getUserById } from '../services/userService.js';
import { redisClient } from '../utils/redisClient.js';
const findGameHandler = async (io, socket) => {
    const userId = socket.request.user.id;

    // 1. Check if user is already in a game or queue
    const userStatus = await redisClient.get(`user_status:${userId}`);

    if (userStatus === 'queued' || userStatus.startsWith('in_game:')) {
        console.log(`User ${userId} is already ${userStatus}. Ignoring find_game.`);
        socket.emit('matchmaking_error', { message: 'You are already in a queue or game.' });
        return;
    }

    console.log(`User ${userId} is looking for a game...`);

    // 2. Add user to the matchmaking queue (a Redis List)
    await redisClient.lPush('matchmaking_queue', userId);
    await redisClient.set(`user_status:${userId}`, 'queued');
    socket.emit('matchmaking_status', { message: 'You are in the queue...' });

    // 3. Check if there are enough players to start a match
    const queueLength = await redisClient.lLen('matchmaking_queue');

    if (queueLength >= 2) {
        console.log('Match found! Creating game...');

        // 4. Pop two players from the queue
        const player1_id = await redisClient.rPop('matchmaking_queue');
        const player2_id = await redisClient.rPop('matchmaking_queue');

        // 5. Get the socket IDs for both players
        const player1SocketId = await redisClient.get(`user_socket:${player1_id}`);
        const player2SocketId = await redisClient.get(`user_socket:${player2_id}`);

        // Find the actual socket objects
        const player1Socket = io.sockets.sockets.get(player1SocketId);
        const player2Socket = io.sockets.sockets.get(player2SocketId);

        // (Check if sockets still exist, in case one disconnected right as match was made)
        if (!player1Socket || !player2Socket) {
            console.log('Matchmaking failed, one player disconnected.');
            // (Push users back into queue if they are still connected)
            if (player1Socket) {
                redisClient.lPush('matchmaking_queue', player1_id);
                redisClient.set(`user_status:${player1_id}`, 'queued');
            }
            if (player2Socket) {
                redisClient.lPush('matchmaking_queue', player2_id);
                redisClient.set(`user_status:${player2_id}`, 'queued');
            }
            return;
        }

        // 6. Create the game
        const gameId = `game_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;


        // 7. Define the initial game state

        // fetch usernames and avatars from database
        const player1 = await getUserById(player1_id);
        const player2 = await getUserById(player2_id);

        const whoBatFirst = Math.random() < 0.5 ? player1_id : player2_id;

        const initialGameState = {
            gameId: gameId,
            player1_id: player1_id,
            player2_id: player2_id,
            player1_name: player1.name,
            player2_name: player2.name,
            player1_avatar: player1.profilePicture,
            player2_avatar: player2.profilePicture,
            game_phase: 'matched', // other phases: toss, inings1, innings2, completed
            current_batter: whoBatFirst,
            current_bowler: whoBatFirst === player1_id ? player2_id : player1_id,
            toss_winner: whoBatFirst,
            innings: 1,
            balls_bowled: 0,
            max_balls: 6, // 1 over
            player1_score: 0,
            player2_score: 0,
            player1_scorePerBall: [],
            player2_scorePerBall: [],
            batter_move: -1,
            bowler_move: -1
        };

        // 8. Store the new game state in a Redis Hash
        await redisClient.hSet(`game:${gameId}`, initialGameState);

        // 9. Update user statuses to "in_game"
        await redisClient.set(`user_status:${player1_id}`, `in_game:${gameId}`);
        await redisClient.set(`user_status:${player2_id}`, `in_game:${gameId}`);

        // 10. Create a Socket.io room and add both players
        player1Socket.join(gameId);
        player2Socket.join(gameId);

        // 11. Emit 'game_start' to BOTH players in the room
        io.to(gameId).emit('game_start', initialGameState);
        console.log(`Game ${gameId} started for ${player1_id} and ${player2_id}`);
    }

};
export default findGameHandler;
