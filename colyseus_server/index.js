const { WebSocketServer } = require("ws");

const PORT = Number(process.env.PORT || 2567);

// ─── Room Management ─────────────────────────────────────────────────────────
const rooms = new Map(); // roomCode -> Room

function generateRoomCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no ambiguous chars
  let code = "";
  for (let i = 0; i < 4; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return rooms.has(code) ? generateRoomCode() : code;
}

function generateSessionId() {
  return Math.random().toString(36).substring(2, 10);
}

class Room {
  constructor(code) {
    this.code = code;
    this.players = new Map(); // sessionId -> { ws, state }
  }

  addPlayer(sessionId, ws) {
    const state = { x: 0, y: 0, vx: 0, vy: 0, tick: 0 };
    this.players.set(sessionId, { ws, state });

    // Tell the new player about ALL existing players
    for (const [existingId, existing] of this.players) {
      if (existingId !== sessionId) {
        ws.send(JSON.stringify({
          type: "player_joined",
          sessionId: existingId,
          state: existing.state
        }));
      }
    }

    // Broadcast the new player to everyone else
    this.broadcast({ type: "player_joined", sessionId, state }, sessionId);
    console.log(`  [${this.code}] ${sessionId} joined (${this.players.size} players)`);
  }

  removePlayer(sessionId) {
    this.players.delete(sessionId);
    this.broadcast({ type: "player_left", sessionId });
    console.log(`  [${this.code}] ${sessionId} left (${this.players.size} players)`);
    return this.players.size;
  }

  updatePlayer(sessionId, data) {
    const player = this.players.get(sessionId);
    if (!player) return;
    Object.assign(player.state, data);
    // Relay movement to all OTHER players
    this.broadcast({ type: "player_moved", sessionId, state: player.state }, sessionId);
  }

  broadcast(msg, excludeId = null) {
    const data = JSON.stringify(msg);
    for (const [id, player] of this.players) {
      if (id !== excludeId && player.ws.readyState === 1) {
        player.ws.send(data);
      }
    }
  }
}

// ─── WebSocket Server ────────────────────────────────────────────────────────
const wss = new WebSocketServer({ port: PORT });

wss.on("listening", () => {
  console.log(`\n🎮 Werewolf Server listening on ws://localhost:${PORT}\n`);
});

wss.on("connection", (ws) => {
  let sessionId = null;
  let room = null;

  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return;
    }

    switch (msg.type) {
      // ── Host: create a new room ──────────────────────────────────────
      case "host": {
        const code = generateRoomCode();
        sessionId = generateSessionId();
        room = new Room(code);
        room.mode = msg.mode || "day"; // Store the game mode
        rooms.set(code, room);
        room.addPlayer(sessionId, ws);
        ws.send(JSON.stringify({
          type: "hosted",
          roomCode: code,
          sessionId,
          mode: room.mode
        }));
        console.log(`Room ${code} (${room.mode}) created by ${sessionId}`);
        break;
      }

      // ── Join: join an existing room ──────────────────────────────────
      case "join": {
        const code = (msg.roomCode || "").toUpperCase();
        const target = rooms.get(code);
        if (!target) {
          ws.send(JSON.stringify({ type: "error", message: "Room not found: " + code }));
          return;
        }
        sessionId = generateSessionId();
        room = target;
        room.addPlayer(sessionId, ws);
        ws.send(JSON.stringify({
          type: "joined",
          roomCode: code,
          sessionId,
          mode: room.mode // Send the mode to the joiner
        }));
        console.log(`${sessionId} joined room ${code}`);
        break;
      }

      // ── Move: relay player position ──────────────────────────────────
      case "move": {
        if (room && sessionId) {
          room.updatePlayer(sessionId, msg.data);
        }
        break;
      }
    }
  });

  ws.on("close", () => {
    if (room && sessionId) {
      const remaining = room.removePlayer(sessionId);
      if (remaining === 0) {
        rooms.delete(room.code);
        console.log(`Room ${room.code} destroyed (empty)`);
      }
    }
  });
});
