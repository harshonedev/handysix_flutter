import { redisClient } from '../config/redis.config.js';

/**
 * Redis utility functions for game state management
 */

// Game Room Keys
export const getGameRoomKey = (gameId) => `game:${gameId}`;
export const getUserStatusKey = (userId) => `user_status:${userId}`;
export const getUserSocketKey = (userId) => `user_socket:${userId}`;
export const getMatchmakingQueueKey = () => 'matchmaking_queue';

// Game Room Operations
export const saveGameRoom = async (gameId, gameData) => {
    const key = getGameRoomKey(gameId);
    await redisClient.hSet(key, gameData);
    await redisClient.expire(key, 3600); // 1 hour expiry
};

export const getGameRoom = async (gameId) => {
    const key = getGameRoomKey(gameId);
    const data = await redisClient.hGetAll(key);
    if (!data || Object.keys(data).length === 0) return null;

    // Parse JSON fields
    return {
        ...data,
        player1: data.player1 ? JSON.parse(data.player1) : null,
        player2: data.player2 ? JSON.parse(data.player2) : null,
        player1_scorePerBall: data.player1_scorePerBall ? JSON.parse(data.player1_scorePerBall) : [],
        player2_scorePerBall: data.player2_scorePerBall ? JSON.parse(data.player2_scorePerBall) : [],
        player1_score: parseInt(data.player1_score || 0),
        player2_score: parseInt(data.player2_score || 0),
        balls_bowled: parseInt(data.balls_bowled || 0),
        max_balls: parseInt(data.max_balls || 6),
        batter_move: parseInt(data.batter_move || -1),
        bowler_move: parseInt(data.bowler_move || -1),
        target: data.target ? parseInt(data.target) : null,
        innings: parseInt(data.innings || 1),
    };
};

export const updateGameRoom = async (gameId, updates) => {
    const key = getGameRoomKey(gameId);
    const exists = await redisClient.exists(key);
    if (!exists) return false;

    // Stringify objects before storing
    const processedUpdates = {};
    for (const [field, value] of Object.entries(updates)) {
        if (typeof value === 'object' && value !== null) {
            processedUpdates[field] = JSON.stringify(value);
        } else {
            processedUpdates[field] = value;
        }
    }

    await redisClient.hSet(key, processedUpdates);
    return true;
};

export const deleteGameRoom = async (gameId) => {
    const key = getGameRoomKey(gameId);
    await redisClient.del(key);
};

// User Status Operations
export const setUserStatus = async (userId, status) => {
    await redisClient.set(getUserStatusKey(userId), status, { EX: 3600 });
};

export const getUserStatus = async (userId) => {
    return await redisClient.get(getUserStatusKey(userId));
};

export const deleteUserStatus = async (userId) => {
    await redisClient.del(getUserStatusKey(userId));
};

// User Socket Mapping
export const setUserSocket = async (userId, socketId) => {
    await redisClient.set(getUserSocketKey(userId), socketId, { EX: 3600 });
};

export const getUserSocket = async (userId) => {
    return await redisClient.get(getUserSocketKey(userId));
};

export const deleteUserSocket = async (userId) => {
    await redisClient.del(getUserSocketKey(userId));
};

// Matchmaking Queue
export const addToQueue = async (userId) => {
    await redisClient.lPush(getMatchmakingQueueKey(), userId);
};

export const removeFromQueue = async (userId) => {
    await redisClient.lRem(getMatchmakingQueueKey(), 0, userId);
};

export const getQueueLength = async () => {
    return await redisClient.lLen(getMatchmakingQueueKey());
};

export const popFromQueue = async () => {
    return await redisClient.rPop(getMatchmakingQueueKey());
};
