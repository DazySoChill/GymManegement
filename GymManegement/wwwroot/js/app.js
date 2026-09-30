/* ============================================================
   app.js – Core UI: routing, toast, modal utilities
   ============================================================ */

// ── Toast ─────────────────────────────────────────────────────
function toast(msg, type = 'info', duration = 3000) {
  const container = document.getElementById('toast-container');
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.textContent = msg;
  container.appendChild(el);
  setTimeout(() => el.remove(), duration);
}

// ── Modal helpers ─────────────────────────────────────────────
function openModal(id) {
  document.getElementById(id).classList.add('open');
}
function closeModal(id) {
  document.getElementById(id).classList.remove('open');
}

// ── Router ────────────────────────────────────────────────────
function navigateTo(pageId) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('#sidebar nav a').forEach(a => {
    a.classList.toggle('active', a.dataset.page === pageId);
  });
  const page = document.getElementById(`page-${pageId}`);
  if (page) {
    page.classList.add('active');
    document.getElementById('topbar-title').textContent =
      document.querySelector(`[data-page="${pageId}"]`)?.textContent.trim() || '';
    // Run page initializer
    const init = window[`init_${pageId}`];
    if (typeof init === 'function') init();
  }
}

// ── Table helpers ─────────────────────────────────────────────
function loading(containerId) {
  document.getElementById(containerId).innerHTML =
    `<tr><td colspan="20" class="loading"><span class="spinner"></span></td></tr>`;
}

function emptyRow(containerId, cols, msg = 'Không có dữ liệu') {
  document.getElementById(containerId).innerHTML =
    `<tr><td colspan="${cols}" style="text-align:center;padding:40px;color:var(--muted)">${msg}</td></tr>`;
}

function dateFmt(d) {
  if (!d) return '';
  return new Date(d).toLocaleDateString('vi-VN');
}

function datetimeFmt(d) {
  if (!d) return '';
  return new Date(d).toLocaleString('vi-VN');
}

function moneyFmt(n) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(n);
}

function badge(text, cls) {
  return `<span class="badge badge-${cls}">${text}</span>`;
}

function statusBadge(status) {
  const map = {
    Active:    ['Active','green'],    Inactive:['Inactive','gray'],  Suspended: ['Suspended','red'],
    Pending:   ['Chờ TT','yellow'],   Paid:    ['Đã TT','green'],    Overdue:   ['Quá hạn','red'],
    Cancelled: ['Huỷ','gray'],
    Scheduled: ['Đã lên lịch','blue'],Completed:['Hoàn thành','green'],
    Completed2:['Hoàn thành','green'],Failed:  ['Thất bại','red'],   Refunded:  ['Hoàn tiền','yellow'],
  };
  const [label, cls] = map[status] || [status, 'gray'];
  return badge(label, cls);
}

// ── Sidebar toggle (mobile) ───────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  // Sidebar links
  document.querySelectorAll('#sidebar nav a').forEach(link => {
    link.addEventListener('click', e => {
      e.preventDefault();
      navigateTo(link.dataset.page);
    });
  });

  // Default page
  navigateTo('dashboard');

  // Close modals on backdrop click
  document.querySelectorAll('.modal-backdrop').forEach(bd => {
    bd.addEventListener('click', e => {
      if (e.target === bd) bd.classList.remove('open');
    });
  });
});
