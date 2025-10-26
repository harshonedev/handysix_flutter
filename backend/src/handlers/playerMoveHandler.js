import {
    getGameRoom,
    updateGameRoom,
    setUserStatus,
} from '../utils/redisClient.js';
import {
    processMoves,
    checkInningsEnd,
    transitionToInnings2,
    calculateResult,
    saveGameResult,
    GamePhase,
    GameStatus,
} from '../services/gameService.js';

/**
 * Handler for player move submission
 */
const playerMoveHandler = async (io, socket, data) => {
    const userId = socket.user.uid;
    const { gameId, move } = data;

    try {
        // Validate input
        if (!gameId || move === undefined || move < 1 || move > 6) {
            socket.emit('move_error', { message: 'Invalid move data' });
            return;
        }

        // Get current game state
        const gameState = await getGameRoom(gameId);

        if (!gameState) {
            socket.emit('move_error', { message: 'Game not found' });
            return;
        }

        // Check if game is active
        if (gameState.status !== GameStatus.ACTIVE) {
            socket.emit('move_error', { message: 'Game is not active' });
            return;
        }

        // Check if it's innings phase
        if (gameState.phase !== GamePhase.INNINGS1 && gameState.phase !== GamePhase.INNINGS2) {
            socket.emit('move_error', { message: 'Not in innings phase' });
            return;
        }

        // Determine which player made the move
        const isPlayer1 = userId === gameState.player1.uid;
        const isPlayer2 = userId === gameState.player2.uid;

        if (!isPlayer1 && !isPlayer2) {
            socket.emit('move_error', { message: 'You are not in this game' });
            return;
        }

        // Update move
        const updates = {};
        if (isPlayer1) {
            if (gameState.player1choice !== 0) {
                socket.emit('move_error', { message: 'Move already submitted' });
                return;
            }
            updates.player1choice = move;
        } else {
            if (gameState.player2choice !== 0) {
                socket.emit('move_error', { message: 'Move already submitted' });
                return;
            }
            updates.player2choice = move;
        }

        await updateGameRoom(gameId, updates);

        // Notify the room that a player has made their move
        io.to(gameId).emit('player_moved', {
            gameId,
            playerId: userId,
            playerType: isPlayer1 ? 'player1' : 'player2',
        });

        // Get updated game state
        const updatedGameState = await getGameRoom(gameId);

        // Check if both players have moved
        if (updatedGameState.player1choice !== 0 && updatedGameState.player2choice !== 0) {
            // Process the moves
            await processGameMoves(io, gameId, updatedGameState);
        }

    } catch (error) {
        console.error('Error in playerMoveHandler:', error);
        socket.emit('move_error', { message: 'Failed to process move' });
    }
};

/**
 * Process moves from both players
 */
const processGameMoves = async (io, gameId, gameState) => {
    try {
        // Calculate result of the moves
        const resultState = processMoves(
            gameState,
            gameState.player1choice,
            gameState.player2choice
        );

        // Update game state with result
        await updateGameRoom(gameId, {
            player1: JSON.stringify(resultState.player1),
            player2: JSON.stringify(resultState.player2),
            player1choice: resultState.player1choice,
            player2choice: resultState.player2choice,
            currentMove: resultState.currentMove,
            ballsBowled: resultState.ballsBowled,
        });

        // Emit move result to both players
        io.to(gameId).emit('move_result', {
            gameId,
            player1Move: resultState.player1choice,
            player2Move: resultState.player2choice,
            isOut: resultState.isOut,
            runs: resultState.runs,
            message: resultState.message,
            player1: resultState.player1,
            player2: resultState.player2,
        });

        // Wait 2 seconds before checking innings end
        setTimeout(async () => {
            await checkAndProgressGame(io, gameId, resultState);
        }, 2000);

    } catch (error) {
        console.error('Error processing game moves:', error);
        io.to(gameId).emit('game_error', { message: 'Error processing moves' });
    }
};

/**
 * Check if innings should end and progress game
 */
const checkAndProgressGame = async (io, gameId, gameState) => {
    try {
        const { shouldEnd, reason } = checkInningsEnd(gameState);

        if (shouldEnd) {
            if (gameState.innings === 1) {
                // Transition to innings 2
                const innings2State = transitionToInnings2(gameState);

                await updateGameRoom(gameId, {
                    phase: innings2State.phase,
                    innings: innings2State.innings,
                    ballsBowled: innings2State.ballsBowled,
                    player1: JSON.stringify(innings2State.player1),
                    player2: JSON.stringify(innings2State.player2),
                    player1choice: 0,
                    player2choice: 0,
                    target: innings2State.target,
                    message: innings2State.message,
                });

                io.to(gameId).emit('innings_end', {
                    gameId,
                    innings: 1,
                    reason,
                    message: `Innings 1 ended. ${innings2State.message}`,
                    player1: innings2State.player1,
                    player2: innings2State.player2,
                });

                // Start innings 2 countdown
                setTimeout(() => {
                    io.to(gameId).emit('innings_start', {
                        gameId,
                        innings: 2,
                        target: innings2State.target,
                        message: innings2State.message,
                    });

                    // Update phase to active innings
                    updateGameRoom(gameId, { phase: GamePhase.INNINGS2 });
                }, 3000);

            } else {
                // Game over - calculate result
                const finalState = calculateResult(gameState);

                await updateGameRoom(gameId, {
                    phase: finalState.phase,
                    status: finalState.status,
                    winner: finalState.winner,
                    isTie: finalState.isTie,
                    message: finalState.message,
                });

                // Save result to database
                await saveGameResult(finalState);

                // Update user statuses
                await setUserStatus(finalState.player1.uid, 'online');
                await setUserStatus(finalState.player2.uid, 'online');

                io.to(gameId).emit('game_over', {
                    gameId,
                    winner: finalState.winner,
                    isTie: finalState.isTie,
                    message: finalState.message,
                    player1: finalState.player1,
                    player2: finalState.player2,
                });

                console.log(`Game ${gameId} completed. Winner: ${finalState.winner || 'Tie'}`);
            }
        } else {
            // Continue current innings - reset choices
            await updateGameRoom(gameId, {
                player1choice: 0,
                player2choice: 0,
            });

            io.to(gameId).emit('continue_innings', {
                gameId,
                message: 'Choose your move!',
            });
        }

    } catch (error) {
        console.error('Error checking game progress:', error);
        io.to(gameId).emit('game_error', { message: 'Error progressing game' });
    }
};

export default playerMoveHandler;
