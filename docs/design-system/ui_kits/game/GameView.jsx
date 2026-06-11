/* global React */
const { useState, useEffect } = React;

// ── Pause button (top-left "II") ──────────────────────────────────────────
window.PauseButton = function PauseButton({ onClick }) {
  return (
    <button onClick={onClick} style={{
      position: 'absolute', left: 12, top: 12, width: 44, height: 40,
      background: 'linear-gradient(180deg,#4F4F4F,#353535)',
      border: 0, borderRadius: 0, color: 'var(--parchment)',
      fontFamily: 'var(--font-ui)', fontSize: 22, letterSpacing: '0.1em',
      cursor: 'pointer', textShadow: '0 1px 0 rgba(0,0,0,0.6)',
      zIndex: 5,
    }}>II</button>
  );
};

// ── Countdown timer (top-right) ───────────────────────────────────────────
window.TimerHud = function TimerHud({ seconds }) {
  const mm = Math.floor(seconds / 60).toString().padStart(2, '0');
  const ss = Math.floor(seconds % 60).toString().padStart(2, '0');
  return (
    <div style={{
      position: 'absolute', right: 12, top: 12, height: 38,
      fontFamily: 'var(--font-mono)', fontSize: 28,
      color: 'var(--state-timer)', textShadow: '0 2px 0 rgba(0,0,0,0.8)',
      letterSpacing: '0.04em', textAlign: 'right', minWidth: 120,
      zIndex: 5,
    }}>{mm}:{ss}</div>
  );
};

// ── Mobile joystick + JUMP button ─────────────────────────────────────────
window.MobileControls = function MobileControls({ onLeft, onRight, onJump }) {
  const [held, setHeld] = useState(false);
  const [drag, setDrag] = useState({ x: 0, y: 0 });
  const max = 50; // BASE_JOYSTICK / 2

  function move(clientX, clientY, baseRect) {
    let dx = clientX - (baseRect.left + baseRect.width / 2);
    let dy = clientY - (baseRect.top + baseRect.height / 2);
    const d = Math.hypot(dx, dy);
    if (d > max) { dx = dx / d * max; dy = dy / d * max; }
    setDrag({ x: dx, y: dy });
    if (dx < -10) onLeft?.(true), onRight?.(false);
    else if (dx > 10) onRight?.(true), onLeft?.(false);
    else onLeft?.(false), onRight?.(false);
  }

  return (
    <>
      {/* JUMP button — bottom-left */}
      <button
        onPointerDown={() => { setHeld(true); onJump?.(); }}
        onPointerUp={() => setHeld(false)}
        onPointerLeave={() => setHeld(false)}
        style={{
          position: 'absolute', left: 20, bottom: 20, width: 100, height: 100,
          borderRadius: 50, background: 'linear-gradient(180deg,#5a5a5a,#3a3a3a)',
          color: 'var(--parchment)', fontFamily: 'var(--font-ui)', fontSize: 24,
          textTransform: 'uppercase', letterSpacing: '0.08em',
          border: '2px solid rgba(255,255,255,0.3)', boxSizing: 'border-box',
          textShadow: '0 1px 0 rgba(0,0,0,0.6)', cursor: 'pointer',
          filter: held ? 'brightness(0.7)' : 'none',
          touchAction: 'none', zIndex: 5,
        }}
      >Jump</button>

      {/* Joystick — bottom-right */}
      <div
        onPointerDown={e => move(e.clientX, e.clientY, e.currentTarget.getBoundingClientRect())}
        onPointerMove={e => { if (e.buttons === 1) move(e.clientX, e.clientY, e.currentTarget.getBoundingClientRect()); }}
        onPointerUp={() => { setDrag({ x: 0, y: 0 }); onLeft?.(false); onRight?.(false); }}
        onPointerLeave={() => { setDrag({ x: 0, y: 0 }); onLeft?.(false); onRight?.(false); }}
        style={{
          position: 'absolute', right: 20, bottom: 20, width: 100, height: 100,
          borderRadius: 50, background: 'rgba(255,255,255,0.18)',
          border: '2px solid rgba(255,255,255,0.4)', boxSizing: 'border-box',
          touchAction: 'none', zIndex: 5,
        }}
      >
        <div style={{
          position: 'absolute',
          left: 25 + drag.x, top: 25 + drag.y,
          width: 50, height: 50, borderRadius: 25,
          background: 'rgba(255,255,255,0.65)',
          boxShadow: '0 2px 4px rgba(0,0,0,0.4)',
          pointerEvents: 'none',
          transition: drag.x === 0 && drag.y === 0 ? 'left 120ms ease-out, top 120ms ease-out' : 'none',
        }} />
      </div>
    </>
  );
};

// ── In-game canvas (background + player sprite + monsters) ────────────────
window.GameView = function GameView({ map }) {
  const bgMap = {
    day:    { bg: '../../assets/backgrounds/grass-bg.png',  mid: '../../assets/backgrounds/grass-mid.png', floorColor: '#3a4a1f' },
    night:  { bg: '../../assets/backgrounds/cave-bg-1.png', mid: '../../assets/backgrounds/cave-bg-2.png', floorColor: '#0e1f1d' },
    forest: { bg: '../../assets/backgrounds/cave-bg-3.png', mid: '../../assets/backgrounds/cave-bg-4a.png', floorColor: '#1a1a26' },
  };
  const m = bgMap[map] || bgMap.night;

  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', background: m.floorColor }}>
      {/* far background */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: `url("${m.bg}")`,
        backgroundSize: 'cover', backgroundPosition: 'center',
        opacity: 0.95,
      }} />
      {/* mid layer */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 80,
        height: 200,
        backgroundImage: `url("${m.mid}")`,
        backgroundRepeat: 'repeat-x', backgroundPosition: 'bottom center',
        backgroundSize: 'auto 100%', opacity: 0.9,
      }} />
      {/* floor strip */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, height: 80,
        background: `linear-gradient(180deg, transparent, ${m.floorColor})`,
      }} />
      {/* player sprite (idle frame) — center bottom */}
      <img src="../../assets/sprites/pink-monster-idle.png" alt=""
        style={{
          position: 'absolute', left: '50%', bottom: 90,
          width: 64, height: 'auto', // crop first frame visually with object-position
          imageRendering: 'pixelated',
          transform: 'translateX(-50%) scale(2)', transformOrigin: 'bottom center',
          // show only first of 4 frames
          clipPath: 'inset(0 75% 0 0)',
        }} />
      {/* remote players */}
      <img src="../../assets/sprites/owlet-monster-idle.png" alt=""
        style={{
          position: 'absolute', left: 60, bottom: 90, width: 64,
          imageRendering: 'pixelated', transform: 'scale(1.8)', transformOrigin: 'bottom left',
          clipPath: 'inset(0 75% 0 0)', opacity: 0.95,
        }} />
      <img src="../../assets/sprites/dude-monster-idle.png" alt=""
        style={{
          position: 'absolute', right: 50, bottom: 90, width: 64,
          imageRendering: 'pixelated', transform: 'scale(1.8) scaleX(-1)', transformOrigin: 'bottom right',
          clipPath: 'inset(0 75% 0 0)', opacity: 0.95,
        }} />
      {/* enemy: slug crawling */}
      <img src="../../assets/sprites/slug.png" alt=""
        style={{
          position: 'absolute', left: 140, bottom: 84, width: 32,
          imageRendering: 'pixelated', transform: 'scale(1.5)', transformOrigin: 'bottom left',
          clipPath: 'inset(0 75% 0 0)',
        }} />
    </div>
  );
};
