import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

const prisma = new PrismaClient();

/**
 * Game state constants matching Flutter enums
 */
export const GamePhase = {
    TOSS: 'toss',
    START_INNINGS: 'startInnigs',
    INNINGS1: 'innings1',
    INNINGS2: 'innings2',
    RESULT: 'result',
    WAITING: 'waiting',
};

export const GameStatus = {
    ACTIVE: 'active',
    WAITING: 'waiting',
    INACTIVE: 'inactive',
    FINISHED: 'finished',
    PAUSED: 'paused',
};

export const PlayerType = {
    PLAYER1: 'player1',
    PLAYER2: 'player2',
};

/**
 * Create initial game state
 */
export const createGameState = (player1Data, player2Data) => {
    const whoBatFirst = Math.random() < 0.5 ? PlayerType.PLAYER1 : PlayerType.PLAYER2;

    const player1 = {
        uid: player1Data.uid,
        name: player1Data.name,
        avatarUrl: player1Data.profilePicture || '',
        type: PlayerType.PLAYER1,
        score: 0,
        ballsFaced: 0,
        isOut: false,
        isBatting: whoBatFirst === PlayerType.PLAYER1,
        movesPerBall: [],
    };

    const player2 = {
        uid: player2Data.uid,
        name: player2Data.name,
        avatarUrl: player2Data.profilePicture || '',
        type: PlayerType.PLAYER2,
        score: 0,
        ballsFaced: 0,
        isOut: false,
        isBatting: whoBatFirst === PlayerType.PLAYER2,
        movesPerBall: [],
    };

    return {
        id: uuidv4(),
        phase: GamePhase.TOSS,
        status: GameStatus.ACTIVE,
        player1,
        player2,
        whoBattingFirst: whoBatFirst,
        player1choice: 0,
        player2choice: 0,
        currentMove: 0,
        innings: 1,
        ballsBowled: 0,
        maxBalls: 6,
        target: null,
        winner: null,
        isTie: false,
        result: null,
        message: whoBatFirst === PlayerType.PLAYER1
            ? `${player1.name} bats first!`
            : `${player2.name} bats first!`,
        createdAt: Date.now(),
    };
};

/**
 * Process player moves and determine outcome
 */
export const processMoves = (gameState, player1Move, player2Move) => {
    const { player1, player2, phase, innings } = gameState;

    // Determine who is batting
    const isBatting1 = player1.isBatting;
    const batterMove = isBatting1 ? player1Move : player2Move;
    const bowlerMove = isBatting1 ? player2Move : player1Move;

    let result = {
        isOut: false,
        runs: 0,
        message: '',
    };

    // Check if out (same move)
    if (player1Move === player2Move) {
        result.isOut = true;
        result.message = 'OUT!';

        // Update batting player
        if (isBatting1) {
            player1.isOut = true;
            player1.movesPerBall.push(player1Move);
            player1.ballsFaced++;
        } else {
            player2.isOut = true;
            player2.movesPerBall.push(player2Move);
            player2.ballsFaced++;
        }
    } else {
        // Runs scored
        result.runs = batterMove;
        result.message = `${result.runs} ${result.runs === 1 ? 'run' : 'runs'}!`;

        // Update batting player
        if (isBatting1) {
            player1.score += result.runs;
            player1.movesPerBall.push(player1Move);
            player1.ballsFaced++;
        } else {
            player2.score += result.runs;
            player2.movesPerBall.push(player2Move);
            player2.ballsFaced++;
        }

        // Update bowling player (just track the ball)
        if (isBatting1) {
            player2.movesPerBall.push(player2Move);
        } else {
            player1.movesPerBall.push(player1Move);
        }
    }

    // Update balls bowled
    gameState.ballsBowled = isBatting1 ? player1.ballsFaced : player2.ballsFaced;

    return {
        ...gameState,
        player1,
        player2,
        player1choice: player1Move,
        player2choice: player2Move,
        currentMove: gameState.currentMove + 1,
        ...result,
    };
};

/**
 * Check if innings should end
 */
export const checkInningsEnd = (gameState) => {
    const { player1, player2, ballsBowled, maxBalls, innings, target } = gameState;

    const battingPlayer = player1.isBatting ? player1 : player2;
    const currentScore = battingPlayer.score;

    // Check if batsman is out
    if (battingPlayer.isOut) {
        return { shouldEnd: true, reason: 'out' };
    }

    // Check if max balls reached
    if (ballsBowled >= maxBalls) {
        return { shouldEnd: true, reason: 'overs_complete' };
    }

    // In innings 2, check if target is chased
    if (innings === 2 && target !== null && currentScore > target) {
        return { shouldEnd: true, reason: 'target_chased' };
    }

    return { shouldEnd: false };
};

/**
 * Transition to next innings
 */
export const transitionToInnings2 = (gameState) => {
    const { player1, player2 } = gameState;

    // Swap batting
    player1.isBatting = !player1.isBatting;
    player2.isBatting = !player2.isBatting;

    // Reset out status and balls for new innings
    player1.isOut = false;
    player2.isOut = false;

    // Set target
    const target = player1.isBatting ? player2.score : player1.score;

    return {
        ...gameState,
        phase: GamePhase.START_INNINGS,
        innings: 2,
        ballsBowled: 0,
        player1,
        player2,
        player1choice: 0,
        player2choice: 0,
        target,
        message: `Target: ${target + 1} runs`,
    };
};

/**
 * Calculate final result
 */
export const calculateResult = (gameState) => {
    const { player1, player2 } = gameState;

    let winner = null;
    let isTie = false;
    let message = '';

    if (player1.score > player2.score) {
        winner = PlayerType.PLAYER1;
        message = `${player1.name} wins by ${player1.score - player2.score} runs!`;
    } else if (player2.score > player1.score) {
        winner = PlayerType.PLAYER2;
        message = `${player2.name} wins by ${player2.score - player1.score} runs!`;
    } else {
        isTie = true;
        message = "It's a tie!";
    }

    return {
        ...gameState,
        phase: GamePhase.RESULT,
        status: GameStatus.FINISHED,
        winner,
        isTie,
        message,
    };
};

/**
 * Save game result to database
 */
export const saveGameResult = async (gameState) => {
    try {
        const { player1, player2, winner, isTie } = gameState;

        // Update player1 stats
        await updatePlayerStats(player1.uid, {
            matches: 1,
            wins: winner === PlayerType.PLAYER1 ? 1 : 0,
            losses: winner === PlayerType.PLAYER2 ? 1 : 0,
            runs: player1.score,
        });

        // Update player2 stats
        await updatePlayerStats(player2.uid, {
            matches: 1,
            wins: winner === PlayerType.PLAYER2 ? 1 : 0,
            losses: winner === PlayerType.PLAYER1 ? 1 : 0,
            runs: player2.score,
        });

        console.log(`Game result saved: ${gameState.id}`);
        return true;
    } catch (error) {
        console.error('Error saving game result:', error);
        return false;
    }
};

/**
 * Update player statistics
 */
const updatePlayerStats = async (uid, updates) => {
    try {
        const user = await prisma.user.findUnique({
            where: { uid },
            include: { Stats: true },
        });

        if (!user) {
            console.error(`User not found: ${uid}`);
            return;
        }

        if (user.Stats) {
            // Update existing stats
            await prisma.stats.update({
                where: { id: user.Stats.id },
                data: {
                    matches: { increment: updates.matches },
                    wins: { increment: updates.wins },
                    losses: { increment: updates.losses },
                    runs: { increment: updates.runs },
                },
            });
        } else {
            // Create new stats
            await prisma.stats.create({
                data: {
                    userId: user.id,
                    matches: updates.matches,
                    wins: updates.wins,
                    losses: updates.losses,
                    runs: updates.runs,
                },
            });
        }
    } catch (error) {
        console.error(`Error updating stats for ${uid}:`, error);
    }
};
