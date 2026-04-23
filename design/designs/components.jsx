// Shared ProteinChef UI primitives

const { useState, useEffect, useRef, useMemo } = React;

// ───────── Icons (minimal, line-based) ─────────
const Icon = ({ name, size = 20, stroke = 1.75, color = 'currentColor' }) => {
  const common = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth: stroke,
    strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  const paths = {
    plus: <><path d="M12 5v14M5 12h14"/></>,
    chevronRight: <><path d="M9 6l6 6-6 6"/></>,
    chevronDown: <><path d="M6 9l6 6 6-6"/></>,
    chevronLeft: <><path d="M15 6l-6 6 6 6"/></>,
    close: <><path d="M6 6l12 12M18 6L6 18"/></>,
    search: <><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></>,
    home: <><path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-7h-6v7H4a1 1 0 01-1-1V11z"/></>,
    bolt: <><path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z"/></>,
    fork: <><path d="M7 3v7a2 2 0 002 2v9M11 3v7M7 7h4"/><path d="M17 3c-1 3-1 7 0 10h0v9"/></>,
    dumb: <><path d="M3 9v6M6 6v12M18 6v12M21 9v6M6 12h12"/></>,
    users: <><circle cx="9" cy="8" r="3.5"/><path d="M2 20c0-3.5 3-6 7-6s7 2.5 7 6"/><path d="M16 4a3.5 3.5 0 010 7M22 20c0-3-2-5-5-5.5"/></>,
    gear: <><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1"/></>,
    heart: <><path d="M12 20s-7-4.5-9-9a5 5 0 019-3 5 5 0 019 3c-2 4.5-9 9-9 9z"/></>,
    comment: <><path d="M21 12a8 8 0 01-11.5 7L4 21l2-5.5A8 8 0 1121 12z"/></>,
    bookmark: <><path d="M6 4h12v17l-6-4-6 4V4z"/></>,
    clock: <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
    flame: <><path d="M12 3s4 4 4 8a4 4 0 11-8 0c0-2 1-3 1-3s1 2 3 2c0-3-3-5 0-7z"/><path d="M8 16a4 4 0 008 0"/></>,
    check: <><path d="M4 12l5 5L20 6"/></>,
    play: <><path d="M7 4l12 8-12 8V4z" fill="currentColor"/></>,
    pause: <><rect x="6" y="5" width="4" height="14" fill="currentColor"/><rect x="14" y="5" width="4" height="14" fill="currentColor"/></>,
    camera: <><path d="M4 7h3l2-3h6l2 3h3v13H4V7z"/><circle cx="12" cy="13" r="4"/></>,
    trash: <><path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/></>,
    minus: <><path d="M5 12h14"/></>,
    edit: <><path d="M4 20h4L20 8l-4-4L4 16v4z"/></>,
    share: <><path d="M12 3v12M7 8l5-5 5 5M5 15v5h14v-5"/></>,
    filter: <><path d="M3 5h18M6 12h12M10 19h4"/></>,
    bell: <><path d="M6 16V11a6 6 0 1112 0v5l2 2H4l2-2z"/><path d="M10 20a2 2 0 004 0"/></>,
    sparkle: <><path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5L18 18M6 18l2.5-2.5M15.5 8.5L18 6"/></>,
    target: <><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/></>,
    trend: <><path d="M3 17l6-6 4 4 8-8M15 7h6v6"/></>,
    arrowUp: <><path d="M12 19V5M5 12l7-7 7 7"/></>,
    arrowRight: <><path d="M5 12h14M12 5l7 7-7 7"/></>,
    more: <><circle cx="5" cy="12" r="1.5" fill="currentColor"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><circle cx="19" cy="12" r="1.5" fill="currentColor"/></>,
    scale: <><path d="M4 20h16M6 20V10l6-5 6 5v10"/><path d="M10 20v-5h4v5"/></>,
    ruler: <><rect x="3" y="8" width="18" height="8" rx="1"/><path d="M7 8v3M11 8v4M15 8v3M19 8v4"/></>,
  };
  return <svg {...common}>{paths[name] || null}</svg>;
};

// ───────── App bar (large title) ─────────
const AppBar = ({ eyebrow, title, right, left, sub }) => (
  <div className="pc-appbar">
    <div>
      {eyebrow && <div className="t-eyebrow" style={{color:'var(--ink-3)', marginBottom: 8}}>{eyebrow}</div>}
      <div className="pc-appbar__title">{title}</div>
      {sub && <div className="pc-appbar__sub">{sub}</div>}
    </div>
    <div style={{display:'flex', gap: 8, alignItems:'center'}}>
      {left}
      {right}
    </div>
  </div>
);

// ───────── Tab bar ─────────
const TabBar = ({ active = 'today', onChange = () => {} }) => {
  const tabs = [
    { id: 'today', label: 'Today', icon: 'home' },
    { id: 'recipes', label: 'Recipes', icon: 'fork' },
    { id: 'train', label: 'Train', icon: 'dumb' },
    { id: 'feed', label: 'Feed', icon: 'users' },
    { id: 'me', label: 'Me', icon: 'gear' },
  ];
  return (
    <div className="pc-tabbar">
      {tabs.map(t => (
        <button key={t.id} className={`pc-tab ${active === t.id ? 'pc-tab--active' : ''}`} onClick={() => onChange(t.id)}>
          <Icon name={t.icon} size={22} stroke={active === t.id ? 2 : 1.75}/>
          <div>{t.label}</div>
          <div className="pc-tab__dot"/>
        </button>
      ))}
    </div>
  );
};

// ───────── Horizontal macro bar ─────────
const MacroBar = ({ label, unit = 'g', current, goal, color, big = false }) => {
  const pct = goal > 0 ? Math.min(current / goal, 1) : 0;
  const over = goal > 0 ? Math.max((current / goal) - 1, 0) : 0;
  const remaining = Math.max(goal - current, 0);
  return (
    <div>
      <div style={{display:'flex', alignItems:'baseline', justifyContent:'space-between', marginBottom: 8}}>
        <div style={{display:'flex', alignItems:'baseline', gap: 10}}>
          <span className="t-label" style={{color: 'var(--ink-2)'}}>{label}</span>
          {over > 0 && <span className="t-mono" style={{fontSize: 10, color: color, fontWeight: 700}}>OVER {Math.round(over * 100)}%</span>}
        </div>
        <div style={{display:'flex', alignItems:'baseline', gap: 6}}>
          <span className="t-num" style={{fontSize: big ? 28 : 20}}>{Math.round(current)}</span>
          <span className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)'}}>/ {Math.round(goal)} {unit}</span>
        </div>
      </div>
      <div className="pc-bar">
        <div className="pc-bar__fill" style={{width: `${pct * 100}%`, background: color}}/>
        {over > 0 && (
          <div className="pc-bar__fill" style={{
            width: `${Math.min(over, 1) * 100}%`,
            background: `repeating-linear-gradient(45deg, ${color} 0 4px, rgba(255,255,255,0.4) 4px 7px)`,
            opacity: 0.85
          }}/>
        )}
      </div>
      <div style={{display:'flex', justifyContent:'space-between', marginTop: 6}}>
        <span className="t-mono" style={{fontSize: 10, color: 'var(--ink-4)'}}>
          {remaining > 0 ? `${Math.round(remaining)} ${unit} left` : 'goal hit'}
        </span>
        <span className="t-mono" style={{fontSize: 10, color: 'var(--ink-4)'}}>
          {Math.round(pct * 100)}%
        </span>
      </div>
    </div>
  );
};

// ───────── Status bar ─────────
const StatusBar = ({ dark = false, time = '9:41' }) => {
  const c = dark ? '#fff' : '#000';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '16px 28px 8px', width: '100%',
    }}>
      <span style={{ fontFamily: '-apple-system, "SF Pro", system-ui', fontWeight: 600, fontSize: 15, color: c }}>{time}</span>
      <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
        <svg width="17" height="11" viewBox="0 0 19 12"><rect x="0" y="7.5" width="3.2" height="4.5" rx="0.7" fill={c}/><rect x="4.8" y="5" width="3.2" height="7" rx="0.7" fill={c}/><rect x="9.6" y="2.5" width="3.2" height="9.5" rx="0.7" fill={c}/><rect x="14.4" y="0" width="3.2" height="12" rx="0.7" fill={c}/></svg>
        <svg width="15" height="11" viewBox="0 0 17 12"><path d="M8.5 3.2C10.8 3.2 12.9 4.1 14.4 5.6L15.5 4.5C13.7 2.7 11.2 1.5 8.5 1.5C5.8 1.5 3.3 2.7 1.5 4.5L2.6 5.6C4.1 4.1 6.2 3.2 8.5 3.2Z" fill={c}/><path d="M8.5 6.8C9.9 6.8 11.1 7.3 12 8.2L13.1 7.1C11.8 5.9 10.2 5.1 8.5 5.1C6.8 5.1 5.2 5.9 3.9 7.1L5 8.2C5.9 7.3 7.1 6.8 8.5 6.8Z" fill={c}/><circle cx="8.5" cy="10.5" r="1.5" fill={c}/></svg>
        <svg width="24" height="11" viewBox="0 0 27 13"><rect x="0.5" y="0.5" width="23" height="12" rx="3.5" stroke={c} strokeOpacity="0.35" fill="none"/><rect x="2" y="2" width="20" height="9" rx="2" fill={c}/><path d="M25 4.5V8.5C25.8 8.2 26.5 7.2 26.5 6.5C26.5 5.8 25.8 4.8 25 4.5Z" fill={c} fillOpacity="0.4"/></svg>
      </div>
    </div>
  );
};

// ───────── Simple iPhone frame ─────────
const Phone = ({ children, label, width = 390, height = 844, dark = false }) => (
  <div style={{display:'flex', flexDirection:'column', alignItems:'center', gap: 12}}>
    <div style={{
      width, height,
      background: '#0A0B10',
      borderRadius: 54,
      padding: 11,
      boxShadow: '0 30px 60px rgba(14,16,20,0.18), 0 10px 20px rgba(14,16,20,0.08), inset 0 0 0 1px rgba(255,255,255,0.05)',
      position: 'relative',
    }}>
      <div style={{
        width: '100%', height: '100%',
        borderRadius: 44,
        overflow: 'hidden',
        background: dark ? '#0A0B10' : 'var(--bg)',
        position: 'relative',
      }}>
        {/* Dynamic island */}
        <div style={{
          position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
          width: 120, height: 34, background: '#000', borderRadius: 999, zIndex: 50,
        }}/>
        <StatusBar dark={dark}/>
        <div style={{flex: 1, height: 'calc(100% - 44px)', display: 'flex', flexDirection: 'column'}}>
          {children}
        </div>
      </div>
    </div>
    {label && <div className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)', letterSpacing: '0.1em', textTransform: 'uppercase'}}>{label}</div>}
  </div>
);

// ───────── Placeholder image ─────────
const Placeholder = ({ label = 'photo', h = 120, rounded = 14, dark = false, style = {} }) => (
  <div className={`pc-placeholder ${dark ? 'pc-placeholder--dark' : ''}`} style={{
    height: h, borderRadius: rounded, ...style,
  }}>
    <span style={{position:'relative', zIndex:1}}>{label}</span>
  </div>
);

// Export to window for cross-file use
Object.assign(window, { Icon, AppBar, TabBar, MacroBar, StatusBar, Phone, Placeholder });
