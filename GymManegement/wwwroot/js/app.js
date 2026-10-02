/* ============================================================
   app.js – Core UI: routing, toast, modal utilities, auth
   ============================================================ */

// ── Auth ────────────────────────────────────────────────────────
function getCurrentUser() {
  try { return JSON.parse(localStorage.getItem('user') || 'null'); } catch { return null; }
}

function isAuthenticated() { return !!localStorage.getItem('accessToken'); }

function logout() {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('user');
  window.location.href = '/login.html';
}

function initAuth() {
  if (window.location.pathname.endsWith('login.html')) {
    if (isAuthenticated()) window.location.href = '/';
    return;
  }
  if (!isAuthenticated()) { window.location.href = '/login.html'; return; }

  const user = getCurrentUser();
  if (user) {
    const topbarRight = document.querySelector('.topbar-right');
    if (topbarRight) {
      // Remove existing user menu if any
      const existing = document.getElementById('userMenu');
      if (existing) existing.remove();

      const userMenu = document.createElement('div');
      userMenu.id = 'userMenu';
      userMenu.className = 'user-menu dropdown';
      userMenu.innerHTML = `
        <div class="avatar" id="userAvatar">${user.username?.charAt(0).toUpperCase() || 'U'}</div>
        <div class="user-info">
          <span class="user-name" id="userName">${user.username}</span>
          <span class="user-role" id="userRole">${user.role}</span>
        </div>
      `;
      topbarRight.prepend(userMenu);

      // Dropdown toggle
      userMenu.addEventListener('click', e => {
        if (e.target.closest('.close-btn')) return;
        userMenu.classList.toggle('open');
      });

      // Add dropdown menu
      const dropdownMenu = document.createElement('div');
      dropdownMenu.className = 'dropdown-menu';
      dropdownMenu.innerHTML = `
        <div class="dropdown-item" onclick="window.location.href='/profile.html'">👤 Hồ sơ</div>
        <div class="dropdown-item" onclick="window.location.href='/settings.html'">⚙️ Cài đặt</div>
        <div class="dropdown-divider"></div>
        <div class="dropdown-item danger" onclick="logout()">🚪 Đăng xuất</div>
      `;
      userMenu.appendChild(dropdownMenu);

      // Close on outside click
      document.addEventListener('click', e => {
        if (!userMenu.contains(e.target)) userMenu.classList.remove('open');
      });
    }
  }
}

// ── Toast ─────────────────────────────────────────────────────
function toast(msg, type = 'info', duration = 3500) {
  const container = document.getElementById('toast-container');
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  const icons = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };
  el.innerHTML = `<span>${icons[type] || ''}</span><span>${msg}</span>`;
  container.appendChild(el);
  setTimeout(() => { el.classList.add('removing'); setTimeout(() => el.remove(), 200); }, duration);
}

// ── Modal helpers ─────────────────────────────────────────────
function openModal(id) { document.getElementById(id)?.classList.add('open'); }
function closeModal(id) { document.getElementById(id)?.classList.remove('open'); }

// ── Router ────────────────────────────────────────────────────
function navigateTo(pageId) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('#sidebar nav a').forEach(a => {
    a.classList.toggle('active', a.dataset.page === pageId);
  });
  const page = document.getElementById(`page-${pageId}`);
  if (page) {
    page.classList.add('active');
    const link = document.querySelector(`[data-page="${pageId}"]`);
    document.getElementById('topbar-title').textContent = link?.textContent?.trim() || '';
    const init = window[`init_${pageId}`];
    if (typeof init === 'function') init();
  }
}

// ── Table helpers ─────────────────────────────────────────────
function loading(containerId) {
  const el = document.getElementById(containerId);
  if (el) el.innerHTML = `<tr><td colspan="20" class="loading"><span class="spinner"></span></tr>`;
}

function emptyRow(containerId, cols, msg = 'Không có dữ liệu') {
  const el = document.getElementById(containerId);
  if (el) el.innerHTML = `<tr><td colspan="${cols}" class="table-empty"><span class="icon">📭</span>${msg}</td></tr>`;
}

function dateFmt(d) { if (!d) return ''; return new Date(d).toLocaleDateString('vi-VN'); }
function datetimeFmt(d) { if (!d) return ''; return new Date(d).toLocaleString('vi-VN'); }
function moneyFmt(n) { return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(n); }

function badge(text, cls) { return `<span class="badge badge-${cls}">${text}</span>`; }

function statusBadge(status) {
  const map = {
    Active: ['Active','green'], Inactive:['Inactive','gray'], Suspended:['Suspended','red'],
    Pending: ['Chờ TT','yellow'], Paid:['Đã TT','green'], Overdue:['Quá hạn','red'],
    Cancelled:['Huỷ','gray'], Scheduled:['Đã lên lịch','blue'], Completed:['Hoàn thành','green'],
    Failed:['Thất bại','red'], Refunded:['Hoàn tiền','yellow'],
  };
  const [label, cls] = map[status] || [status, 'gray'];
  return badge(label, cls);
}

// ── Pagination helper ─────────────────────────────────────────
function renderPagination(containerId, currentPage, totalPages, onPageChange) {
  const el = document.getElementById(containerId);
  if (!el || totalPages <= 1) { if (el) el.innerHTML = ''; return; }

  let html = '';
  html += `<button ${currentPage === 1 ? 'disabled' : ''} onclick="${onPageChange}(${currentPage - 1})" aria-label="Previous">‹</button>`;

  const start = Math.max(1, currentPage - 2);
  const end = Math.min(totalPages, currentPage + 2);

  if (start > 1) { html += `<button onclick="${onPageChange}(1)">1</button>`; if (start > 2) html += `<span class="page-info">…</span>`; }

  for (let i = start; i <= end; i++) {
    html += `<button class="${i === currentPage ? 'active' : ''}" onclick="${onPageChange}(${i})">${i}</button>`;
  }

  if (end < totalPages) { if (end < totalPages - 1) html += `<span class="page-info">…</span>`; html += `<button onclick="${onPageChange}(${totalPages})">${totalPages}</button>`; }

  html += `<button ${currentPage === totalPages ? 'disabled' : ''} onclick="${onPageChange}(${currentPage + 1})" aria-label="Next">›</button>`;
  html += `<span class="page-info">Trang ${currentPage}/${totalPages}</span>`;
  el.innerHTML = html;
}

// ── Select helpers ────────────────────────────────────────────
function populateSelect(selectId, items, valueKey, labelKey, placeholder = '-- Chọn --') {
  const select = document.getElementById(selectId);
  if (!select) return;
  const current = select.value;
  select.innerHTML = `<option value="">${placeholder}</option>` + items.map(i => `<option value="${i[valueKey]}">${i[labelKey]}</option>`).join('');
  if (current) select.value = current;
}

// ── Initialize on DOM ready ───────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  initAuth();

  // Sidebar navigation
  document.querySelectorAll('#sidebar nav a').forEach(link => {
    link.addEventListener('click', e => { e.preventDefault(); navigateTo(link.dataset.page); });
  });

  // Close modals on backdrop click
  document.querySelectorAll('.modal-backdrop').forEach(bd => {
    bd.addEventListener('click', e => { if (e.target === bd) bd.classList.remove('open'); });
  });

  // Keyboard: ESC closes modal
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') document.querySelectorAll('.modal-backdrop.open').forEach(m => m.classList.remove('open'));
  });

  // Default page
  navigateTo('dashboard');
});
