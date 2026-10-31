import { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { isBrowser, nui, useKeys, useNuiMessage } from '../shared/nui';
import '../shared/cine.css';

interface Loc { id: string; label: string; sub?: string }

const DEMO: Loc[] = [
  { id: 'last', label: 'Last location', sub: 'Where you left off' },
  { id: 'legion', label: 'Legion Square', sub: 'City centre' },
  { id: 'airport', label: 'Los Santos Airport', sub: 'Arrivals' },
  { id: 'pier', label: 'Del Perro Pier', sub: 'Beach front' },
  { id: 'sandy', label: 'Sandy Shores', sub: 'Blaine County' },
];

function App() {
  const [list, setList] = useState<Loc[] | null>(null);
  const [sel, setSel] = useState(0);
  const [busy, setBusy] = useState(false);

  useNuiMessage((m) => {
    if (m.action === 'open') { setList((m.data as { locations: Loc[] }).locations); setSel(0); setBusy(false); }
    else if (m.action === 'close') setList(null);
  });
  useEffect(() => { if (isBrowser) { document.body.classList.add('demo-bg'); setList(DEMO); } }, []);
  useEffect(() => { if (list && list[sel]) void nui('hover', { id: list[sel].id }); }, [sel, list]);

  const spawn = async () => {
    if (!list || busy) return;
    setBusy(true);
    const r = await nui<{ ok: boolean }>('spawn', { id: list[sel].id }, { ok: true });
    if (!r || !r.ok) setBusy(false);
  };
  useKeys((e) => {
    if (!list || busy) return;
    if (e.key === 'ArrowDown') setSel((s) => Math.min(list.length - 1, s + 1));
    else if (e.key === 'ArrowUp') setSel((s) => Math.max(0, s - 1));
    else if (e.key === 'Enter') void spawn();
  });

  if (!list) return null;
  return (
    <div className={`cine ${busy ? 'busy' : ''}`}>
      <div className="bar top"><small>Project07</small><small>Choose where to wake up</small></div>
      <div className="side">
        <div className="eyebrow">Spawn</div>
        <div className="list">
          {list.map((l, i) => (
            <button key={l.id} className={`item ${i === sel ? 'on' : ''}`} onClick={() => (i === sel ? spawn() : setSel(i))}>
              <span className="n">{String(i + 1).padStart(2, '0')}</span>
              <span><b>{l.label}</b>{l.sub && <><br /><small>{l.sub}</small></>}</span>
            </button>
          ))}
        </div>
        <div className="actions"><button className="act primary" onClick={spawn}>Spawn here</button></div>
      </div>
      <div className="bar bottom">
        <small>{list[sel]?.label}</small>
        <div className="keys"><span className="key"><kbd>↑ ↓</kbd>Choose</span><span className="key"><kbd>Enter</kbd>Spawn</span></div>
      </div>
    </div>
  );
}

createRoot(document.getElementById('root')!).render(<App />);
