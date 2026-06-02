/* global React, MenuButton */

// ── Generic overlay frame ────────────────────────────────────────────────
// Matches pause/death/timeout/complete scenes: full-bleed wash, centered
// VBoxContainer with title + buttons, sep 16-18.
window.Overlay = function Overlay({ wash, children }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: wash,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 10,
    }}>
      <div style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        gap: 16, minWidth: 240, padding: '8px 0',
      }}>{children}</div>
    </div>
  );
};

window.OverlayTitle = function OverlayTitle({ color, children, size = 32 }) {
  return (
    <div style={{
      fontFamily: 'var(--font-ui)', fontSize: size, color,
      textShadow: '0 2px 0 rgba(0,0,0,0.8)', letterSpacing: '0.06em',
      textTransform: 'uppercase', marginBottom: 6,
    }}>{children}</div>
  );
};

// ── Concrete overlays ────────────────────────────────────────────────────
window.OverlayPaused = function OverlayPaused({ onResume, onMenu, onQuit }) {
  return (
    <Overlay wash="rgba(0,0,0,0.6)">
      <OverlayTitle color="var(--state-paused)" size={32}>Paused</OverlayTitle>
      <MenuButton role="multi" height={50} onClick={onResume}>Resume</MenuButton>
      <MenuButton role="multi" height={50} onClick={onMenu}>Main menu</MenuButton>
      <MenuButton role="multi" height={50} onClick={onQuit}>Quit</MenuButton>
    </Overlay>
  );
};

window.OverlayDied = function OverlayDied({ onRestart, onQuit }) {
  return (
    <Overlay wash="rgba(64,0,0,0.7)">
      <OverlayTitle color="var(--state-died)" size={40}>You died</OverlayTitle>
      <MenuButton role="multi" height={50} onClick={onRestart}>Restart</MenuButton>
      <MenuButton role="multi" height={50} onClick={onQuit}>Quit</MenuButton>
    </Overlay>
  );
};

window.OverlayTimeout = function OverlayTimeout({ onRestart, onQuit }) {
  return (
    <Overlay wash="rgba(0,0,0,0.7)">
      <OverlayTitle color="var(--state-timeout)" size={40}>Too late</OverlayTitle>
      <MenuButton role="multi" height={50} onClick={onRestart}>Restart</MenuButton>
      <MenuButton role="multi" height={50} onClick={onQuit}>Quit</MenuButton>
    </Overlay>
  );
};

window.OverlayComplete = function OverlayComplete({ stats, onReplay, onNext, onMenu }) {
  return (
    <Overlay wash="rgba(0,38,13,0.7)">
      <OverlayTitle color="var(--state-complete)" size={36}>Level complete</OverlayTitle>
      <div style={{
        fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--parchment-dim)',
        textAlign: 'center', lineHeight: 1.7, whiteSpace: 'pre-line',
      }}>{stats || "Time: 00:42\nDeaths: 2"}</div>
      <MenuButton role="multi" height={50} onClick={onReplay}>Replay</MenuButton>
      <MenuButton role="multi" height={50} onClick={onNext}>Next level</MenuButton>
      <MenuButton role="multi" height={50} onClick={onMenu}>Main menu</MenuButton>
    </Overlay>
  );
};
