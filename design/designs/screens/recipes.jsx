// Recipes list, detail, editor screens

const RecipesListScreen = ({ onOpenRecipe, onNew }) => {
  const recipes = [
    { id: 1, title: 'Miso salmon bowl', p: 42, k: 520, time: 25, tags: ['dinner','asian'], hp: true, color: '#E06A4E' },
    { id: 2, title: 'Cottage cheese flatbread', p: 38, k: 410, time: 15, tags: ['breakfast','snack'], hp: true, color: '#E5A823' },
    { id: 3, title: 'Turkey chili (batch)', p: 46, k: 560, time: 45, tags: ['batch','dinner'], hp: true, color: '#9A3B1A' },
    { id: 4, title: 'Greek yogurt bowl', p: 32, k: 380, time: 5, tags: ['breakfast'], hp: true, color: '#D6D0BE' },
    { id: 5, title: 'Steak fajitas', p: 38, k: 490, time: 20, tags: ['dinner'], hp: true, color: '#5A2A1A' },
    { id: 6, title: 'Chickpea pasta', p: 28, k: 460, time: 20, tags: ['lunch','vegetarian'], hp: false, color: '#C8AE6A' },
  ];
  const [filter, setFilter] = useState('all');

  return (
    <div className="pc-screen">
      <AppBar
        eyebrow="Kitchen · 6 saved"
        title="Recipes"
        right={
          <>
            <button className="pc-icon-btn" aria-label="Search"><Icon name="search" size={18}/></button>
            <button className="pc-icon-btn pc-icon-btn--ink" onClick={onNew}><Icon name="plus" size={20}/></button>
          </>
        }
      />

      <div style={{padding: '0 20px 12px', display:'flex', gap: 6, overflowX:'auto'}}>
        {['all','high protein','breakfast','lunch','dinner','snack','batch'].map(t => (
          <button key={t} onClick={() => setFilter(t)}
            className={`pc-chip ${filter===t?'pc-chip--active':''}`}
            style={{flexShrink: 0, textTransform: 'capitalize'}}>{t}</button>
        ))}
      </div>

      <div className="pc-scroll" style={{padding: '4px 16px 20px'}}>
        {/* Featured big card */}
        <button onClick={onOpenRecipe} className="pc-card" style={{width: '100%', padding: 0, textAlign:'left', overflow:'hidden', marginBottom: 12}}>
          <Placeholder label="hero · miso salmon" h={180} rounded={0} style={{borderLeft:'none',borderRight:'none',borderTop:'none'}}/>
          <div style={{padding: 18}}>
            <div style={{display:'flex', gap: 6, marginBottom: 8}}>
              <span className="pc-chip pc-chip--lime" style={{padding:'3px 8px', fontSize: 10}}>high protein</span>
              <span className="pc-chip" style={{padding:'3px 8px', fontSize: 10}}>dinner</span>
            </div>
            <div className="t-display" style={{fontSize: 24}}>Miso salmon bowl</div>
            <div style={{display:'flex', gap: 18, marginTop: 12, alignItems:'baseline'}}>
              <div>
                <div className="t-num" style={{fontSize: 28, color: 'var(--protein)'}}>42<span className="t-mono" style={{fontSize: 12, color: 'var(--ink-3)', marginLeft: 2}}>g P</span></div>
                <div className="t-label">per serving</div>
              </div>
              <div style={{width:1, alignSelf:'stretch', background:'var(--line)'}}/>
              <div>
                <div className="t-num" style={{fontSize: 20}}>520<span className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)', marginLeft: 4}}>kcal</span></div>
                <div className="t-label">energy</div>
              </div>
              <div style={{width:1, alignSelf:'stretch', background:'var(--line)'}}/>
              <div>
                <div className="t-num" style={{fontSize: 20}}>25<span className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)', marginLeft: 4}}>min</span></div>
                <div className="t-label">time</div>
              </div>
            </div>
          </div>
        </button>

        {/* Grid */}
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap: 10}}>
          {recipes.slice(1).map(r => (
            <button key={r.id} onClick={onOpenRecipe} className="pc-card" style={{padding: 0, textAlign: 'left', overflow: 'hidden'}}>
              <Placeholder label={r.title.split(' ')[0].toLowerCase()} h={100} rounded={0}/>
              <div style={{padding: 12}}>
                {r.hp && <span className="pc-chip pc-chip--lime" style={{padding:'2px 6px', fontSize: 9, marginBottom: 6}}>HP</span>}
                <div style={{fontSize: 13, fontWeight: 600, lineHeight: 1.2, marginTop: 4}}>{r.title}</div>
                <div className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)', marginTop: 6, letterSpacing: '0.05em'}}>
                  {r.p}g P · {r.time}m
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      <TabBar active="recipes"/>
    </div>
  );
};

const RecipeDetailScreen = ({ onBack, onLog }) => {
  const ingredients = [
    { name: 'Salmon fillet', qty: '340 g', p: 68, k: 707 },
    { name: 'Brown rice, cooked', qty: '200 g', p: 5, k: 224 },
    { name: 'Edamame, shelled', qty: '100 g', p: 11, k: 122 },
    { name: 'Avocado', qty: '50 g', p: 1, k: 80 },
    { name: 'Miso paste', qty: '20 g', p: 2, k: 40 },
    { name: 'Sesame oil', qty: '5 g', p: 0, k: 44 },
  ];
  return (
    <div className="pc-screen">
      <div style={{position:'relative'}}>
        <Placeholder label="miso salmon · cover" h={280} rounded={0}/>
        <button onClick={onBack} className="pc-icon-btn" style={{position:'absolute', top: 12, left: 20}}>
          <Icon name="chevronLeft" size={20}/>
        </button>
        <div style={{position:'absolute', top: 12, right: 20, display:'flex', gap: 8}}>
          <button className="pc-icon-btn"><Icon name="bookmark" size={18}/></button>
          <button className="pc-icon-btn"><Icon name="share" size={18}/></button>
        </div>
      </div>

      <div className="pc-scroll" style={{padding: '20px 20px 20px'}}>
        <div style={{display:'flex', gap: 6, marginBottom: 10}}>
          <span className="pc-chip pc-chip--lime" style={{padding:'3px 8px', fontSize: 10}}>high protein</span>
          <span className="pc-chip" style={{padding:'3px 8px', fontSize: 10}}>dinner</span>
          <span className="pc-chip" style={{padding:'3px 8px', fontSize: 10}}>asian</span>
        </div>
        <div className="t-display" style={{fontSize: 30, lineHeight: 1}}>Miso salmon bowl</div>
        <div className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)', marginTop: 8, letterSpacing: '0.06em'}}>
          YOUR RECIPE · UPDATED 2 DAYS AGO
        </div>

        {/* Macro strip */}
        <div className="pc-card" style={{padding: 18, marginTop: 18}}>
          <div style={{display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom: 12}}>
            <span className="t-label">Per serving</span>
            <div className="pc-seg">
              <span className="pc-seg__btn pc-seg__btn--active">1×</span>
              <span className="pc-seg__btn">2×</span>
              <span className="pc-seg__btn">4×</span>
            </div>
          </div>
          <div style={{display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap: 10}}>
            {[
              { l: 'protein', v: 42, u: 'g', c: 'var(--protein)' },
              { l: 'carbs', v: 48, u: 'g', c: 'var(--carbs)' },
              { l: 'fat', v: 18, u: 'g', c: 'var(--fat)' },
              { l: 'kcal', v: 520, u: '', c: 'var(--ink)' },
            ].map(m => (
              <div key={m.l}>
                <div className="t-num" style={{fontSize: 22, color: m.c}}>{m.v}</div>
                <div className="t-label" style={{marginTop: 2}}>{m.l} {m.u && <span style={{opacity:.5}}>{m.u}</span>}</div>
              </div>
            ))}
          </div>
          <div style={{display:'flex', gap: 16, marginTop: 14, paddingTop: 14, borderTop:'1px solid var(--line)'}}>
            <div style={{display:'flex', gap: 6, alignItems:'center'}}>
              <Icon name="clock" size={14} color="var(--ink-3)"/>
              <span className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)'}}>25 min</span>
            </div>
            <div style={{display:'flex', gap: 6, alignItems:'center'}}>
              <Icon name="users" size={14} color="var(--ink-3)"/>
              <span className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)'}}>2 servings</span>
            </div>
            <div style={{display:'flex', gap: 6, alignItems:'center'}}>
              <Icon name="flame" size={14} color="var(--ink-3)"/>
              <span className="t-mono" style={{fontSize: 11, color: 'var(--ink-3)'}}>medium</span>
            </div>
          </div>
        </div>

        {/* Ingredients */}
        <div style={{marginTop: 24}}>
          <div className="t-display" style={{fontSize: 22, marginBottom: 12}}>Ingredients</div>
          <div className="pc-card" style={{padding: '4px 18px'}}>
            {ingredients.map((it, i) => (
              <div key={i} className="pc-row">
                <div style={{
                  width: 28, height: 28, borderRadius: 8,
                  background: 'rgba(27,166,106,0.12)', color: 'var(--protein)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'var(--font-mono)', fontSize: 11, fontWeight: 600,
                }}>{i+1}</div>
                <div style={{flex: 1}}>
                  <div style={{fontSize: 14, fontWeight: 500}}>{it.name}</div>
                  <div className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)', marginTop: 2}}>{it.qty}</div>
                </div>
                <div style={{textAlign:'right'}}>
                  <div className="t-num" style={{fontSize: 14, color: 'var(--protein)'}}>{it.p}g</div>
                  <div className="t-mono" style={{fontSize: 10, color: 'var(--ink-3)'}}>{it.k} kcal</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Steps */}
        <div style={{marginTop: 24}}>
          <div className="t-display" style={{fontSize: 22, marginBottom: 12}}>Method</div>
          <div style={{display:'flex', flexDirection:'column', gap: 12}}>
            {[
              'Heat oven to 400°F. Whisk miso, soy, mirin, and honey into a glaze.',
              'Brush salmon with glaze; roast 12–14 min until flaky.',
              'Meanwhile warm rice and steam edamame 3 min.',
              'Build bowls: rice, salmon, edamame, sliced avocado. Drizzle sesame oil.',
            ].map((s, i) => (
              <div key={i} className="pc-card" style={{padding: 14, display:'flex', gap: 12}}>
                <div className="t-num" style={{fontSize: 22, color: 'var(--indigo)', lineHeight: 1}}>{String(i+1).padStart(2,'0')}</div>
                <div style={{fontSize: 14, lineHeight: 1.5, paddingTop: 2}}>{s}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{height: 90}}/>
      </div>

      {/* Sticky log button */}
      <div style={{
        position:'absolute', bottom: 16, left: 16, right: 16, zIndex: 3,
        display:'flex', gap: 10,
      }}>
        <button className="pc-btn pc-btn--ghost" style={{flex: 0, padding: '14px 18px', background:'var(--paper)'}}>
          <Icon name="edit" size={16}/>
        </button>
        <button onClick={onLog} className="pc-btn pc-btn--indigo" style={{flex: 1}}>
          Log this meal · +42g P
        </button>
      </div>
    </div>
  );
};

Object.assign(window, { RecipesListScreen, RecipeDetailScreen });
