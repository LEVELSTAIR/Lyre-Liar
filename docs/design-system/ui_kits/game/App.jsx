/* global React, ReactDOM, GameFrame, MainMenu, GameView, PauseButton, TimerHud, MobileControls, OverlayPaused, OverlayDied, OverlayTimeout, OverlayComplete */
const { useState, useEffect } = React;

function App() {
  // Top-level screen: 'menu' | 'game'
  const [screen, setScreen] = useState('menu');
  const [map, setMap] = useState('night');
  const [singlePlayer, setSinglePlayer] = useState(true);
  // In-game overlay: null | 'paused' | 'died' | 'timeout' | 'complete'
  const [overlay, setOverlay] = useState(null);
  const [seconds, setSeconds] = useState(60);

  // Tick the countdown when in-game, single-player, no overlay.
  useEffect(() => {
    if (screen !== 'game' || !singlePlayer || overlay) return;
    const id = setInterval(() => setSeconds(s => {
      if (s <= 1) {
        setOverlay('timeout');
        return 0;
      }
      return s - 1;
    }), 1000);
    return () => clearInterval(id);
  }, [screen, singlePlayer, overlay]);

  function startSingle(mapId) {
    setMap(mapId);
    setSinglePlayer(true);
    setSeconds(60);
    setOverlay(null);
    setScreen('game');
  }
  function startMulti(mapId /*, code, hosted */) {
    setMap(mapId);
    setSinglePlayer(false);
    setOverlay(null);
    setScreen('game');
  }
  function backToMenu() {
    setScreen('menu');
    setOverlay(null);
  }

  return (
    <GameFrame>
      {screen === 'menu' && (
        <MainMenu onStartSingle={startSingle} onStartMulti={startMulti} />
      )}

      {screen === 'game' && (<>
        <GameView map={map} />
        <PauseButton onClick={() => setOverlay('paused')} />
        {singlePlayer && <TimerHud seconds={seconds} />}
        <MobileControls />

        {overlay === 'paused' && (
          <OverlayPaused
            onResume={() => setOverlay(null)}
            onMenu={backToMenu}
            onQuit={backToMenu}
          />
        )}
        {overlay === 'died' && (
          <OverlayDied onRestart={() => { setSeconds(60); setOverlay(null); }} onQuit={backToMenu} />
        )}
        {overlay === 'timeout' && (
          <OverlayTimeout onRestart={() => { setSeconds(60); setOverlay(null); }} onQuit={backToMenu} />
        )}
        {overlay === 'complete' && (
          <OverlayComplete
            stats={`Time: 00:${(60 - seconds).toString().padStart(2,'0')}\nDeaths: 0`}
            onReplay={() => { setSeconds(60); setOverlay(null); }}
            onNext={() => { setSeconds(60); setOverlay(null); }}
            onMenu={backToMenu}
          />
        )}
      </>)}

      {/* Debug strip — lets reviewer jump to any overlay or kill themselves */}
      {screen === 'game' && !overlay && (
        <div style={{
          position: 'absolute', right: 8, top: 60, display: 'flex',
          flexDirection: 'column', gap: 6, zIndex: 9,
        }}>
          {['died','timeout','complete'].map(o => (
            <button key={o} onClick={() => setOverlay(o)} style={debugBtn}>{o}</button>
          ))}
        </div>
      )}
    </GameFrame>
  );
}

const debugBtn = {
  background: 'rgba(0,0,0,0.5)', color: 'var(--state-version)',
  fontFamily: 'var(--font-mono)', fontSize: 10, padding: '3px 8px',
  border: '1px solid var(--state-version)', cursor: 'pointer',
  textTransform: 'uppercase', letterSpacing: '0.1em', borderRadius: 0,
};

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
