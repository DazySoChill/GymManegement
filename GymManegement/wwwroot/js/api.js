/* ============================================================
   api.js – Trung tâm gọi API backend
   BASE_URL tự động theo origin
   ============================================================ */

const BASE = window.location.origin;

async function apiFetch(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `HTTP ${res.status}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

const api = {
  // Members
  getMembers:    ()      => apiFetch('/api/members'),
  getMember:     id      => apiFetch(`/api/members/${id}`),
  createMember:  body    => apiFetch('/api/members', { method:'POST', body: JSON.stringify(body) }),
  updateMember:  (id, b) => apiFetch(`/api/members/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteMember:  id      => apiFetch(`/api/members/${id}`, { method:'DELETE' }),

  // Memberships
  getMemberships:     memberId => apiFetch(`/api/memberships/member/${memberId}`),
  getActiveMembership:memberId => apiFetch(`/api/memberships/member/${memberId}/active`),
  createMembership:   body     => apiFetch('/api/memberships', { method:'POST', body: JSON.stringify(body) }),
  updateMembership:   (id, b)  => apiFetch(`/api/memberships/${id}`, { method:'PUT', body: JSON.stringify(b) }),

  // Trainers
  getTrainers:   ()      => apiFetch('/api/trainers'),
  getTrainer:    id      => apiFetch(`/api/trainers/${id}`),
  createTrainer: body    => apiFetch('/api/trainers', { method:'POST', body: JSON.stringify(body) }),
  updateTrainer: (id, b) => apiFetch(`/api/trainers/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteTrainer: id      => apiFetch(`/api/trainers/${id}`, { method:'DELETE' }),

  // Facilities
  getFacilities:   ()      => apiFetch('/api/facilities'),
  getFacility:     id      => apiFetch(`/api/facilities/${id}`),
  getActiveFacilities: ()  => apiFetch('/api/facilities/active'),
  createFacility:  body    => apiFetch('/api/facilities', { method:'POST', body: JSON.stringify(body) }),
  updateFacility:  (id, b) => apiFetch(`/api/facilities/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteFacility:  id      => apiFetch(`/api/facilities/${id}`, { method:'DELETE' }),

  // Schedules
  getSchedules:   ()      => apiFetch('/api/schedules'),
  getSchedule:    id      => apiFetch(`/api/schedules/${id}`),
  createSchedule: body    => apiFetch('/api/schedules', { method:'POST', body: JSON.stringify(body) }),
  updateSchedule: (id, b) => apiFetch(`/api/schedules/${id}`, { method:'PUT', body: JSON.stringify(b) }),
  deleteSchedule: id      => apiFetch(`/api/schedules/${id}`, { method:'DELETE' }),

  // Sessions
  getSessions:    ()      => apiFetch('/api/sessions'),
  getSession:     id      => apiFetch(`/api/sessions/${id}`),
  createSession:  body    => apiFetch('/api/sessions', { method:'POST', body: JSON.stringify(body) }),
  updateSessionStatus:(id,b) => apiFetch(`/api/sessions/${id}/status`, { method:'PUT', body: JSON.stringify(b) }),
  deleteSession:  id      => apiFetch(`/api/sessions/${id}`, { method:'DELETE' }),

  // Checkins
  getCheckins:     ()     => apiFetch('/api/checkins'),
  checkinManual:   body   => apiFetch('/api/checkins', { method:'POST', body: JSON.stringify(body) }),
  checkinQR:       body   => apiFetch('/api/checkins/qr', { method:'POST', body: JSON.stringify(body) }),

  // Invoices
  getInvoices:    ()      => apiFetch('/api/invoices'),
  getInvoice:     id      => apiFetch(`/api/invoices/${id}`),
  getMemberInvoices: m    => apiFetch(`/api/invoices/member/${m}`),
  getOverdueInvoices: ()  => apiFetch('/api/invoices/overdue'),
  createInvoice:  body    => apiFetch('/api/invoices', { method:'POST', body: JSON.stringify(body) }),
  updateInvoiceStatus:(id,b)=>apiFetch(`/api/invoices/${id}/status`, { method:'PUT', body: JSON.stringify(b) }),

  // Payments
  getPaymentsByInvoice: invId => apiFetch(`/api/payments/invoice/${invId}`),
  createPayment:  body        => apiFetch('/api/payments', { method:'POST', body: JSON.stringify(body) }),
  updatePaymentStatus:(id,b)  => apiFetch(`/api/payments/${id}/status`, { method:'PUT', body: JSON.stringify(b) }),

  // Reports
  getActiveMembers: ()           => apiFetch('/api/reports/active-members'),
  getRevenue:       (m,y)        => apiFetch(`/api/reports/revenue?month=${m}&year=${y}`),
  getRevenueDetail: (m,y)        => apiFetch(`/api/reports/revenue/detail?month=${m}&year=${y}`),
  getExpiringSoon:  (days=7)     => apiFetch(`/api/reports/expiring-soon?daysAhead=${days}`),
};
