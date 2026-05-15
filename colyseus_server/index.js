const http = require("http");
const express = require("express");
const { Server, Room, ServerError } = require("@colyseus/core");
const { WebSocketTransport } = require("@colyseus/ws-transport");
const { Schema, MapSchema, defineTypes } = require("@colyseus/schema");

const PORT = Number(process.env.PORT || 2567);

// ─── State Schemas ─────────────────────────────────────────────────────
class PlayerState extends Schema {
  constructor() {
    super();
    this.x = 0;
    this.y = 0;
    this.vx = 0;
    this.vy = 0;
    this.tick = 0;
  }
}
defineTypes(PlayerState, {
  x: "number",
  y: "number",
  vx: "number",
  vy: "number",
  tick: "number",
});

class WerewolfRoomState extends Schema {
  constructor() {
    super();
    this.players = new MapSchema();
    this.roomCode = "";
    this.mode = "day";
    this.hostSessionId = "";
  }
}
defineTypes(WerewolfRoomState, {
  players: { map: PlayerState },
  roomCode: "string",
  mode: "string",
  hostSessionId: "string",
});

// ─── Room ──────────────────────────────────────────────────────────────
class WerewolfRoom extends Room {
  onCreate(options) {
    // Reached onCreate via a guest's join → no room with that code existed.
    if (options.host !== true) {
      throw new ServerError(404, `Room not found: ${options.roomCode || ""}`);
    }
    if (!options.roomCode || typeof options.roomCode !== "string") {
      throw new ServerError(400, "Missing roomCode");
    }

    const state = new WerewolfRoomState();
    state.roomCode = String(options.roomCode).toUpperCase();
    state.mode = ["night", "day", "forest"].includes(options.mode) ? options.mode : "day";
    this.setState(state);

    this.maxClients = 16;
    this.autoDispose = true;
    this.setMetadata({ roomCode: state.roomCode, mode: state.mode });

    this.onMessage("move", (client, data) => {
      const player = this.state.players.get(client.sessionId);
      if (!player || !data) return;
      if (typeof data.x === "number") player.x = data.x;
      if (typeof data.y === "number") player.y = data.y;
      if (typeof data.vx === "number") player.vx = data.vx;
      if (typeof data.vy === "number") player.vy = data.vy;
      if (typeof data.tick === "number") player.tick = data.tick;
    });

    console.log(`[${state.roomCode}] Room created (mode=${state.mode})`);
  }

  onJoin(client, options) {
    // Collision: a second host tried to create with the same code and got
    // matched into this existing room. Reject so they can retry.
    if (options && options.host === true && this.state.hostSessionId !== "") {
      throw new ServerError(409, "Room code in use, retry");
    }

    if (options && options.host === true) {
      this.state.hostSessionId = client.sessionId;
    }

    this.state.players.set(client.sessionId, new PlayerState());
    console.log(
      `[${this.state.roomCode}] ${client.sessionId} joined (${this.state.players.size} players)`
    );
  }

  onLeave(client) {
    this.state.players.delete(client.sessionId);
    console.log(
      `[${this.state.roomCode}] ${client.sessionId} left (${this.state.players.size} players)`
    );
  }

  onDispose() {
    console.log(`[${this.state.roomCode}] Room disposed`);
  }
}

// ─── Server Bootstrap ──────────────────────────────────────────────────
const app = express();
app.get("/", (_req, res) => res.send("Werewolf Colyseus server running"));

const httpServer = http.createServer(app);

const gameServer = new Server({
  transport: new WebSocketTransport({ server: httpServer }),
});

gameServer.define("werewolf", WerewolfRoom).filterBy(["roomCode"]);

httpServer.listen(PORT, () => {
  console.log(`\n🎮 Werewolf Colyseus server on ws://localhost:${PORT}\n`);
});
