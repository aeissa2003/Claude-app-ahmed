// Log meal sheet + Recipe editor

const LogMealSheet = ({ onClose, onLog }) => {
  const [tab, setTab] = useState('recipe');
  const [servings, setServings] = useState(1);
  const [mealType, setMealType] = useState('Lunch');
  return (
    <div className="pc-screen" style={{background: 'rgba(10,11,20,0.5)'}}>
      <div style={{flex: 1}} onClick={onClose}/>
      <div style={{
        background: 'var(--paper)',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '12px 20px 28px',
        maxHeight: '82%',
        display:'flex', flexDirection:'column'
      }}>
        <div style={{width: 40, height: 4, background: 'var(--line-2)', borderRadius: 999, margin: '4px auto 14px'}}/>

        <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: 14}}>
          <div className="t-display" style={{fontSize: 24}}>Log a meal</div>
          <button onClick={onClose} className="pc-icon-btn"><Icon name="close" size={18}/></button>
        </div>

        {/* Tab picker */}
        <div className="pc-seg" style={{width:'100%', justifyContent:'space-between', marginBottom: 16}}>
          {[['recipe','Saved recipe'],['quick','Quick add'],['scan','Scan']].map(([id,l]) => (
            <button key={id} onClick={() => setTab(id)}
              className={`pc-seg__btn ${tab===id?'pc-seg__btn--active':''}`}
              style={{flex: 1}}>{l}</button>
          ))}
        </div>

        {tab === 'recipe' && (
          <div style={{overflow:'auto'}}>
            <div className="pc-card" style={{padding: 16, display:'flex', gap: 14, alignItems:'center', marginBottom: 12}}>
              <Placeholder label="salmon" h={64} rounded={12} style={{width: 64}}/>
              <div style={{flex:1}}>
                <div style={{fontWeight: 600, fontSize: 15}}>Miso salmon bowl</div>
                <div className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)', marginTop: 4}}>42g P · 520 kcal / serving</div>
              </div>
              <button className="pc-icon-btn"><Icon name="edit" size={16}/></button>
            </div>

            <div className="pc-card" style={{padding: 18}}>
              <div className="t-label">Servings</div>
              <div style={{display:'flex', alignItems:'center', gap: 14, marginTop: 10}}>
                <button onClick={() => setServings(Math.max(0.5, servings - 0.5))} className="pc-icon-btn"><Icon name="minus" size={18}/></button>
                <div style={{flex: 1, textAlign: 'center'}}>
                  <span className="t-num" style={{fontSize: 56}}>{servings}</span>
                </div>
                <button onClick={() => setServings(servings + 0.5)} className="pc-icon-btn pc-icon-btn--ink"><Icon name="plus" size={18}/></button>
              </div>
              <div style={{display:'flex', gap: 6, marginTop: 14, justifyContent:'center'}}>
                {[0.5, 1, 1.5, 2].map(v => (
                  <button key={v} onClick={() => setServings(v)}
                    className={`pc-chip ${servings===v?'pc-chip--active':''}`}>{v}×</button>
                ))}
              </div>
            </div>

            <div className="pc-card" style={{padding: 18, marginTop: 12}}>
              <div className="t-label" style={{marginBottom: 10}}>Meal</div>
              <div style={{display:'flex', gap: 6, flexWrap:'wrap'}}>
                {['Breakfast','Lunch','Dinner','Snacks'].map(m => (
                  <button key={m} onClick={() => setMealType(m)}
                    className={`pc-chip ${mealType===m?'pc-chip--active':''}`}>{m}</button>
                ))}
              </div>
            </div>

            <div className="pc-card pc-card--ink" style={{padding: 16, marginTop: 14, display:'flex', alignItems:'center', justifyContent:'space-between'}}>
              <div>
                <div className="t-eyebrow" style={{color:'rgba(255,255,255,0.55)'}}>Will add</div>
                <div style={{display:'flex', alignItems:'baseline', gap: 8, marginTop: 4}}>
                  <span className="t-num" style={{fontSize: 36, color: 'var(--lime)'}}>+{Math.round(42 * servings)}</span>
                  <span className="t-mono" style={{fontSize: 12, color: 'rgba(255,255,255,0.7)'}}>g protein</span>
                </div>
              </div>
              <div style={{textAlign:'right'}}>
                <div className="t-num" style={{fontSize: 22}}>{Math.round(520 * servings)}</div>
                <div className="t-mono" style={{fontSize: 10, color: 'rgba(255,255,255,0.55)'}}>kcal</div>
              </div>
            </div>

            <button onClick={onLog} className="pc-btn pc-btn--block pc-btn--indigo" style={{marginTop: 14}}>
              Log to {mealType}
            </button>
          </div>
        )}

        {tab === 'quick' && (
          <div>
            <div className="pc-card" style={{padding: 14, display:'flex', alignItems:'center', gap: 10, marginBottom: 10}}>
              <Icon name="search" size={18} color="var(--ink-3)"/>
              <input placeholder="Search ingredients…" style={{border:'none', outline:'none', flex: 1, fontSize: 15, background: 'transparent'}}/>
            </div>
            {['Chicken breast (raw)', 'Greek yogurt (nonfat)', 'Whey protein', 'Egg, whole'].map((n,i)=>(
              <div key={n} className="pc-row" style={{padding: '14px 4px'}}>
                <div style={{flex:1}}>
                  <div style={{fontSize: 14}}>{n}</div>
                  <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)', marginTop: 2}}>{[31,10,80,13][i]}g P / 100g</div>
                </div>
                <button className="pc-icon-btn pc-icon-btn--ink"><Icon name="plus" size={16}/></button>
              </div>
            ))}
          </div>
        )}

        {tab === 'scan' && (
          <div style={{textAlign:'center', padding: '40px 20px'}}>
            <div style={{
              width: 120, height: 120, borderRadius: 28, margin:'0 auto 16px',
              background: 'var(--ink)', color:'var(--lime)',
              display:'flex', alignItems:'center', justifyContent:'center',
            }}>
              <Icon name="camera" size={48}/>
            </div>
            <div className="t-display" style={{fontSize: 20}}>Snap your plate</div>
            <div style={{fontSize: 13, color:'var(--ink-3)', marginTop: 8, maxWidth: 260, marginLeft:'auto', marginRight:'auto'}}>
              Point the camera at your food. We'll estimate the macros and you confirm.
            </div>
            <button className="pc-btn pc-btn--indigo" style={{marginTop: 20}}>Open camera</button>
          </div>
        )}
      </div>
    </div>
  );
};

const RecipeEditorScreen = ({ onBack, onSave }) => {
  return (
    <div className="pc-screen">
      <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', padding: '4px 16px 12px'}}>
        <button onClick={onBack} className="pc-icon-btn"><Icon name="close" size={20}/></button>
        <span className="t-mono" style={{fontSize: 11, color:'var(--ink-3)', letterSpacing: '0.1em'}}>NEW RECIPE</span>
        <button onClick={onSave} className="pc-btn pc-btn--sm pc-btn--indigo">Save</button>
      </div>

      <div className="pc-scroll" style={{padding: '0 16px 20px'}}>
        <button className="pc-placeholder" style={{
          width:'100%', height: 180, borderRadius: 20, border: '1.5px dashed var(--line-2)', background:'transparent',
          display:'flex', flexDirection:'column', gap: 6
        }}>
          <Icon name="camera" size={28} color="var(--ink-3)"/>
          <span style={{position:'relative', zIndex: 1}}>Add cover photo</span>
        </button>

        <div style={{marginTop: 18}}>
          <input
            placeholder="Recipe name"
            className="t-display"
            style={{
              width:'100%', fontSize: 28, border:'none', outline:'none',
              padding: '8px 0', background: 'transparent',
              borderBottom: '1px solid var(--line)',
            }}
            defaultValue="Miso salmon bowl"
          />
        </div>

        {/* Quick inputs */}
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap: 8, marginTop: 16}}>
          {[
            { l:'servings', v:'2', ico:'users' },
            { l:'prep', v:'10m', ico:'clock' },
            { l:'cook', v:'15m', ico:'flame' },
          ].map(f => (
            <div key={f.l} className="pc-card" style={{padding: 12}}>
              <div style={{display:'flex', alignItems:'center', gap: 6}}>
                <Icon name={f.ico} size={12} color="var(--ink-3)"/>
                <span className="t-label">{f.l}</span>
              </div>
              <div className="t-num" style={{fontSize: 22, marginTop: 4}}>{f.v}</div>
            </div>
          ))}
        </div>

        {/* Ingredients section */}
        <div style={{marginTop: 24}}>
          <div style={{display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom: 10}}>
            <div className="t-display" style={{fontSize: 20}}>Ingredients</div>
            <button className="pc-chip"><Icon name="plus" size={12}/> Add</button>
          </div>
          <div className="pc-card" style={{padding: '4px 16px'}}>
            {[
              { n: 'Salmon fillet', q: '340 g', p: 68 },
              { n: 'Brown rice, cooked', q: '200 g', p: 5 },
              { n: 'Edamame', q: '100 g', p: 11 },
              { n: 'Avocado', q: '50 g', p: 1 },
            ].map((it,i) => (
              <div key={i} className="pc-row">
                <div style={{width: 6, height: 32, background: 'var(--line-2)', borderRadius: 999}}/>
                <div style={{flex:1}}>
                  <div style={{fontSize: 14, fontWeight: 500}}>{it.n}</div>
                  <div className="t-mono" style={{fontSize: 10, color:'var(--ink-3)', marginTop: 2}}>{it.q}</div>
                </div>
                <div className="t-num" style={{fontSize: 14, color:'var(--protein)'}}>{it.p}g</div>
                <button><Icon name="close" size={14} color="var(--ink-4)"/></button>
              </div>
            ))}
          </div>
        </div>

        {/* Live macros readout */}
        <div className="pc-card pc-card--ink" style={{padding: 18, marginTop: 16}}>
          <div style={{display:'flex', justifyContent:'space-between', alignItems:'baseline'}}>
            <span className="t-eyebrow" style={{color:'rgba(255,255,255,0.55)'}}>Calculated · per serving</span>
            <span className="pc-chip pc-chip--lime" style={{padding: '2px 7px', fontSize: 9}}>HP</span>
          </div>
          <div style={{display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap: 10, marginTop: 10}}>
            {[
              { l: 'protein', v: 42, c: 'var(--lime)' },
              { l: 'carbs', v: 48, c: '#fff' },
              { l: 'fat', v: 18, c: '#fff' },
              { l: 'kcal', v: 520, c: '#fff' },
            ].map(m => (
              <div key={m.l}>
                <div className="t-num" style={{fontSize: 22, color: m.c}}>{m.v}</div>
                <div className="t-mono" style={{fontSize: 9, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.1em', textTransform: 'uppercase'}}>{m.l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

Object.assign(window, { LogMealSheet, RecipeEditorScreen });
