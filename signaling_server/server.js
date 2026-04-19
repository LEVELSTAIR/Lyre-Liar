const WebSocket = require('ws');

const PORT = process.env.PORT || 8090;
const wss = new WebSocket.Server({ port: PORT });
const rooms = {};
const peers = new Map();

function generateRoomCode() {
	const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
	let code = '';
	for (let i = 0; i < 6; i++) {
		code += chars.charAt(Math.floor(Math.random() * chars.length));
	}
	return code;
}

function sendToClient(ws, msg) {
	if (ws.readyState === WebSocket.OPEN) {
		ws.send(JSON.stringify(msg));
	}
}

function sendToRoom(roomCode, msg, excludeWs = null) {
	if (!rooms[roomCode]) return;

	const room = rooms[roomCode];
	if (room.host && room.host !== excludeWs) {
		sendToClient(room.host, msg);
	}

	for (const client of room.clients) {
		if (client.ws !== excludeWs) {
			sendToClient(client.ws, msg);
		}
	}
}

wss.on('connection', (ws) => {
	let peerInfo = { room: null, peer_id: null, role: null };
	peers.set(ws, peerInfo);

	console.log('Client connected');

	ws.on('message', (data) => {
		try {
			const msg = JSON.parse(data);

			switch (msg.type) {
				case 'host':
					handleHost(ws, msg, peerInfo);
					break;
				case 'join':
					handleJoin(ws, msg, peerInfo);
					break;
				case 'offer':
				case 'answer':
				case 'ice':
					handleSignaling(ws, msg, peerInfo);
					break;
				default:
					console.log('Unknown message type:', msg.type);
			}
		} catch (e) {
			console.error('Error processing message:', e);
		}
	});

	ws.on('close', () => {
		if (peerInfo.room) {
			handleDisconnect(peerInfo);
		}
		peers.delete(ws);
		console.log('Client disconnected');
	});

	ws.on('error', (err) => {
		console.error('WebSocket error:', err);
	});
});

function handleHost(ws, msg, peerInfo) {
	const roomCode = msg.room || generateRoomCode();

	if (rooms[roomCode] && rooms[roomCode].host) {
		sendToClient(ws, { type: 'error', message: 'Room already exists' });
		return;
	}

	if (!rooms[roomCode]) {
		rooms[roomCode] = { host: null, clients: [] };
	}

	rooms[roomCode].host = ws;
	peerInfo.room = roomCode;
	peerInfo.peer_id = 1;
	peerInfo.role = 'host';

	sendToClient(ws, { type: 'room_created', room: roomCode });
	console.log(`Host created room: ${roomCode}`);
}

function handleJoin(ws, msg, peerInfo) {
	const roomCode = msg.room;

	if (!rooms[roomCode]) {
		sendToClient(ws, { type: 'error', message: 'Room not found' });
		return;
	}

	const room = rooms[roomCode];
	if (!room.host) {
		sendToClient(ws, { type: 'error', message: 'Host disconnected' });
		return;
	}

	const clientId = 2 + room.clients.length;
	const clientInfo = { ws, id: clientId };
	room.clients.push(clientInfo);

	peerInfo.room = roomCode;
	peerInfo.peer_id = clientId;
	peerInfo.role = 'client';

	sendToClient(ws, { type: 'peer_id', id: clientId });
	sendToClient(room.host, { type: 'new_peer', id: clientId });

	console.log(`Client ${clientId} joined room: ${roomCode}`);
}

function handleSignaling(ws, msg, peerInfo) {
	if (!peerInfo.room) return;

	const room = rooms[peerInfo.room];
	if (!room) return;

	const toId = msg.to;
	let targetWs = null;

	if (toId === 1) {
		targetWs = room.host;
	} else {
		const client = room.clients.find(c => c.id === toId);
		if (client) targetWs = client.ws;
	}

	if (targetWs) {
		const forwardMsg = { ...msg, from: peerInfo.peer_id };
		delete forwardMsg.to;
		sendToClient(targetWs, forwardMsg);
	}
}

function handleDisconnect(peerInfo) {
	const room = rooms[peerInfo.room];
	if (!room) return;

	if (peerInfo.role === 'host') {
		const disconnectMsg = { type: 'error', message: 'Host disconnected' };
		for (const client of room.clients) {
			sendToClient(client.ws, disconnectMsg);
		}
		delete rooms[peerInfo.room];
		console.log(`Room ${peerInfo.room} closed (host disconnected)`);
	} else {
		room.clients = room.clients.filter(c => c.id !== peerInfo.peer_id);
		const clientMsg = { type: 'peer_disconnected', id: peerInfo.peer_id };
		sendToClient(room.host, clientMsg);
		console.log(`Client ${peerInfo.peer_id} left room ${peerInfo.room}`);
	}
}

console.log(`WebRTC Signaling Server listening on port ${PORT}`);
