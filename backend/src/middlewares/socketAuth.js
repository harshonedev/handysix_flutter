/**
 * Socket.IO middleware for authentication
 * Extracts user info from socket handshake
 */
const socketAuthMiddleware = (socket, next) => {
    try {
        // Extract user data from handshake auth
        const { uid, name, email } = socket.handshake.auth;

        if (!uid) {
            return next(new Error('Authentication required'));
        }

        // Attach user to socket
        socket.user = {
            uid,
            name: name || 'Guest',
            email: email || null,
        };

        console.log(`Socket authenticated: ${uid} (${socket.id})`);
        next();

    } catch (error) {
        console.error('Socket auth error:', error);
        next(new Error('Authentication failed'));
    }
};

export default socketAuthMiddleware;
