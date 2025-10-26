# HandySix Backend - Real-time Multiplayer Game Server

Socket.IO-based backend for HandySix multiplayer hand cricket game with Redis state management and MongoDB persistence.

## Architecture Overview

```
┌─────────────┐     WebSocket      ┌──────────────┐
│   Flutter   │ ◄─────────────────► │  Socket.IO   │
│    Client   │                     │    Server    │
└─────────────┘                     └──────┬───────┘
                                           │
                          ┌────────────────┼────────────────┐
                          │                │                │
                     ┌────▼────┐      ┌───▼────┐     ┌────▼─────┐
                     │  Redis  │      │ Prisma │     │ Firebase │
                     │  Cache  │      │   ORM  │     │   Auth   │
                     └─────────┘      └───┬────┘     └──────────┘
                                          │
                                     ┌────▼─────┐
                                     │ MongoDB  │
                                     └──────────┘
```

## Features

- ✅ Real-time matchmaking with queue system
- ✅ Turn-based gameplay with move validation
- ✅ Game state management in Redis
- ✅ Player statistics persistence in MongoDB
- ✅ Automatic disconnect handling with forfeit
- ✅ Pause/Resume game functionality
- ✅ Socket.IO authentication middleware

## Prerequisites

- Node.js 18+ and npm
- Redis server running on `localhost:6379` (or configure in .env)
- MongoDB Atlas account or local MongoDB instance
- Firebase project for authentication

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# Server Configuration
PORT=5000
NODE_ENV=development

# CORS Configuration
CORS_ORIGIN=*

# Redis Configuration
REDIS_URL=redis://localhost:6379

# MongoDB Configuration (Prisma)
DATABASE_URL="MONNFODB_CONNECTION_STRING_HERE"
retryWrites=true&w=majority"

# Socket.IO Configuration
SOCKET_PING_INTERVAL=10000
SOCKET_PING_TIMEOUT=5000
```

### 3. Setup Prisma

Generate Prisma client and push schema to MongoDB:

```bash
npx prisma generate
npx prisma db push
```

### 4. Start Redis

**Option A: Using Docker**
```bash
docker run -d --name redis -p 6379:6379 redis:latest
```

**Option B: Local Installation**
```bash
# Ubuntu/Debian
sudo apt-get install redis-server
sudo service redis-server start

# macOS
brew install redis
brew services start redis

# Windows
# Download from https://redis.io/download
```

Verify Redis is running:
```bash
redis-cli ping
# Should return: PONG
```

### 5. Start the Server

**Development mode with auto-reload:**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

Server will start on `http://localhost:5000` (or configured PORT)

## API Structure

### Socket.IO Events

#### Client → Server

| Event | Data | Description |
|-------|------|-------------|
| `find_game` | - | Start matchmaking |
| `cancel_matchmaking` | - | Cancel matchmaking |
| `player_move` | `{ gameId, move }` | Submit move (1-6) |
| `pause_game` | `{ gameId }` | Pause active game |
| `resume_game` | `{ gameId }` | Resume paused game |

#### Server → Client

| Event | Data | Description |
|-------|------|-------------|
| `matchmaking_status` | `{ message, status }` | Matchmaking queue status |
| `matchmaking_error` | `{ message }` | Matchmaking error |
| `game_matched` | `{ gameId, player1, player2, ... }` | Match found |
| `game_start_countdown` | `{ countdown, message }` | Game starting countdown |
| `player_moved` | `{ playerId, playerType }` | Opponent made move |
| `move_result` | `{ player1Move, player2Move, isOut, runs, ... }` | Result of both moves |
| `innings_end` | `{ innings, reason, message }` | Innings completed |
| `innings_start` | `{ innings, target, message }` | New innings starting |
| `continue_innings` | `{ message }` | Next ball |
| `game_over` | `{ winner, isTie, message, ... }` | Game completed |
| `game_paused` | `{ pausedBy, message }` | Game paused |
| `game_resumed` | `{ resumedBy, message }` | Game resumed |
| `player_disconnected` | `{ disconnectedPlayer, winner }` | Opponent disconnected |
| `move_error` | `{ message }` | Move validation error |
| `game_error` | `{ message }` | General game error |

### REST API Endpoints

```
GET  /                          - Health check
GET  /api/v1/user/:uid          - Get user by Firebase UID
POST /api/v1/user/login         - Create/login user
```

## File Structure

```
backend/
├── src/
│   ├── app.js                       # Main server setup
│   ├── routes.js                    # REST API routes
│   ├── config/
│   │   └── redis.config.js          # Redis client configuration
│   ├── handlers/                    # Socket.IO event handlers
│   │   ├── gameEventsHandler.js     # Main game event router
│   │   ├── findGameHandler.js       # Matchmaking logic
│   │   ├── playerMoveHandler.js     # Move processing
│   │   ├── disconnectHandler.js     # Disconnect handling
│   │   ├── cancelMatchmakingHandler.js
│   │   └── pauseResumeHandler.js
│   ├── services/
│   │   ├── gameService.js           # Game state logic
│   │   └── userService.js           # User database operations
│   ├── middlewares/
│   │   └── socketAuth.js            # Socket authentication
│   └── utils/
│       └── redisClient.js           # Redis helper functions
├── prisma/
│   └── schema.prisma                # Database schema
├── package.json
└── .env
```

## Game Flow

### 1. Matchmaking
```
Client              Server              Redis
  │                   │                   │
  ├─find_game────────>│                   │
  │                   ├─addToQueue───────>│
  │                   ├─check queue len───>│
  │                   │<──2 players ready──┤
  │                   ├─create game state──>│
  │<─game_matched─────┤                   │
  │<─countdown─────────┤                   │
```

### 2. Gameplay Loop
```
Client              Server              Redis
  │                   │                   │
  ├─player_move──────>│                   │
  │                   ├─store move───────>│
  │                   ├─check both moved──>│
  │                   ├─process moves─────>│
  │<─move_result──────┤                   │
  │<─continue_innings──┤                   │
  │                   │                   │
  ├─player_move──────>│  (repeat)         │
```

### 3. Game End
```
Client              Server              MongoDB
  │                   │                   │
  │<─innings_end──────┤                   │
  │<─innings_start─────┤  (if innings 1)  │
  │                   │                   │
  │<─game_over─────────┤                   │
  │                   ├─save result───────>│
  │                   ├─update stats──────>│
```

## Redis Data Structure

### Keys

- `matchmaking_queue`: List - UIDs of players waiting
- `user_status:{uid}`: String - `online` | `queued` | `in_game:{gameId}`
- `user_socket:{uid}`: String - Socket ID
- `game:{gameId}`: Hash - Complete game state

### Game State (Hash)

```javascript
{
  id: "uuid",
  phase: "toss" | "startInnigs" | "innings1" | "innings2" | "result",
  status: "active" | "waiting" | "paused" | "finished",
  player1: JSON<GamePlayer>,
  player2: JSON<GamePlayer>,
  whoBattingFirst: "player1" | "player2",
  player1choice: 0-6,
  player2choice: 0-6,
  currentMove: number,
  innings: 1 | 2,
  ballsBowled: number,
  maxBalls: 6,
  target: number | null,
  winner: "player1" | "player2" | null,
  isTie: boolean,
  message: string,
  createdAt: timestamp
}
```

## Database Schema (MongoDB)

### User
```prisma
model User {
  id             String  @id @default(auto()) @map("_id") @db.ObjectId
  uid            String  @unique  // Firebase UID
  name           String
  email          String?
  profilePicture String?
  Stats          Stats?
}
```

### Stats
```prisma
model Stats {
  id      String @id @default(auto()) @map("_id") @db.ObjectId
  wins    Int    @default(0)
  matches Int    @default(0)
  losses  Int    @default(0)
  runs    Int    @default(0)
  userId  String @unique @db.ObjectId
  user    User   @relation(fields: [userId], references: [id])
}
```

## Testing

### Test Socket.IO Connection

Use the included `test-client.html`:

```bash
# Start server
npm run dev

# Open test-client.html in browser
# Or visit: http://localhost:5000/test-client.html
```

### Manual Testing with Redis CLI

```bash
# Check matchmaking queue
redis-cli LLEN matchmaking_queue

# View game state
redis-cli HGETALL game:{gameId}

# Check user status
redis-cli GET user_status:{uid}

# Clear all keys (for testing)
redis-cli FLUSHALL
```

### Test REST API

```bash
# Health check
curl http://localhost:5000

# Get user
curl http://localhost:5000/api/v1/user/{firebaseUid}
```

## Troubleshooting

### Redis Connection Failed
```
Error: connect ECONNREFUSED 127.0.0.1:6379
```
**Solution**: Start Redis server or update `REDIS_URL` in `.env`

### Prisma Client Not Generated
```
Error: Cannot find module '@prisma/client'
```
**Solution**: Run `npx prisma generate`

### MongoDB Connection Failed
```
Error: Invalid connection string
```
**Solution**: Check `DATABASE_URL` in `.env`, ensure MongoDB is running

### Socket Authentication Failed
```
Authentication required
```
**Solution**: Ensure Flutter client passes `uid`, `name`, and `email` in socket auth

## Production Deployment

### Environment Variables
```env
NODE_ENV=production
PORT=5000
REDIS_URL=redis://production-redis-host:6379
DATABASE_URL=mongodb+srv://...
CORS_ORIGIN=https://your-flutter-app.com
```

### Recommended Setup
- Use Redis Cloud or AWS ElastiCache for Redis
- MongoDB Atlas for database
- Deploy on Heroku, Railway, or AWS EC2
- Use PM2 for process management:

```bash
npm install -g pm2
pm2 start src/app.js --name handysix-backend
pm2 save
pm2 startup
```

### Docker Deployment

```dockerfile
# Dockerfile already included in backend/
docker build -t handysix-backend .
docker run -p 5000:5000 --env-file .env handysix-backend
```

## Performance Considerations

- Redis keys auto-expire after 1 hour
- Game state updates are atomic
- Socket rooms for efficient broadcasting
- Graceful shutdown handling (SIGTERM/SIGINT)

## License

This backend is part of the HandySix project.
