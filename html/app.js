const app=document.getElementById('app'),content=document.getElementById('content'),subtitle=document.getElementById('subtitle');
const post=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
document.getElementById('close').onclick=()=>{app.classList.add('hidden');post('close')};
window.addEventListener('keydown',e=>{if(e.key==='Escape')document.getElementById('close').click()});
const money=n=>'$'+Number(n||0).toLocaleString(undefined,{minimumFractionDigits:2,maximumFractionDigits:2});
function accountHTML(a){let bad=Number(a.missed_payments)>0;return `<div class="card"><h3>${a.card_type.toUpperCase()} <span class="pill">${a.status}</span></h3><div>•••• ${String(a.card_number).slice(-4)} · Limit ${money(a.credit_limit)}</div><div>Balance: <b>${money(a.balance)}</b></div><div>Minimum due: <b>${money(a.minimum_due)}</b></div><div class="${bad?'bad':'good'}">Missed payments: <b>${a.missed_payments}</b></div><div>Due: ${a.due_at||'—'}</div>${a.close_reason?`<div class="bad">${a.close_reason}</div>`:''}${Number(a.balance)>0?`<div style="margin-top:10px"><input id="pay-${a.id}" type="number" min="1" placeholder="Amount"><button onclick="pay(${a.id})">Pay</button></div>`:''}</div>`}
function player(d){subtitle.textContent='Credit & Card Center';let cards=Object.entries(d.cards).map(([k,c])=>`<div class="card"><h3>${c.label}</h3><div>Minimum score: ${c.minScore}</div><div>Limit: ${money(c.limit)}</div><div>APR: ${c.apr}%</div><button style="margin-top:10px" onclick="applyCard('${k}')">Apply</button></div>`).join('');content.innerHTML=`<div class="score">${d.score}</div><div class="muted">Credit score · 300–850</div><h2>Your accounts</h2>${d.accounts.length?d.accounts.map(accountHTML).join(''):'<div class="card muted">No credit accounts yet.</div>'}<h2>Apply for credit</h2><div class="grid">${cards}</div>`}
function admin(d){subtitle.textContent=`Admin Credit Report · ${d.player} · ${d.citizenid}`;let missed=d.accounts.reduce((s,a)=>s+Number(a.missed_payments||0),0);content.innerHTML=`<div class="score">${d.score}</div><div class="${missed?'bad':'good'}">Total recorded missed payments: <b>${missed}</b></div><h2>Accounts / delinquency</h2>${d.accounts.length?d.accounts.map(accountHTML).join(''):'<div class="card muted">No accounts.</div>'}`}
window.applyCard=k=>post('apply',{cardType:k});window.pay=id=>{let v=document.getElementById('pay-'+id).value;post('pay',{accountId:id,amount:v})};
window.addEventListener('message',e=>{if(e.data.action==='open'){app.classList.remove('hidden');player(e.data.data)}if(e.data.action==='admin'){app.classList.remove('hidden');admin(e.data.data)}});


// AGC reusable payment selector (Cash / Debit / Credit)
window.addEventListener('message', (event) => {
  const m = event.data || {};
  if (m.action !== 'payment') return;
  const opts = m.options || {};
  const money = n => '$' + Number(n || 0).toLocaleString(undefined,{minimumFractionDigits:2,maximumFractionDigits:2});
  const cards = (opts.cards || []).filter(c => Number(c.available || 0) >= Number(m.amount || 0));
  document.body.innerHTML = `<div class="wrap"><div class="panel payment-panel">
    <div class="top"><div><h1>Choose Payment Method</h1><div class="muted">${esc(m.description || 'Purchase')}</div></div><button id="payCancel">×</button></div>
    <div class="purchase-total">${money(m.amount)}</div>
    <div class="payment-grid">
      ${opts.allowCash ? `<button class="pay-option" data-method="cash"><b>Cash</b><span>Wallet balance: ${money(opts.cash)}</span><em>${Number(opts.cash||0)>=Number(m.amount||0)?'Available':'Insufficient funds'}</em></button>`:''}
      ${opts.allowDebit ? `<button class="pay-option" data-method="debit"><b>Debit</b><span>Bank balance: ${money(opts.debit)}</span><em>${Number(opts.debit||0)>=Number(m.amount||0)?'Available':'Insufficient funds'}</em></button>`:''}
      ${opts.allowCredit ? (opts.cards||[]).map(c=>`<button class="pay-option" data-method="credit" data-account="${c.id}" ${Number(c.available||0)<Number(m.amount||0)?'disabled':''}><b>${esc(c.label)} •••• ${esc(c.last4)}</b><span>Available credit: ${money(c.available)}</span><em>${Number(c.available||0)>=Number(m.amount||0)?'Charge this card':'Insufficient credit'}</em></button>`).join('') : ''}
    </div>
  </div></div>`;
  document.querySelectorAll('.pay-option').forEach(btn => btn.addEventListener('click', () => {
    if (btn.disabled) return;
    post('choosePayment',{requestId:m.requestId,method:btn.dataset.method,accountId:btn.dataset.account||null});
  }));
  document.getElementById('payCancel').addEventListener('click',()=>post('cancelPayment',{requestId:m.requestId}));
});
