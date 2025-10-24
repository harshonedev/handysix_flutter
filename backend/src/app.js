import express from 'express';
import { createServer } from 'http';
import morgan from 'morgan';
import dotenv from 'dotenv';
import routes from './routes.js';
import { connectRedis, disconnectRedis } from './config/redis.config.js';
import { Server } from 'socket.io';
import gameEventsHandler from './handlers/gameEventsHandler.js';

const app = express();
const httpServer = createServer(app);

// Load environment variables from .env file
dotenv.config();

const port = process.env.PORT || 5000;

// Middleware to parse JSON bodies
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));


// Mount API routes
app.use('/api/v1', routes);

// Basic route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to Handy Six API' });
});

// error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        error: 'Internal Server Error',
        details: err.message || 'An unexpected error occurred'
    });
});

// 404 handler for undefined routes
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        details: 'The requested resource could not be found'
    });
});

// Connect Redis 
await connectRedis();

// Initialize Socket.IO
const io = new Server(httpServer, {
    cors: {
        origin: process.env.CORS_ORIGIN || '*',
        methods: ['GET', 'POST', 'PUT', 'DELETE'],
    },
    pingInterval: process.env.SOCKET_PING_INTERVAL || 10000,
    pingTimeout: process.env.SOCKET_PING_TIMEOUT || 5000,
});

// Register Socket.IO event handlers
io.on('connection', (socket) => {
    const userId = socket.user.uid;
    console.log(`User connected: ${userId} with socket: ${socket.id}`);

    // Initialize game handler
    gameEventsHandler(io, socket);


});

// Start HTTP server
httpServer.listen(port, () => {
    console.log(`Server running on port ${port}`);
    console.log(`WebSocket server ready`);
});



