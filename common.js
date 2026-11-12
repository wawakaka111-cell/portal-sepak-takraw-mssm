const ready = window.SUPABASE_URL && !window.SUPABASE_URL.includes("PASTE_") &&
              window.SUPABASE_ANON_KEY && !window.SUPABASE_ANON_KEY.includes("PASTE_");
const db = ready ? window.supabase.createClient(window.SUPABASE_URL, window.SUPABASE_ANON_KEY) : null;
const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function configWarning(){return `<div class="notice">Sambungan database belum disediakan. Isi URL dan anon/publishable key dalam <b>supabase-config.js</b> selepas menyediakan projek Supabase.</div>`;}
async function getActiveSeason(){
  if(!db) return null;
  const {data} = await db.from('seasons').select('*').order('year',{ascending:false});
  return data?.find(x=>x.is_active) || data?.[0] || null;
}
