import { redisClient, isRedisAvailable } from '../config/redis.config.js';

/**
 * Redis utility functions for game state management
 * Note: These functions return null/false when Redis is unavailable
 */

// Game Room Keys
export const getGameRoomKey = (gameId) => `game:${gameId}`;
export const getUserStatusKey = (userId) => `user_status:${userId}`;
export const getUserSocketKey = (userId) => `user_socket:${userId}`;
export const getMatchmakingQueueKey = () => 'matchmaking_queue';

// Game Room Operations
export const saveGameRoom = async (gameId, gameData) => {
    if (!isRedisAvailable()) {
        console.warn('Redis not available - skipping saveGameRoom');
        return false;
    }
    try {
        const key = getGameRoomKey(gameId);
        await redisClient.hSet(key, gameData);
        await redisClient.expire(key, 3600); // 1 hour expiry
        return true;
    } catch (error) {
        console.error('Redis saveGameRoom error:', error.message);
        return false;
    }
};

export const getGameRoom = async (gameId) => {
    if (!isRedisAvailable()) {
        console.warn('Redis not available - skipping getGameRoom');
        return null;
    }
    try {
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
    } catch (error) {
        console.error('Redis getGameRoom error:', error.message);
        return null;
    }
};

export const updateGameRoom = async (gameId, updates) => {
    if (!isRedisAvailable()) {
        console.warn('Redis not available - skipping updateGameRoom');
        return false;
    }
    try {
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
    } catch (error) {
        console.error('Redis updateGameRoom error:', error.message);
        return false;
    }
};

export const deleteGameRoom = async (gameId) => {
    if (!isRedisAvailable()) return false;
    try {
        const key = getGameRoomKey(gameId);
        await redisClient.del(key);
        return true;
    } catch (error) {
        console.error('Redis deleteGameRoom error:', error.message);
        return false;
    }
};

// User Status Operations
export const setUserStatus = async (userId, status) => {
    if (!isRedisAvailable()) return false;
    try {
        await redisClient.set(getUserStatusKey(userId), status, { EX: 3600 });
        return true;
    } catch (error) {
        console.error('Redis setUserStatus error:', error.message);
        return false;
    }
};

export const getUserStatus = async (userId) => {
    if (!isRedisAvailable()) return null;
    try {
        return await redisClient.get(getUserStatusKey(userId));
    } catch (error) {
        console.error('Redis getUserStatus error:', error.message);
        return null;
    }
};

export const deleteUserStatus = async (userId) => {
    if (!isRedisAvailable()) return false;
    try {
        await redisClient.del(getUserStatusKey(userId));
        return true;
    } catch (error) {
        console.error('Redis deleteUserStatus error:', error.message);
        return false;
    }
};

// User Socket Mapping
export const setUserSocket = async (userId, socketId) => {
    if (!isRedisAvailable()) return false;
    try {
        await redisClient.set(getUserSocketKey(userId), socketId, { EX: 3600 });
        return true;
    } catch (error) {
        console.error('Redis setUserSocket error:', error.message);
        return false;
    }
};

export const getUserSocket = async (userId) => {
    if (!isRedisAvailable()) return null;
    try {
        return await redisClient.get(getUserSocketKey(userId));
    } catch (error) {
        console.error('Redis getUserSocket error:', error.message);
        return null;
    }
};

export const deleteUserSocket = async (userId) => {
    if (!isRedisAvailable()) return false;
    try {
        await redisClient.del(getUserSocketKey(userId));
        return true;
    } catch (error) {
        console.error('Redis deleteUserSocket error:', error.message);
        return false;
    }
};

// Matchmaking Queue
export const addToQueue = async (userId) => {
    if (!isRedisAvailable()) return false;
    try {
        await redisClient.lPush(getMatchmakingQueueKey(), userId);
        return true;
    } catch (error) {
        console.error('Redis addToQueue error:', error.message);
        return false;
    }
};

export const removeFromQueue = async (userId) => {
    if (!isRedisAvailable()) return false;
    try {
        await redisClient.lRem(getMatchmakingQueueKey(), 0, userId);
        return true;
    } catch (error) {
        console.error('Redis removeFromQueue error:', error.message);
        return false;
    }
};

export const getQueueLength = async () => {
    if (!isRedisAvailable()) return 0;
    try {
        return await redisClient.lLen(getMatchmakingQueueKey());
    } catch (error) {
        console.error('Redis getQueueLength error:', error.message);
        return 0;
    }
};

export const popFromQueue = async () => {
    if (!isRedisAvailable()) return null;
    try {
        return await redisClient.rPop(getMatchmakingQueueKey());
    } catch (error) {
        console.error('Redis popFromQueue error:', error.message);
        return null;
    }
};
