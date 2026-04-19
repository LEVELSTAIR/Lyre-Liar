# WebRTC Signaling Server — Project Werewolf

A lightweight WebSocket-based signaling server for coordinating WebRTC peer connections in Project Werewolf's multiplayer game.

## Local Development

### Prerequisites
- Node.js 16+ and npm

### Setup
```bash
cd signaling_server
npm install
npm start
```

Server runs on `ws://localhost:9080`.

Update `scripts/multiplayer_manager.gd`:
```gdscript
var signaling_server_url := "ws://localhost:9080"
```

## Deployment (Free Tier)

### Option 1: Railway.app (Recommended)
1. Install Railway CLI: `npm install -g @railway/cli`
2. From `signaling_server/` directory:
   ```bash
   railway login
   railway init
   railway link  # (if not linking to existing project)
   railway up
   ```
3. Get the deployed URL:
   ```bash
   railway open
   ```
   Copy the deployment URL (ends in `.railway.app`), replace `https` with `wss`
4. Update `multiplayer_manager.gd`:
   ```gdscript
   var signaling_server_url := "wss://your-project.railway.app"
   ```

### Option 2: Render.com
1. Push code to GitHub
2. Go to https://render.com and create account
3. Create New → Web Service
4. Connect GitHub repo, select `signaling_server` as root directory
5. Build command: `npm install`
6. Start command: `npm start`
7. Get the deployed URL (ends in `.onrender.com`), use `wss://` prefix

### Option 3: Fly.io
1. Install Fly CLI
2. From `signaling_server/`:
   ```bash
   fly auth login
   fly launch
   fly deploy
   ```
3. Get URL via `fly open` (copy the domain, use `wss://` prefix)

## How It Works

**Room Flow:**
1. **Host connects:** Sends `{"type":"host","room":"ABC123"}` → gets `room_created` response
2. **Client joins:** Sends `{"type":"join","room":"ABC123"}` → gets assigned `peer_id=2`
3. **WebRTC negotiation:** Host/client exchange SDP offers/answers and ICE candidates via the signaling server

**Message Routing:**
- `offer/answer/ice` messages are routed by the `to` field (the target peer ID)
- The server forwards with `from` field indicating the sender

## Protocol Reference

```json
// Host → Server
{"type":"host","room":"ABC123"}

// Client → Server
{"type":"join","room":"ABC123"}

// Offer/Answer/ICE (both directions)
{"type":"offer","to":2,"sdp":"..."}
{"type":"answer","to":1,"sdp":"..."}
{"type":"ice","to":1,"candidate":{"media":"...","index":0,"name":"..."}}

// Server → Client
{"type":"room_created","room":"ABC123"}
{"type":"peer_id","id":2}
{"type":"new_peer","id":2}
{"type":"offer","from":2,"sdp":"..."}
{"type":"answer","from":1,"sdp":"..."}
{"type":"ice","from":1,"candidate":{...}}
{"type":"error","message":"Room not found"}
```
