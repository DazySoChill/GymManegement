/* ============================================================
   api.js – Trung tâm gọi API backend
   BASE_URL tự động theo origin
   Updated for SQL2 backend compatibility - 2026-10-09
   ============================================================ */

const BASE = window.location.origin;

function getAuthHeaders() {
  const token = localStorage.getItem('accessToken');
  return token ? { 'Authorization': `Bearer ${token}` } : {};
}

async function apiFetch(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...getAuthHeaders(), ...options.headers },
    ...options,
  });
  
  // 401 -> token hết hạn hoặc không hợp lệ -> xóa storage và về login
  if (res.status === 401) {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('user');
    window.location.href = '/login.html';
    throw new Error('Phiên đăng nhập hết hạn');
  }
  
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `HTTP ${res.status}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

// Helper to build query string from pagination/sort/filter params
function buildQuery(params = {}) {
  const searchParams = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      searchParams.append(key, value);
    }
  });
  const qs = searchParams.toString();
  return qs ? `?${qs}` : '';
}

const api = {
  // Members
  getMembers:    (params = {})      => apiFetch(`/api/members${buildQuery(params)}`),
  getMember:     id      => apiFetch(`/api/members/${id}`),
  createMember:  body    => apiFetch('/api/members', { method:'POST', body: JSON.stringify(body) }),
  updateMember:  (id, b) => apiFetch(`/api/members/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteMember:  id      => apiFetch(`/api/members/${id}`, { method:'DELETE' }),

  // Memberships
  getMemberships:     (memberId, params = {}) => apiFetch(`/api/memberships/member/${memberId}${buildQuery(params)}`),
  getActiveMembership:memberId => apiFetch(`/api/memberships/member/${memberId}/active`),
  createMembership:   body     => apiFetch('/api/memberships', { method:'POST', body: JSON.stringify(body) }),
  updateMembership:   (id, b)  => apiFetch(`/api/memberships/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  renewMembership:    (id, body) => apiFetch(`/api/memberships/${id}/renew`, { method:'POST', body: JSON.stringify(body) }),

  // Trainers
  getTrainers:   (params = {})      => apiFetch(`/api/trainers${buildQuery(params)}`),
  getTrainer:    id      => apiFetch(`/api/trainers/${id}`),
  createTrainer: body    => apiFetch('/api/trainers', { method:'POST', body: JSON.stringify(body) }),
  updateTrainer: (id, b) => apiFetch(`/api/trainers/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteTrainer: id      => apiFetch(`/api/trainers/${id}`, { method:'DELETE' }),

  // Facilities
  getFacilities:   (params = {})      => apiFetch(`/api/facilities${buildQuery(params)}`),
  getFacility:     id      => apiFetch(`/api/facilities/${id}`),
  getActiveFacilities: ()  => apiFetch('/api/facilities/active'),
  createFacility:  body    => apiFetch('/api/facilities', { method:'POST', body: JSON.stringify(body) }),
  updateFacility:  (id, b) => apiFetch(`/api/facilities/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteFacility:  id      => apiFetch(`/api/facilities/${id}`, { method:'DELETE' }),

  // Schedules
  getSchedules:   (params = {})      => apiFetch(`/api/schedules${buildQuery(params)}`),
  getSchedule:    id      => apiFetch(`/api/schedules/${id}`),
  createSchedule: body    => apiFetch('/api/schedules', { method:'POST', body: JSON.stringify(body) }),
  updateSchedule: (id, b) => apiFetch(`/api/schedules/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteSchedule: id      => apiFetch(`/api/schedules/${id}`, { method:'DELETE' }),

  // Sessions
  getSessions:    (params = {})      => apiFetch(`/api/sessions${buildQuery(params)}`),
  getSession:     id      => apiFetch(`/api/sessions/${id}`),
  createSession:  body    => apiFetch('/api/sessions', { method:'POST', body: JSON.stringify(body) }),
  updateSessionStatus:(id,b) => apiFetch(`/api/sessions/${id}/status`, { method:'PUT', body: JSON.stringify(b) }),
  deleteSession:  id      => apiFetch(`/api/sessions/${id}`, { method:'DELETE' }),

  // Checkins
  getCheckins:     (params = {})     => apiFetch(`/api/checkins${buildQuery(params)}`),
  checkinManual:   body   => apiFetch('/api/checkins/manual', { method:'POST', body: JSON.stringify(body) }),
  checkinQR:       body   => apiFetch('/api/checkins/qr', { method:'POST', body: JSON.stringify(body) }),

  // Invoices
  getInvoices:    (params = {})      => apiFetch(`/api/invoices${buildQuery(params)}`),
  getInvoice:     id      => apiFetch(`/api/invoices/${id}`),
  getMemberInvoices: (m, params = {}) => apiFetch(`/api/invoices/member/${m}${buildQuery(params)}`),
  getOverdueInvoices: (params = {})  => apiFetch(`/api/invoices/overdue${buildQuery(params)}`),
  createInvoice:  body    => apiFetch('/api/invoices', { method:'POST', body: JSON.stringify(body) }),
  updateInvoiceStatus:(id,b)=>apiFetch(`/api/invoices/${id}/status`, { method:'PUT', body: JSON.stringify(b) }),

  // Payments
  getPaymentsByInvoice: (invId, params = {}) => apiFetch(`/api/payments/invoice/${invId}${buildQuery(params)}`),
  createPayment:  body        => apiFetch('/api/payments', { method:'POST', body: JSON.stringify(body) }),
  updatePaymentStatus:(id,b)  => apiFetch(`/api/payments/${id}/status`, { method:'PUT', body: JSON.stringify(b) }),

  // Reports
  getActiveMembers: (params = {})    => apiFetch(`/api/reports/active-members${buildQuery(params)}`),
  getRevenue:       (m,y,params={})  => apiFetch(`/api/reports/revenue?month=${m}&year=${y}${buildQuery(params).replace('?','&')}`),
  getRevenueDetail: (m,y,params={})  => apiFetch(`/api/reports/revenue/detail?month=${m}&year=${y}${buildQuery(params).replace('?','&')}`),
};

// Auth endpoints
api.auth = {
  login: (body) => apiFetch('/api/auth/login', { method: 'POST', body: JSON.stringify(body) }),
  register: (body) => apiFetch('/api/auth/register', { method: 'POST', body: JSON.stringify(body) }),
  changePassword: (body) => apiFetch('/api/auth/change-password', { method: 'POST', body: JSON.stringify(body) }),
  getProfile: () => apiFetch('/api/auth/profile'),
};
