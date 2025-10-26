import {
    removeFromQueue,
    getUserStatus,
    setUserStatus,
} from '../utils/redisClient.js';

/**
 * Handler for canceling matchmaking
 */
const cancelMatchmakingHandler = async (io, socket) => {
    const userId = socket.user.uid;

    try {
        const userStatus = await getUserStatus(userId);

        if (userStatus !== 'queued') {
            socket.emit('cancel_matchmaking_error', {
                message: 'You are not in the queue'
            });
            return;
        }

        // Remove from queue
        await removeFromQueue(userId);
        await setUserStatus(userId, 'online');

        socket.emit('matchmaking_cancelled', {
            message: 'Matchmaking cancelled',
            status: 'cancelled'
        });

        console.log(`User ${userId} cancelled matchmaking`);

    } catch (error) {
        console.error('Error in cancelMatchmakingHandler:', error);
        socket.emit('cancel_matchmaking_error', {
            message: 'Failed to cancel matchmaking'
        });
    }
};

export default cancelMatchmakingHandler;
