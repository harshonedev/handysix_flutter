import findGameHandler from "./findGameHandler";
const gameEventsHandler = (io, socket) => {
    console.log(`Game handler initialized for socket: ${socket.id}`);

    const userId = socket.user.uid;
    redisClient.set(`user_socket:${userId}`, socket.id);

    // Set user status to online
    redisClient.set(`user_status:${userId}`, 'online');


    socket.on('find_game', () => {
        console.log(`User ${userId} is looking for a game.`);
        findGameHandler(io, socket);
    });


    // Handle disconnection
    socket.on('disconnect', () => {
        console.log(`Client disconnected: ${socket.id}`);
    });

};

export default gameEventsHandler;