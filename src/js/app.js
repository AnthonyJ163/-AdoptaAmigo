/* AdaptaAmigo - lógica compartida entre todas las páginas
   Los datos se guardan en localStorage para persistir al cambiar de página. */

const DEFAULT_PETS = [
  { id: 1, nombre: "Max", especie: "Perro", edad: "3 años", ubicacion: "Lima", img: "https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=500&q=80", desc: "Max es un perro alegre, juguetón y muy cariñoso con los niños. Le encanta correr en parques y convive sin problemas con otros animales." },
  { id: 2, nombre: "Luna", especie: "Gato", edad: "1 año", ubicacion: "Miraflores", img: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=500&q=80", desc: "Luna es muy mansa, aseada y dócil. Le encanta tomar sol y recibir cariños." },
  { id: 3, nombre: "Rocky", especie: "Perro", edad: "2 años", ubicacion: "Surco", img: "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=500&q=80", desc: "Rocky tiene mucha energía, ideal para personas deportistas o familias con jardín." },
  { id: 4, nombre: "Nina", especie: "Gato", edad: "6 meses", ubicacion: "San Isidro", img: "https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=500&q=80", desc: "Mascota pequeña rescatada, vacunada y lista para formar parte de tu hogar." }
];

/* ---------- Almacenamiento ---------- */
function load(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch (e) { return fallback; }
}
function save(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) {}
}

function getUser() { return load('aa_user', null); }

/* Mascotas: las de ejemplo las ve todo el mundo; las que publica un usuario
   solo aparecen cuando ese usuario tiene la sesión iniciada. */
function getAllPets() { return load('aa_pets', DEFAULT_PETS); }
function savePets(p) { save('aa_pets', p); }
function getPets() {
  const u = getUser();
  return getAllPets().filter(p => !p.owner || (u && p.owner === u.email));
}
function getMyPublishedPets() {
  const u = getUser();
  return u ? getAllPets().filter(p => p.owner === u.email) : [];
}

/* Solicitudes: cada una guarda el correo de su dueño. */
function getApps() { return load('aa_apps', []); }
function saveApps(a) { save('aa_apps', a); }
function getMyApps() {
  const u = getUser();
  return u ? getApps().filter(a => a.owner === u.email) : [];
}

/* Páginas que exigen sesión iniciada */
function requireLogin() {
  if (!getUser()) {
    const here = window.location.pathname.split('/').pop() + window.location.search;
    window.location.href = 'login.html?next=' + encodeURIComponent(here);
    return false;
  }
  return true;
}

/* Después de iniciar sesión / registrarse: vuelve a la página que se quería abrir */
function nextPage() {
  const next = new URLSearchParams(window.location.search).get('next');
  return (next && /^[\w-]+\.html(\?[\w=&-]*)?$/.test(next)) ? next : 'catalogo.html';
}
function setUser(u) { save('aa_user', u); }

function logout() {
  localStorage.removeItem('aa_user');
  window.location.href = 'index.html';
}

/* ---------- Header y footer ---------- */
function navLink(href, label, active) {
  const cls = active === href ? 'text-emerald-600' : 'hover:text-emerald-600';
  return `<a href="${href}" class="${cls} transition">${label}</a>`;
}

function renderHeader(active) {
  const user = getUser();
  const auth = user
    ? `<div class="flex items-center space-x-3">
         <div class="flex items-center space-x-2 bg-emerald-50 px-3 py-1.5 rounded-full border border-emerald-200">
           <span class="text-xs">👤</span>
           <span class="text-xs font-bold text-emerald-800">${user.name}</span>
         </div>
         <button onclick="logout()" class="text-xs text-red-500 hover:underline font-semibold">Salir</button>
       </div>`
    : `<div class="flex items-center space-x-3">
         <a href="login.html" class="text-emerald-600 font-semibold px-3 py-2 hover:bg-emerald-50 rounded-lg text-sm transition">Iniciar sesión</a>
         <a href="registro.html" class="bg-emerald-600 text-white font-semibold px-4 py-2 rounded-lg text-sm shadow hover:bg-emerald-700 transition">Regístrate</a>
       </div>`;

  document.getElementById('app-header').innerHTML = `
    <header class="bg-white shadow-sm sticky top-0 z-50 border-b border-gray-100">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 h-20 flex items-center justify-between">
        <a href="index.html" class="text-2xl font-bold text-emerald-600">🐾 AdaptaAmigo</a>
        <nav class="hidden md:flex space-x-6 font-medium text-gray-600">
          ${navLink('index.html', 'Inicio', active)}
          ${navLink('catalogo.html', 'Animales', active)}
          ${navLink('mis-solicitudes.html', 'Mis Solicitudes', active)}
          ${navLink('panel-refugio.html', 'Panel Refugio', active)}
        </nav>
        ${auth}
      </div>
    </header>`;
}

function renderFooter() {
  document.getElementById('app-footer').innerHTML = `
    <footer class="bg-white border-t border-gray-100 py-6 text-center text-xs text-gray-500 mt-auto">
      <p>© 2026 AdaptaAmigo - Plataforma de Adopción Responsable</p>
    </footer>`;
}

function initLayout(active) {
  renderHeader(active);
  renderFooter();
}

function getQueryId() {
  return parseInt(new URLSearchParams(window.location.search).get('id'), 10);
}


/* ---------- Cuentas (demo, guardadas en localStorage) ---------- */
function getUsers() { return load('aa_users', []); }
function saveUsers(u) { save('aa_users', u); }

function registerUser(name, email, password) {
  email = email.trim().toLowerCase();
  const users = getUsers();
  if (users.some(u => u.email === email)) {
    return { ok: false, msg: 'Ya existe una cuenta con ese correo. Inicia sesión.' };
  }
  users.push({ name: name.trim(), email: email, password: password });
  saveUsers(users);
  setUser({ name: name.trim(), email: email });
  if (!getUser()) return { ok: false, msg: 'Tu navegador bloquea el almacenamiento local. Abre la página en Chrome/Edge o permite los datos del sitio.' };
  return { ok: true };
}

function loginUser(email, password) {
  email = email.trim().toLowerCase();
  const user = getUsers().find(u => u.email === email);
  if (!user) return { ok: false, msg: 'No existe una cuenta con ese correo. Regístrate primero.' };
  if (user.password !== password) return { ok: false, msg: 'Contraseña incorrecta.' };
  setUser({ name: user.name, email: user.email });
  if (!getUser()) return { ok: false, msg: 'Tu navegador bloquea el almacenamiento local. Abre la página en Chrome/Edge o permite los datos del sitio.' };
  return { ok: true };
}

function showFormError(msg) {
  const el = document.getElementById('form-error');
  el.textContent = msg;
  el.classList.remove('hidden');
}
