import { createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

// Redis client configuration
const redisClient = createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379',
    socket: {
        reconnectStrategy: (retries) => {
            if (retries > 10) {
                console.error('Redis: Too many reconnection attempts, giving up');
                return new Error('Too many retries');
            }
            // Exponential backoff: wait longer between each retry
            return Math.min(retries * 100, 3000);
        }
    }
});

// Redis client event handlers
redisClient.on('connect', () => {
    console.log('Redis: Connecting...');
});

redisClient.on('ready', () => {
    console.log('Redis: Connected and ready');
});

redisClient.on('error', (err) => {
    console.error('Redis Client Error:', err);
});

redisClient.on('end', () => {
    console.log('Redis: Connection closed');
});

// Connect to Redis
const connectRedis = async () => {
    try {
        if (!redisClient.isOpen) {
            await redisClient.connect();
        }
    } catch (error) {
        console.error('Failed to connect to Redis:', error);
        throw error;
    }
};

// Graceful shutdown
const disconnectRedis = async () => {
    try {
        if (redisClient.isOpen) {
            await redisClient.quit();
            console.log('Redis: Disconnected gracefully');
        }
    } catch (error) {
        console.error('Error disconnecting from Redis:', error);
    }
};

export { redisClient, connectRedis, disconnectRedis };
