/* ============================================================
   auth.js – Role-based auth helpers
   ============================================================ */

function getCurrentUser() {
  try {
    return JSON.parse(localStorage.getItem('user') || 'null');
  } catch {
    return null;
  }
}

function getUserRole() {
  const user = getCurrentUser();
  return user?.role || null;
}

function isAdmin() {
  const role = getUserRole();
  return role === 'Admin' || role === 'SuperAdmin';
}

function isMember() {
  return getUserRole() === 'Member';
}

function isTrainer() {
  return getUserRole() === 'Trainer';
}

function requireAdmin() {
  if (!isAdmin()) {
    alert('Không có quyền truy cập. Chức năng chỉ dành cho quản trị viên.');
    window.location.href = '/index.html';
  }
}

function requireAuth() {
  if (!localStorage.getItem('accessToken')) {
    window.location.href = '/login.html';
  }
}
