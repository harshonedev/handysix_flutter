import express from 'express';
import morgan from 'morgan';
import dotenv from 'dotenv';
import routes from './routes.js';

const app = express();

// Load environment variables from .env file
dotenv.config();

const port = process.env.PORT || 8080;

// Middleware to parse JSON bodies
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));


// Mount API routes
app.use('/api', routes);

// Basic route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to Hand Cricket API' });
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


// Start server
app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
