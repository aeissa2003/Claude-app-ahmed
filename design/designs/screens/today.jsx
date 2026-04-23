// Today / Dashboard screen

const TodayScreen = ({ onOpenLog, onOpenSuggestion }) => {
  const consumed = { protein: 128, carbs: 178, fat: 52, kcal: 1654 };
  const goal = { protein: 200, carbs: 260, fat: 70, kcal: 2400 };

  const meals = [
    { type: 'Breakfast', items: [
      { name: 'Greek yogurt bowl', detail: '1 serving · oats, blueberries', p: 32, k: 380 },
      { name: '2 whole eggs', detail: '100 g', p: 13, k: 155 },
    ]},
    { type: 'Lunch', items: [
      { name: 'Chicken rice bowl', detail: '1.5 servings', p: 54, k: 620 },
    ]},
    { type: 'Dinner', items: [] },
    { type: 'Snacks', items: [
      { name: 'Whey shake', detail: '1 scoop', p: 24, k: 120 },
    ]},
  ];

  const suggestions = [
    { title: 'Cottage cheese flatbread', serv: 1, p: 38, k: 410, tag: 'high protein' },
    { title: 'Miso salmon + greens', serv: 1, p: 42, k: 520, tag: 'hits target' },
    { title: 'Turkey chili', serv: 1.5, p: 46, k: 560, tag: 'batch' },
  ];

  return (
    <div className="pc-screen">
      <AppBar
        eyebrow="Fri · Apr 24"
        title="Today"
        right={
          <>
            <button className="pc-icon-btn" aria-label="Notifications"><Icon name="bell" size={18}/></button>
            <button className="pc-icon-btn pc-icon-btn--ink" aria-label="Log food" onClick={onOpenLog}><Icon name="plus" size={20}/></button>
          </>
        }
      />

      <div className="pc-scroll" style={{paddingBottom: 24}}>
        {/* Hero card: big protein number + bars */}
        <div style={{padding: '0 16px'}}>
          <div className="pc-card pc-card--ink" style={{padding: 22, position: 'relative', overflow: 'hidden'}}>
            <div style={{display:'flex', alignItems:'flex-start', justifyContent:'space-between'}}>
              <div>
                <div className="t-eyebrow" style={{color: 'rgba(255,255,255,0.55)'}}>Protein left</div>
                <div style={{display:'flex', alignItems:'baseline', gap: 10, marginTop: 6}}>
                  <span className="t-display" style={{fontSize: 80, lineHeight: 0.9, color: 'var(--lime)'}}>
                    {goal.protein - consumed.protein}
                  </span>
                  <span className="t-mono" style={{fontSize: 14, color: 'rgba(255,255,255,0.7)'}}>g</span>
                </div>
                <div className="t-mono" style={{fontSize: 11, color: 'rgba(255,255,255,0.55)', marginTop: 6, letterSpacing: '0.08em'}}>
                  {consumed.protein} of {goal.protein}g logged · {Math.round((consumed.protein/goal.protein)*100)}%
                </div>
              </div>
              <div style={{
                padding: '6px 10px', borderRadius: 999,
                background: 'rgba(212,255,58,0.14)', color: 'var(--lime)',
                fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.1em', textTransform: 'uppercase',
                fontWeight: 600,
              }}>On pace</div>
            </div>

            {/* Protein mega-bar */}
            <div style={{marginTop: 20, height: 14, background: 'rgba(255,255,255,0.1)', borderRadius: 999, position: 'relative', overflow: 'hidden'}}>
              <div style={{position:'absolute', inset: 0, width: `${(consumed.protein/goal.protein)*100}%`, background: 'var(--lime)', borderRadius: 999}}/>
            </div>
            <div style={{display:'flex', justifyContent:'space-between', marginTop: 10}}>
              <span className="t-mono" style={{fontSize: 10, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.08em'}}>0</span>
              <span className="t-mono" style={{fontSize: 10, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.08em'}}>{goal.protein}g goal</span>
            </div>
          </div>
        </div>

        {/* Other macros */}
        <div style={{padding: '16px'}}>
          <div className="pc-card" style={{padding: 20, display: 'flex', flexDirection: 'column', gap: 18}}>
            <MacroBar label="Calories" unit="kcal" current={consumed.kcal} goal={goal.kcal} color="var(--ink)"/>
            <MacroBar label="Carbs" current={consumed.carbs} goal={goal.carbs} color="var(--carbs)"/>
            <MacroBar label="Fat" current={consumed.fat} goal={goal.fat} color="var(--fat)"/>
          </div>
        </div>

        {/* Meals */}
        <div style={{padding: '0 16px', marginTop: 8}}>
          <div style={{display:'flex', alignItems:'baseline', justifyContent:'space-between', padding: '0 4px 12px'}}>
            <div className="t-display" style={{fontSize: 22}}>Meals</div>
            <span className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)', letterSpacing: '0.1em'}}>4 LOGGED</span>
          </div>
          <div style={{display:'flex', flexDirection:'column', gap: 10}}>
            {meals.map(m => {
              const total = m.items.reduce((a,b)=>({p:a.p+b.p, k:a.k+b.k}),{p:0,k:0});
              return (
                <div key={m.type} className="pc-card" style={{padding: 16}}>
                  <div style={{display:'flex', alignItems:'center', justifyContent:'space-between'}}>
                    <div style={{display:'flex', alignItems:'baseline', gap: 10}}>
                      <span className="t-display" style={{fontSize: 18}}>{m.type}</span>
                      {m.items.length === 0 && <span className="t-mono" style={{fontSize: 10, color: 'var(--ink-4)', letterSpacing: '0.08em'}}>EMPTY</span>}
                    </div>
                    {m.items.length > 0
                      ? <span className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)'}}>{total.p}g · {total.k} kcal</span>
                      : <button className="pc-chip"><Icon name="plus" size={12}/> Add</button>}
                  </div>
                  {m.items.length > 0 && (
                    <div style={{marginTop: 10}}>
                      {m.items.map((it, i) => (
                        <div key={i} className="pc-row" style={{padding: '10px 0'}}>
                          <div style={{flex: 1}}>
                            <div style={{fontSize: 14, fontWeight: 500}}>{it.name}</div>
                            <div className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)', marginTop: 2, letterSpacing: '0.05em'}}>{it.detail}</div>
                          </div>
                          <div style={{textAlign:'right'}}>
                            <div className="t-num" style={{fontSize: 16, color: 'var(--protein)'}}>{it.p}<span style={{fontSize: 10, fontFamily: 'var(--font-mono)', color: 'var(--ink-3)', marginLeft: 2}}>g P</span></div>
                            <div className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)'}}>{it.k} kcal</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Suggestions */}
        <div style={{padding: '24px 16px 16px'}}>
          <div style={{display:'flex', alignItems:'baseline', justifyContent:'space-between', padding: '0 4px 12px'}}>
            <div>
              <div className="t-display" style={{fontSize: 22}}>Hit your target</div>
              <div className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)', marginTop: 4, letterSpacing: '0.05em'}}>recipes tuned to your remaining 72g</div>
            </div>
          </div>
          <div style={{display:'flex', gap: 12, overflowX:'auto', padding: '4px 4px 4px'}}>
            {suggestions.map((s, i) => (
              <button key={i} onClick={onOpenSuggestion} className="pc-card" style={{
                minWidth: 200, padding: 14, textAlign: 'left', display:'flex', flexDirection:'column', gap: 10, flexShrink: 0
              }}>
                <Placeholder label="plate" h={100} rounded={12}/>
                <div>
                  <div style={{display:'flex', gap: 4, flexWrap:'wrap', marginBottom: 6}}>
                    <span className="pc-chip pc-chip--lime" style={{padding:'3px 8px', fontSize: 10}}>{s.tag}</span>
                  </div>
                  <div style={{fontSize: 14, fontWeight: 600, lineHeight: 1.2}}>{s.title}</div>
                  <div className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)', marginTop: 6, letterSpacing: '0.05em'}}>
                    {s.p}g P · {s.k} kcal · {s.serv} serv
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>

      <TabBar active="today"/>
    </div>
  );
};

Object.assign(window, { TodayScreen });
