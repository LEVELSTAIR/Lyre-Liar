/* global React */
const { useState, useEffect } = React;

// ── GameFrame ──────────────────────────────────────────────────────────────
// Mirrors Godot's 360×640 portrait base with ResponsiveUI's clamp(min(vp/360, vp/640), 0.7, 2.5).
// Letterboxes on the shell-void color.
window.GameFrame = function GameFrame({ children }) {
  const [scale, setScale] = useState(1);
  useEffect(() => {
    const recompute = () => {
      const vw = window.innerWidth;
      const vh = window.innerHeight;
      const s = Math.min(Math.min(vw / 360, vh / 640) * 0.95, 2.5);
      setScale(Math.max(0.7, s));
    };
    recompute();
    window.addEventListener('resize', recompute);
    return () => window.removeEventListener('resize', recompute);
  }, []);
  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'var(--shell-void)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      overflow: 'hidden',
    }}>
      <div style={{
        width: 360, height: 640, transform: `scale(${scale})`, transformOrigin: 'center',
        position: 'relative', overflow: 'hidden', background: 'var(--shell-void)',
        boxShadow: '0 0 0 1px rgba(199,141,46,0.18), 0 30px 80px rgba(0,0,0,0.6)',
      }}>
        {children}
      </div>
    </div>
  );
};

// ── TitleBlock ─────────────────────────────────────────────────────────────
// Matches TitleContainer in main_menu.tscn: brass rule, big wordmark with shadow,
// tagline in brass-glow, brass rule.
window.TitleBlock = function TitleBlock() {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, top: '8%',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0,
    }}>
      <div style={{ height: 6, width: 320, background: 'var(--brass-rule)' }} />
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 36,
        color: 'var(--parchment)', textShadow: '0 3px 0 rgba(82,46,15,0.8)',
        letterSpacing: '0.04em', textTransform: 'uppercase', lineHeight: 1,
        padding: '10px 0 4px',
      }}>Lyre &amp; Liar</div>
      <div style={{
        fontFamily: 'var(--font-body)', fontStyle: 'italic', fontSize: 13,
        color: 'var(--brass-glow)', letterSpacing: '0.02em', marginBottom: 8,
      }}>Whisper me a betrayal</div>
      <div style={{ height: 6, width: 320, background: 'var(--brass-rule)' }} />
    </div>
  );
};

// ── MenuButton ─────────────────────────────────────────────────────────────
// Godot default-stylebox approximation: gray gradient, square corners, no
// border, label color per role, brighten on hover, darken + 1 px push on press.
window.MenuButton = function MenuButton({ role = 'multi', children, onClick, disabled, full = true, height = 56 }) {
  const colorMap = {
    single: 'var(--label-single)', multi: 'var(--label-multi)',
    day: 'var(--map-day)', night: 'var(--map-night)', forest: 'var(--map-forest)',
  };
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className="ll-menu-btn"
      style={{
        width: full ? 280 : 'auto', height, padding: '0 14px',
        border: 0, borderRadius: 0,
        fontFamily: 'var(--font-ui)', fontSize: 22, letterSpacing: '0.06em',
        textTransform: 'uppercase',
        color: colorMap[role] || colorMap.multi,
        background: 'linear-gradient(180deg, #4F4F4F 0%, #353535 100%)',
        textShadow: '0 1px 0 rgba(0,0,0,0.6)',
        cursor: disabled ? 'default' : 'pointer',
        filter: disabled ? 'brightness(0.6) grayscale(0.4)' : 'none',
        transition: 'filter 90ms linear, transform 90ms ease-out',
      }}
    >{children}</button>
  );
};

// ── StatusLine ─────────────────────────────────────────────────────────────
window.StatusLine = function StatusLine({ text, color }) {
  return (
    <div style={{
      fontFamily: 'var(--font-body)', fontSize: 12, color: color || 'var(--state-status)',
      textAlign: 'center', lineHeight: 1.5, whiteSpace: 'pre-wrap', minHeight: 38,
    }}>{text}</div>
  );
};

// ── ModeLabel ──────────────────────────────────────────────────────────────
window.ModeLabel = function ModeLabel({ children }) {
  return (
    <div style={{
      fontFamily: 'var(--font-ui)', fontSize: 14, color: 'var(--state-mode)',
      textTransform: 'uppercase', letterSpacing: '0.16em', textAlign: 'center',
    }}>{children}</div>
  );
};

// ── VersionBadge ───────────────────────────────────────────────────────────
window.VersionBadge = function VersionBadge() {
  return (
    <div style={{
      position: 'absolute', right: 12, bottom: 8,
      fontFamily: 'var(--font-body)', fontSize: 12, color: 'var(--state-version)',
      letterSpacing: '0.04em',
    }}>v0.1.0 - Alpha</div>
  );
};

// ── BrassRule (utility) ────────────────────────────────────────────────────
window.BrassRule = function BrassRule({ width = 320 }) {
  return <div style={{ height: 6, width, background: 'var(--brass-rule)' }} />;
};
