/* global React, TitleBlock, MenuButton, ModeLabel, StatusLine, VersionBadge */
const { useState } = React;

// Mirrors the three "screens" of main_menu.gd::_update_ui_state:
//   - initial:   single player / multiplayer
//   - mapSelect: day / night / forest
//   - multi:     server address + room code + host / join
window.MainMenu = function MainMenu({ onStartSingle, onStartMulti }) {
  const [gameType, setGameType] = useState('');   // '' | 'single' | 'multi'
  const [mode, setMode] = useState('');           // '' | 'day' | 'night' | 'forest'
  const [ip, setIp] = useState('192.168.1.10');
  const [roomCode, setRoomCode] = useState('');
  const [status, setStatus] = useState('');
  const [hosting, setHosting] = useState(false);
  const [busy, setBusy] = useState(false);

  function pickMap(m) {
    setMode(m);
    if (gameType === 'single') {
      onStartSingle?.(m);
    }
  }
  function host() {
    if (!mode) return;
    setBusy(true);
    setHosting(true);
    setStatus('Hosting game...');
    // simulate room ready
    setTimeout(() => {
      const code = randomCode();
      setRoomCode(code);
      setStatus(`Room: ${code}\nYour IP: ${ip}\nWaiting for players...`);
      // auto-advance after a short beat
      setTimeout(() => onStartMulti?.(mode, code, true), 1500);
    }, 700);
  }
  function join() {
    if (!roomCode || roomCode.length !== 4) {
      setStatus('Room code must be 4 characters');
      return;
    }
    setBusy(true);
    setStatus('Loading game...');
    setTimeout(() => onStartMulti?.(mode, roomCode.toUpperCase(), false), 800);
  }

  return (
    <div style={{ position: 'absolute', inset: 0 }}>
      {/* Parallax background (cave bg1) modulated green, like the actual scene */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: 'url("../../assets/backgrounds/cave-bg-1.png")',
        backgroundSize: 'cover', backgroundPosition: 'center',
        filter: 'hue-rotate(40deg) saturate(0.7) brightness(0.5)',
        opacity: 0.32,
      }} />
      {/* Title block (always visible) */}
      <TitleBlock />

      {/* Vertical button stack */}
      <div style={{
        position: 'absolute', left: 0, right: 0, top: '45%',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
        padding: '0 24px',
      }}>
        {gameType === '' && (<>
          <MenuButton role="single" onClick={() => { setGameType('single'); setMode(''); }}>Single player</MenuButton>
          <MenuButton role="multi" onClick={() => { setGameType('multi'); setMode(''); }}>Multiplayer</MenuButton>
          <MenuButton role="multi" onClick={() => alert('quit')}>Quit</MenuButton>
        </>)}

        {gameType !== '' && !mode && (<>
          <ModeLabel>Select map</ModeLabel>
          <MenuButton role="day"    onClick={() => pickMap('day')}>Day</MenuButton>
          <MenuButton role="night"  onClick={() => pickMap('night')}>Night</MenuButton>
          <MenuButton role="forest" onClick={() => pickMap('forest')}>Forest (lvl 4)</MenuButton>
          <div style={{ height: 6 }} />
          <MenuButton role="multi" onClick={() => { setGameType(''); setMode(''); }}>Back</MenuButton>
        </>)}

        {gameType === 'multi' && mode && (<>
          <ModeLabel>Multiplayer ({mode})</ModeLabel>
          <div style={{ width: 280, display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div style={{ fontFamily: 'var(--font-ui)', fontSize: 13, color: 'var(--state-mode)', textTransform: 'uppercase', letterSpacing: '0.16em', textAlign: 'center' }}>Server address</div>
            <input
              value={ip} onChange={e => setIp(e.target.value)}
              placeholder="e.g. 192.168.1.10" disabled={busy}
              style={inputStyle}
            />
            <input
              value={roomCode} onChange={e => setRoomCode(e.target.value.toUpperCase().slice(0, 4))}
              placeholder="Room code" maxLength={4} disabled={busy}
              style={{ ...inputStyle, fontFamily: 'var(--font-mono)', letterSpacing: '0.2em', fontSize: 18 }}
            />
            <StatusLine text={status} />
          </div>
          <MenuButton role="multi" onClick={host} disabled={busy}>Host game</MenuButton>
          <MenuButton role="multi" onClick={join} disabled={busy || hosting}>Join game</MenuButton>
        </>)}
      </div>

      <VersionBadge />
    </div>
  );
};

const inputStyle = {
  width: '100%', height: 36, border: '1px solid #777',
  background: '#FFFFFF', color: '#111', fontFamily: 'var(--font-body)',
  fontSize: 14, textAlign: 'center', outline: 'none', borderRadius: 0,
  boxSizing: 'border-box',
};

function randomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let s = '';
  for (let i = 0; i < 4; i++) s += chars[Math.floor(Math.random() * chars.length)];
  return s;
}
