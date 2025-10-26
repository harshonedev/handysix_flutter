import { createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

let redisClient = null;
let redisConnected = false;

// Only create Redis client if URL is provided
if (process.env.REDIS_URL) {
    // Redis client configuration
    redisClient = createClient({
        username: process.env.REDIS_USERNAME || 'default',
        password: process.env.REDIS_PASSWORD || '',
        socket: {
            host: process.env.REDIS_HOST || 'localhost',
            port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
            reconnectStrategy: (retries) => {
                if (retries > 3) {
                    console.error('Redis: Too many reconnection attempts, giving up');
                    return false; // Stop reconnecting
                }
                // Exponential backoff: wait longer between each retry
                return Math.min(retries * 100, 3000);
            },
            connectTimeout: 10000 // 10 second timeout
        }
    });

    // Redis client event handlers
    redisClient.on('connect', () => {
        console.log('Redis: Connecting...');
    });

    redisClient.on('ready', () => {
        console.log('Redis: Connected and ready');
        redisConnected = true;
    });

    redisClient.on('error', (err) => {
        console.error('Redis Client Error:', err.message);
        redisConnected = false;
    });

    redisClient.on('end', () => {
        console.log('Redis: Connection closed');
        redisConnected = false;
    });
} else {
    console.warn('⚠️  REDIS_URL not configured - Redis features disabled');
}

// Connect to Redis
const connectRedis = async () => {
    if (!redisClient) {
        console.log('Redis: Skipping connection (not configured)');
        return;
    }

    try {
        if (!redisClient.isOpen) {
            console.log('Redis: Attempting to connect...');
            await redisClient.connect();
            console.log('Redis: Connection successful');
            redisConnected = true;
        }
    } catch (error) {
        console.error('Failed to connect to Redis:', error.message);
        console.warn('⚠️  Server will continue without Redis. Multiplayer features may be limited.');
        redisConnected = false;
        // Don't throw - allow server to start without Redis
    }
};

// Graceful shutdown
const disconnectRedis = async () => {
    if (!redisClient) return;

    try {
        if (redisClient.isOpen) {
            await redisClient.quit();
            console.log('Redis: Disconnected gracefully');
            redisConnected = false;
        }
    } catch (error) {
        console.error('Error disconnecting from Redis:', error);
    }
};

// Check if Redis is connected and available
const isRedisAvailable = () => {
    return redisClient && redisClient.isOpen && redisClient.isReady && redisConnected;
};

export { redisClient, connectRedis, disconnectRedis, isRedisAvailable };
