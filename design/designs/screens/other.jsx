// Workouts list + Active workout + Feed + Onboarding + Settings

// ═════════════════ WORKOUTS LIST ═════════════════
const WorkoutsListScreen = ({ onStart, onTemplate }) => {
  const history = [
    { date: 'Wed · Apr 22', name: 'Push day', dur: '52m', vol: '4,820', sets: 18, prs: 2 },
    { date: 'Mon · Apr 20', name: 'Pull day', dur: '48m', vol: '5,210', sets: 16, prs: 1 },
    { date: 'Sat · Apr 18', name: 'Legs', dur: '61m', vol: '7,450', sets: 20, prs: 0 },
  ];
  const templates = [
    { name: 'Push · chest focus', count: 6 },
    { name: 'Pull · vertical', count: 5 },
    { name: 'Legs · quad day', count: 7 },
  ];
  return (
    <div className="pc-screen">
      <AppBar
        eyebrow="Week 16 · 3 of 4 done"
        title="Train"
        right={<button className="pc-icon-btn pc-icon-btn--ink"><Icon name="plus" size={20}/></button>}
      />

      <div className="pc-scroll" style={{padding: '0 16px 20px'}}>
        {/* Start CTA card */}
        <div className="pc-card pc-card--indigo" style={{padding: 22, position: 'relative', overflow:'hidden'}}>
          <div className="t-eyebrow" style={{color:'rgba(255,255,255,0.65)'}}>Next up</div>
          <div className="t-display" style={{fontSize: 30, marginTop: 4, color:'#fff'}}>Push day</div>
          <div className="t-mono" style={{fontSize: 11, color:'rgba(255,255,255,0.7)', marginTop: 6, letterSpacing:'0.05em'}}>
            6 EXERCISES · ~50 MIN · LAST: +5 KG BENCH PR
          </div>
          <button onClick={onStart} className="pc-btn pc-btn--lime" style={{marginTop: 16}}>
            <Icon name="play" size={14}/> Start workout
          </button>
        </div>

        {/* Weekly stats */}
        <div style={{display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap: 8, marginTop: 12}}>
          {[
            { l:'workouts', v:'3', s:'of 4' },
            { l:'volume', v:'17.4k', s:'kg' },
            { l:'prs', v:'3', s:'this week' },
          ].map(s => (
            <div key={s.l} className="pc-card" style={{padding: 14}}>
              <div className="t-num" style={{fontSize: 26}}>{s.v}</div>
              <div className="t-mono" style={{fontSize: 9, color:'var(--ink-3)', letterSpacing:'0.1em', textTransform:'uppercase', marginTop: 2}}>{s.l}</div>
              <div className="t-mono" style={{fontSize: 9, color:'var(--ink-4)', marginTop: 2}}>{s.s}</div>
            </div>
          ))}
        </div>

        {/* Templates */}
        <div style={{marginTop: 22}}>
          <div style={{display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom: 10}}>
            <div className="t-display" style={{fontSize: 20}}>Templates</div>
            <span className="t-mono" style={{fontSize: 10, color:'var(--ink-3)'}}>3 SAVED</span>
          </div>
          <div style={{display:'flex', gap: 10, overflowX:'auto', paddingBottom: 4}}>
            {templates.map(t => (
              <button key={t.name} onClick={onTemplate} className="pc-card" style={{minWidth: 170, padding: 14, textAlign:'left', flexShrink: 0}}>
                <div style={{width: 36, height: 36, borderRadius: 10, background:'rgba(43,46,255,0.1)', color:'var(--indigo)', display:'flex', alignItems:'center', justifyContent:'center'}}>
                  <Icon name="dumb" size={20}/>
                </div>
                <div style={{fontSize: 14, fontWeight: 600, marginTop: 12, lineHeight: 1.2}}>{t.name}</div>
                <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)', marginTop: 4}}>{t.count} exercises</div>
              </button>
            ))}
          </div>
        </div>

        {/* History */}
        <div style={{marginTop: 22}}>
          <div className="t-display" style={{fontSize: 20, marginBottom: 10}}>History</div>
          <div className="pc-card" style={{padding: '4px 18px'}}>
            {history.map((h,i) => (
              <div key={i} className="pc-row" style={{padding: '14px 0'}}>
                <div style={{flex: 1}}>
                  <div style={{display:'flex', alignItems:'center', gap: 8}}>
                    <span style={{fontSize: 14, fontWeight: 600}}>{h.name}</span>
                    {h.prs > 0 && <span className="pc-chip pc-chip--lime" style={{padding: '2px 6px', fontSize: 9}}>{h.prs} PR</span>}
                  </div>
                  <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)', marginTop: 3}}>{h.date} · {h.dur} · {h.sets} sets</div>
                </div>
                <div style={{textAlign:'right'}}>
                  <div className="t-num" style={{fontSize: 18}}>{h.vol}</div>
                  <div className="t-mono" style={{fontSize: 9, color:'var(--ink-3)'}}>KG VOLUME</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <TabBar active="train"/>
    </div>
  );
};

// ═════════════════ ACTIVE WORKOUT ═════════════════
const ActiveWorkoutScreen = ({ onFinish, onCancel }) => {
  const [elapsed, setElapsed] = useState(1847); // 30:47
  const [rest, setRest] = useState(62);
  const [restOn, setRestOn] = useState(true);

  useEffect(() => {
    const t = setInterval(() => setElapsed(e => e + 1), 1000);
    return () => clearInterval(t);
  }, []);
  useEffect(() => {
    if (!restOn) return;
    const t = setInterval(() => setRest(r => Math.max(0, r - 1)), 1000);
    return () => clearInterval(t);
  }, [restOn]);

  const fmt = (s) => {
    const m = Math.floor(s/60), ss = s%60;
    const h = Math.floor(m/60);
    return h > 0 ? `${h}:${String(m%60).padStart(2,'0')}:${String(ss).padStart(2,'0')}` : `${String(m).padStart(2,'0')}:${String(ss).padStart(2,'0')}`;
  };

  const [sets, setSets] = useState({
    'bench': [
      { w: 60, r: 10, done: true, prev: '60×10' },
      { w: 70, r: 8, done: true, prev: '65×8' },
      { w: 75, r: 6, done: true, prev: '70×6', pr: true },
      { w: 75, r: 6, done: false, prev: '70×5' },
    ],
    'incline': [
      { w: 22, r: 10, done: false, prev: '20×10' },
      { w: 22, r: 10, done: false, prev: '20×10' },
      { w: 22, r: 10, done: false, prev: '20×8' },
    ]
  });

  return (
    <div className="pc-screen pc-screen--dark">
      {/* top bar */}
      <div style={{padding: '4px 16px 10px', display:'flex', alignItems:'center', justifyContent:'space-between'}}>
        <button onClick={onCancel} className="pc-icon-btn" style={{background:'rgba(255,255,255,0.08)', color:'#fff', borderColor:'transparent'}}>
          <Icon name="close" size={18}/>
        </button>
        <div style={{textAlign:'center'}}>
          <div className="t-mono" style={{fontSize: 10, color:'rgba(245,243,238,0.5)', letterSpacing:'0.1em'}}>PUSH DAY · ELAPSED</div>
          <div className="t-num" style={{fontSize: 22, fontFeatureSettings:'"tnum"', marginTop: 2}}>{fmt(elapsed)}</div>
        </div>
        <button onClick={onFinish} className="pc-btn pc-btn--sm pc-btn--lime">Finish</button>
      </div>

      {/* Rest timer giant */}
      {restOn && (
        <div style={{margin: '8px 16px', padding: '16px 20px', borderRadius: 22, background: 'rgba(212,255,58,0.08)', border: '1px solid rgba(212,255,58,0.2)', display:'flex', alignItems:'center', justifyContent:'space-between'}}>
          <div>
            <div className="t-mono" style={{fontSize: 10, color:'var(--lime)', letterSpacing:'0.1em'}}>REST TIMER</div>
            <div className="t-num" style={{fontSize: 44, color:'var(--lime)', lineHeight: 1}}>0:{String(rest).padStart(2,'0')}</div>
          </div>
          <div style={{display:'flex', gap: 6}}>
            <button onClick={() => setRest(r => Math.max(0, r-15))} className="pc-icon-btn" style={{background:'rgba(255,255,255,0.08)', color:'#fff', borderColor:'transparent'}}>−15</button>
            <button onClick={() => setRest(r => r+15)} className="pc-icon-btn" style={{background:'rgba(255,255,255,0.08)', color:'#fff', borderColor:'transparent'}}>+15</button>
            <button onClick={() => setRestOn(false)} className="pc-icon-btn" style={{background:'var(--lime)', color:'var(--lime-ink)', borderColor:'transparent'}}>
              <Icon name="pause" size={16}/>
            </button>
          </div>
        </div>
      )}

      <div className="pc-scroll" style={{padding: '8px 16px 20px'}}>
        {/* Exercise card */}
        {[
          { id: 'bench', name: 'Barbell Bench Press', muscle: 'chest', sets: sets.bench },
          { id: 'incline', name: 'Incline DB Press', muscle: 'chest', sets: sets.incline },
        ].map(ex => (
          <div key={ex.id} style={{padding: 18, borderRadius: 22, background:'rgba(255,255,255,0.04)', marginBottom: 10, border:'1px solid rgba(255,255,255,0.06)'}}>
            <div style={{display:'flex', alignItems:'center', justifyContent:'space-between'}}>
              <div>
                <div className="t-display" style={{fontSize: 20, color: '#fff'}}>{ex.name}</div>
                <div className="t-mono" style={{fontSize: 10, color:'rgba(245,243,238,0.5)', marginTop: 3, letterSpacing:'0.1em', textTransform:'uppercase'}}>
                  {ex.muscle} · {ex.sets.filter(s=>s.done).length}/{ex.sets.length} sets
                </div>
              </div>
              <button className="pc-icon-btn" style={{background:'rgba(255,255,255,0.08)', color:'#fff', borderColor:'transparent'}}>
                <Icon name="more" size={18}/>
              </button>
            </div>

            {/* Set header */}
            <div style={{display:'grid', gridTemplateColumns:'36px 1fr 1fr 1fr 40px', gap: 8, marginTop: 14, alignItems:'center'}}>
              <span className="t-mono" style={{fontSize: 9, color:'rgba(245,243,238,0.35)', letterSpacing:'0.1em'}}>SET</span>
              <span className="t-mono" style={{fontSize: 9, color:'rgba(245,243,238,0.35)', letterSpacing:'0.1em'}}>PREV</span>
              <span className="t-mono" style={{fontSize: 9, color:'rgba(245,243,238,0.35)', letterSpacing:'0.1em'}}>KG</span>
              <span className="t-mono" style={{fontSize: 9, color:'rgba(245,243,238,0.35)', letterSpacing:'0.1em'}}>REPS</span>
              <span/>
            </div>

            {ex.sets.map((s, i) => (
              <div key={i} style={{
                display:'grid', gridTemplateColumns:'36px 1fr 1fr 1fr 40px', gap: 8, alignItems:'center',
                padding: '10px 0', borderTop: '1px solid rgba(255,255,255,0.06)',
                opacity: s.done ? 0.7 : 1,
              }}>
                <div style={{
                  width: 30, height: 30, borderRadius: 8,
                  background: s.pr ? 'var(--lime)' : s.done ? 'rgba(212,255,58,0.15)' : 'rgba(255,255,255,0.06)',
                  color: s.pr ? 'var(--lime-ink)' : s.done ? 'var(--lime)' : '#fff',
                  display:'flex', alignItems:'center', justifyContent:'center',
                  fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 12,
                }}>
                  {s.pr ? 'PR' : i+1}
                </div>
                <span className="t-mono" style={{fontSize: 12, color:'rgba(245,243,238,0.45)'}}>{s.prev}</span>
                <span className="t-num" style={{fontSize: 22, color: s.done ? 'rgba(245,243,238,0.7)' : '#fff'}}>{s.w}</span>
                <span className="t-num" style={{fontSize: 22, color: s.done ? 'rgba(245,243,238,0.7)' : '#fff'}}>{s.r}</span>
                <button
                  style={{
                    width: 36, height: 36, borderRadius: 10,
                    background: s.done ? 'var(--lime)' : 'rgba(255,255,255,0.08)',
                    color: s.done ? 'var(--lime-ink)' : '#fff',
                    display:'flex', alignItems:'center', justifyContent:'center',
                  }}
                >
                  <Icon name="check" size={16}/>
                </button>
              </div>
            ))}

            <button style={{width:'100%', marginTop: 10, padding: '10px', borderRadius: 10, background:'rgba(255,255,255,0.04)', border:'1px dashed rgba(255,255,255,0.15)', color:'rgba(245,243,238,0.65)', fontSize: 12, fontFamily:'var(--font-mono)', letterSpacing:'0.08em', textTransform:'uppercase'}}>
              + Add set
            </button>
          </div>
        ))}

        <button style={{width:'100%', marginTop: 8, padding: '14px', borderRadius: 16, background:'rgba(255,255,255,0.04)', border:'1px dashed rgba(255,255,255,0.15)', color:'#fff', display:'flex', justifyContent:'center', alignItems:'center', gap: 8}}>
          <Icon name="plus" size={16}/> Add exercise
        </button>
      </div>
    </div>
  );
};

// ═════════════════ FEED (magazine grid) ═════════════════
const FeedScreen = ({ onOpenPost }) => {
  return (
    <div className="pc-screen">
      <AppBar
        eyebrow="12 friends · cooking this week"
        title="Feed"
        right={
          <>
            <button className="pc-icon-btn"><Icon name="users" size={18}/></button>
            <button className="pc-icon-btn"><Icon name="search" size={18}/></button>
          </>
        }
      />

      <div className="pc-scroll" style={{padding: '0 16px 20px'}}>
        {/* Hero featured post (big) */}
        <button onClick={onOpenPost} className="pc-card" style={{width:'100%', padding: 0, textAlign:'left', overflow:'hidden', marginBottom: 10}}>
          <Placeholder label="maya · salmon donburi" h={240} rounded={0}/>
          <div style={{padding: 16}}>
            <div style={{display:'flex', alignItems:'center', gap: 10}}>
              <div style={{width: 28, height: 28, borderRadius:999, background:'var(--indigo)', color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontSize: 12, fontWeight: 700}}>M</div>
              <div style={{flex:1}}>
                <div style={{fontSize: 13, fontWeight: 600}}>Maya K.</div>
                <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)'}}>@mayacooks · 2h</div>
              </div>
              <span className="pc-chip pc-chip--lime" style={{padding:'2px 7px', fontSize: 9}}>HP</span>
            </div>
            <div className="t-display" style={{fontSize: 22, marginTop: 12, lineHeight: 1.1}}>Salmon donburi, 45g protein</div>
            <div style={{fontSize: 13, color:'var(--ink-3)', marginTop: 6}}>Toasted the rice in sesame oil. Game changer.</div>
            <div style={{display:'flex', gap: 16, marginTop: 12}}>
              <span style={{display:'flex', gap: 5, alignItems:'center'}}><Icon name="heart" size={14} color="var(--fat)"/><span className="t-mono" style={{fontSize: 12}}>28</span></span>
              <span style={{display:'flex', gap: 5, alignItems:'center'}}><Icon name="comment" size={14} color="var(--ink-3)"/><span className="t-mono" style={{fontSize: 12}}>6</span></span>
              <span style={{display:'flex', gap: 5, alignItems:'center'}}><Icon name="bookmark" size={14} color="var(--ink-3)"/><span className="t-mono" style={{fontSize: 12}}>12 saved</span></span>
            </div>
          </div>
        </button>

        {/* Magazine grid row: text quote + small post */}
        <div style={{display:'grid', gridTemplateColumns:'1.1fr 1fr', gap: 10, marginBottom: 10}}>
          <div className="pc-card pc-card--ink" style={{padding: 18, display:'flex', flexDirection:'column', justifyContent:'space-between'}}>
            <div className="t-eyebrow" style={{color:'rgba(255,255,255,0.5)'}}>@jordan</div>
            <div className="t-display" style={{fontSize: 22, color:'#fff', lineHeight: 1.1, marginTop: 14}}>
              "Cottage cheese pancakes saved my bulk."
            </div>
            <div className="t-mono" style={{fontSize: 10, color:'rgba(255,255,255,0.5)', marginTop: 14}}>
              3 FRIENDS SAVED
            </div>
          </div>
          <button onClick={onOpenPost} className="pc-card" style={{padding: 0, overflow:'hidden', textAlign:'left'}}>
            <Placeholder label="pancakes" h={130} rounded={0}/>
            <div style={{padding: 12}}>
              <div style={{fontSize: 13, fontWeight: 600, lineHeight: 1.2}}>Cottage cheese pancakes</div>
              <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)', marginTop: 6}}>38g P · 420 kcal</div>
            </div>
          </button>
        </div>

        {/* Two equal */}
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap: 10, marginBottom: 10}}>
          {[
            { name: 'Priya', handle: '@priya', dish: 'Greek lamb bowl', p: 48, k: 580, color: '#8B3A1E' },
            { name: 'Alex', handle: '@alexlifts', dish: 'Tuna pasta salad', p: 40, k: 460, color: '#D4A259' },
          ].map(p => (
            <button key={p.name} onClick={onOpenPost} className="pc-card" style={{padding: 0, overflow:'hidden', textAlign:'left'}}>
              <Placeholder label={p.dish.split(' ')[0].toLowerCase()} h={120} rounded={0}/>
              <div style={{padding: 12}}>
                <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)'}}>{p.handle}</div>
                <div style={{fontSize: 13, fontWeight: 600, lineHeight: 1.2, marginTop: 4}}>{p.dish}</div>
                <div className="t-mono" style={{fontSize: 10, color:'var(--protein)', marginTop: 6, fontWeight: 600}}>{p.p}g P</div>
              </div>
            </button>
          ))}
        </div>

        {/* Wide horizontal */}
        <button onClick={onOpenPost} className="pc-card" style={{width:'100%', padding: 14, display:'flex', gap: 14, alignItems:'center', textAlign:'left'}}>
          <Placeholder label="chili" h={80} rounded={12} style={{width: 80, flexShrink: 0}}/>
          <div style={{flex: 1}}>
            <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)'}}>@samlifts · adapted from you</div>
            <div style={{fontSize: 14, fontWeight: 600, marginTop: 4}}>Turkey chili — spicier version</div>
            <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)', marginTop: 4}}>50g P · 570 kcal · 8 saves</div>
          </div>
          <Icon name="chevronRight" size={16} color="var(--ink-4)"/>
        </button>
      </div>

      <TabBar active="feed"/>
    </div>
  );
};

// ═════════════════ FEED POST DETAIL ═════════════════
const FeedPostScreen = ({ onBack }) => (
  <div className="pc-screen">
    <div style={{position:'relative'}}>
      <Placeholder label="maya · donburi" h={320} rounded={0}/>
      <button onClick={onBack} className="pc-icon-btn" style={{position:'absolute', top: 12, left: 20}}>
        <Icon name="chevronLeft" size={20}/>
      </button>
    </div>
    <div className="pc-scroll" style={{padding: '18px 20px 100px'}}>
      <div style={{display:'flex', alignItems:'center', gap: 12}}>
        <div style={{width: 40, height: 40, borderRadius:999, background:'var(--indigo)', color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontSize: 16, fontWeight: 700}}>M</div>
        <div style={{flex: 1}}>
          <div style={{fontWeight: 600, fontSize: 15}}>Maya K.</div>
          <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)'}}>@mayacooks · 2h ago</div>
        </div>
        <button className="pc-btn pc-btn--sm pc-btn--ghost">Following</button>
      </div>

      <div className="t-display" style={{fontSize: 28, marginTop: 18, lineHeight: 1.1}}>Salmon donburi, 45g protein</div>
      <div style={{fontSize: 14, color:'var(--ink-2)', marginTop: 10, lineHeight: 1.55}}>
        Toasted the rice in sesame oil before adding water — nutty, crispy bottom. Swapped avocado for kewpie-glazed cucumbers to cut fat.
      </div>

      <div className="pc-card pc-card--ink" style={{padding: 18, marginTop: 18, display:'flex', gap: 14, alignItems:'center'}}>
        <Placeholder label="donburi" h={56} rounded={12} style={{width: 56}} dark/>
        <div style={{flex: 1}}>
          <div style={{color: '#fff', fontWeight: 600}}>Salmon donburi bowl</div>
          <div className="t-mono" style={{fontSize: 10, color:'rgba(255,255,255,0.55)', marginTop: 3}}>45g P · 540 kcal / serving</div>
        </div>
        <button className="pc-btn pc-btn--sm pc-btn--lime">Save copy</button>
      </div>

      <div style={{display:'flex', gap: 22, marginTop: 22}}>
        <button style={{display:'flex', gap: 8, alignItems:'center'}}>
          <Icon name="heart" size={20} color="var(--fat)"/> <span className="t-mono" style={{fontSize: 13}}>28</span>
        </button>
        <button style={{display:'flex', gap: 8, alignItems:'center'}}>
          <Icon name="comment" size={20}/> <span className="t-mono" style={{fontSize: 13}}>6</span>
        </button>
        <button style={{display:'flex', gap: 8, alignItems:'center', marginLeft:'auto'}}>
          <Icon name="share" size={20}/>
        </button>
      </div>

      <div style={{marginTop: 24, borderTop: '1px solid var(--line)', paddingTop: 18}}>
        <div className="t-label">Comments</div>
        {[
          { n: 'Alex', h: '@alexlifts', t: 'Crispy rice?? genius. trying this tomorrow' },
          { n: 'Priya', h: '@priya', t: 'how much salmon per bowl?' },
        ].map((c,i)=>(
          <div key={i} style={{display:'flex', gap: 10, marginTop: 14}}>
            <div style={{width: 28, height: 28, borderRadius:999, background:'var(--ink)', color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontSize: 11, fontWeight: 700}}>{c.n[0]}</div>
            <div style={{flex:1}}>
              <div style={{fontSize: 13}}><b>{c.n}</b> <span className="t-mono" style={{fontSize: 10, color:'var(--ink-3)'}}>{c.h}</span></div>
              <div style={{fontSize: 13, color:'var(--ink-2)', marginTop: 2}}>{c.t}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  </div>
);

// ═════════════════ ONBOARDING ═════════════════
const OnboardingScreen = () => {
  const [step, setStep] = useState(3);
  const total = 6;
  return (
    <div className="pc-screen pc-screen--paper">
      <div style={{padding: '4px 20px 16px', display:'flex', alignItems:'center', gap: 10}}>
        <button className="pc-icon-btn"><Icon name="chevronLeft" size={18}/></button>
        <div style={{flex: 1, display:'flex', gap: 4}}>
          {[...Array(total)].map((_,i)=>(
            <div key={i} style={{flex:1, height: 4, borderRadius: 999, background: i < step ? 'var(--ink)' : 'var(--line)'}}/>
          ))}
        </div>
        <button className="t-mono" style={{fontSize: 11, color:'var(--ink-3)', letterSpacing:'0.1em'}}>SKIP</button>
      </div>

      <div className="pc-scroll" style={{padding: '20px 24px'}}>
        <div className="t-mono" style={{fontSize: 11, color:'var(--indigo)', letterSpacing:'0.12em'}}>STEP {step} OF {total}</div>
        <div className="t-display" style={{fontSize: 38, lineHeight: 1.05, marginTop: 10, letterSpacing:'-0.035em'}}>
          What's your<br/>protein target?
        </div>
        <div style={{fontSize: 14, color:'var(--ink-3)', marginTop: 10, maxWidth: 280}}>
          Typical recommendation: 1.6–2.2 g per kg of bodyweight for muscle building.
        </div>

        {/* Big numeric input */}
        <div className="pc-card pc-card--ink" style={{padding: 30, marginTop: 28, textAlign: 'center', position:'relative', overflow:'hidden'}}>
          <div className="t-eyebrow" style={{color:'rgba(255,255,255,0.5)'}}>Daily target</div>
          <div style={{display:'flex', alignItems:'baseline', justifyContent:'center', gap: 8, marginTop: 12}}>
            <span className="t-display" style={{fontSize: 112, color:'var(--lime)', lineHeight: 0.9}}>180</span>
            <span className="t-mono" style={{fontSize: 16, color:'rgba(255,255,255,0.65)'}}>g / day</span>
          </div>
          <div className="t-mono" style={{fontSize: 11, color:'rgba(255,255,255,0.55)', marginTop: 10, letterSpacing:'0.08em'}}>
            2.2G · KG · MUSCLE BUILD
          </div>

          {/* Slider */}
          <div style={{marginTop: 24, height: 6, background:'rgba(255,255,255,0.12)', borderRadius: 999, position:'relative'}}>
            <div style={{position:'absolute', inset: 0, width: '62%', background:'var(--lime)', borderRadius: 999}}/>
            <div style={{position:'absolute', left: '62%', top: '50%', transform:'translate(-50%, -50%)', width: 22, height: 22, borderRadius:999, background:'#fff', border: '3px solid var(--lime)'}}/>
          </div>
          <div style={{display:'flex', justifyContent:'space-between', marginTop: 10}}>
            <span className="t-mono" style={{fontSize: 10, color:'rgba(255,255,255,0.45)'}}>80g</span>
            <span className="t-mono" style={{fontSize: 10, color:'rgba(255,255,255,0.45)'}}>280g</span>
          </div>
        </div>

        {/* Presets */}
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap: 8, marginTop: 14}}>
          {[
            { l:'maintain', v:'1.6g' },
            { l:'build', v:'2.2g', active: true },
            { l:'cut', v:'2.4g' },
          ].map(p => (
            <button key={p.l} className={`pc-card ${p.active ? '' : ''}`} style={{
              padding: 12, textAlign:'center',
              background: p.active ? 'var(--ink)' : 'var(--paper)',
              color: p.active ? '#fff' : 'var(--ink)',
              borderColor: p.active ? 'var(--ink)' : 'var(--line)',
            }}>
              <div className="t-num" style={{fontSize: 20}}>{p.v}</div>
              <div className="t-mono" style={{fontSize: 9, letterSpacing:'0.1em', textTransform:'uppercase', marginTop: 4, opacity: 0.7}}>{p.l} · kg</div>
            </button>
          ))}
        </div>
      </div>

      <div style={{padding: '12px 20px 32px'}}>
        <button onClick={() => setStep(Math.min(total, step+1))} className="pc-btn pc-btn--block pc-btn--indigo">
          Continue <Icon name="arrowRight" size={16}/>
        </button>
      </div>
    </div>
  );
};

// ═════════════════ SETTINGS / ME ═════════════════
const SettingsScreen = () => {
  return (
    <div className="pc-screen">
      <AppBar
        eyebrow="Account · settings"
        title="Me"
        right={<button className="pc-icon-btn"><Icon name="edit" size={18}/></button>}
      />
      <div className="pc-scroll" style={{padding: '0 16px 20px'}}>
        <div className="pc-card" style={{padding: 20, display:'flex', gap: 14, alignItems:'center'}}>
          <div style={{width: 60, height: 60, borderRadius: 999, background: 'var(--indigo)', color: '#fff', display:'flex', alignItems:'center', justifyContent:'center'}}>
            <span className="t-display" style={{fontSize: 26}}>A</span>
          </div>
          <div style={{flex: 1}}>
            <div className="t-display" style={{fontSize: 22}}>Ahmed</div>
            <div className="t-mono" style={{fontSize: 11, color:'var(--ink-3)', marginTop: 3}}>@ahmed · 12 friends</div>
          </div>
        </div>

        {/* Stats */}
        <div style={{display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap: 8, marginTop: 12}}>
          {[
            { v:'42', l:'recipes' },
            { v:'28', l:'workouts' },
            { v:'94d', l:'streak' },
          ].map(s => (
            <div key={s.l} className="pc-card" style={{padding: 14, textAlign:'center'}}>
              <div className="t-num" style={{fontSize: 26}}>{s.v}</div>
              <div className="t-label" style={{marginTop: 4}}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* Goals card */}
        <div className="pc-card" style={{padding: 18, marginTop: 14}}>
          <div style={{display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom: 12}}>
            <div className="t-display" style={{fontSize: 18}}>Daily targets</div>
            <button className="t-mono" style={{fontSize: 11, color:'var(--indigo)', fontWeight: 600, letterSpacing:'0.08em'}}>EDIT</button>
          </div>
          {[
            { l:'Protein', v:'200 g', c:'var(--protein)' },
            { l:'Calories', v:'2,400 kcal', c:'var(--ink)' },
            { l:'Bodyweight', v:'82 kg', c:'var(--ink)' },
            { l:'Goal', v:'Build', c:'var(--ink)' },
          ].map(row => (
            <div key={row.l} className="pc-row">
              <span style={{flex: 1, fontSize: 14}}>{row.l}</span>
              <span className="t-num" style={{fontSize: 16, color: row.c}}>{row.v}</span>
            </div>
          ))}
        </div>

        {/* Menus */}
        <div className="pc-card" style={{padding: '4px 18px', marginTop: 14}}>
          {[
            { i:'bell', l:'Notifications' },
            { i:'ruler', l:'Units', v:'Metric' },
            { i:'users', l:'Friends' },
            { i:'share', l:'Share ProteinChef' },
          ].map(item => (
            <div key={item.l} className="pc-row">
              <div style={{width: 32, height: 32, borderRadius: 9, background:'rgba(14,16,20,0.05)', display:'flex', alignItems:'center', justifyContent:'center'}}>
                <Icon name={item.i} size={16} color="var(--ink-2)"/>
              </div>
              <span style={{flex: 1, fontSize: 14}}>{item.l}</span>
              {item.v && <span className="t-mono" style={{fontSize: 11, color:'var(--ink-3)'}}>{item.v}</span>}
              <Icon name="chevronRight" size={14} color="var(--ink-4)"/>
            </div>
          ))}
        </div>

        <button style={{width:'100%', marginTop: 20, padding: '14px', color: 'var(--fat)', fontSize: 14, fontWeight: 600}}>
          Sign out
        </button>
      </div>
      <TabBar active="me"/>
    </div>
  );
};

Object.assign(window, { WorkoutsListScreen, ActiveWorkoutScreen, FeedScreen, FeedPostScreen, OnboardingScreen, SettingsScreen });
