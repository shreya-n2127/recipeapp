// Shared code used by every page.
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Escape text so comments/usernames can never inject HTML (XSS protection)
function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, c =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function thumbUrl(youtubeId) {
  return youtubeId ? `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg` : '';
}

function fmtDate(d) {
  return new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}
function slug(t) { return t.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, ''); }

function thumbHtml(r) {
  const own = `images/${slug(r.title)}.jpg`;
  return `<img class="thumb" loading="lazy" src="${own}" alt="${esc(r.title)}"
               data-yt="${thumbUrl(r.youtube_id)}" onerror="imgFallback(this)">`;
}

// If your own photo is missing, try the YouTube thumbnail, then a plate emoji
function imgFallback(img) {
  if (img.dataset.yt && !img.dataset.tried) { img.dataset.tried = '1'; img.src = img.dataset.yt; }
  else {
    const d = document.createElement('div');
    d.className = 'thumb ph'; d.textContent = '🍽️';
    img.replaceWith(d);
  }
}

// Returns the logged-in user (or null)
async function getUser() {
  const { data } = await sb.auth.getSession();
  return data.session ? data.session.user : null;
}

// Draws the orange header on every page. Returns the user.
async function renderHeader() {
  const user = await getUser();
let right = '<a class="cook-btn" href="match.html">🍳 What can I cook?</a>';
  if (user) {
    const { data } = await sb.from('profiles').select('username').eq('id', user.id).maybeSingle();
    const name = data ? data.username : user.email;
    right += ` <span style="margin-left:14px">Hi, <b>${esc(name)}</b></span><button id="logoutBtn">Logout</button>`;
  } else {
    right += ' <a href="login.html">Login / Register</a>';
  }
   document.getElementById('header').innerHTML =
    `<a class="logo" href="index.html">
       <span class="logo-icon">🍳</span>
       <span><span class="logo-text">Meal<b>Next</b></span><small>Cook what you have</small></span>
     </a><div>${right}</div>`;
  
  const b = document.getElementById('logoutBtn');
  if (b) b.onclick = async () => { await sb.auth.signOut(); location.href = 'index.html'; };
  return user;
}
