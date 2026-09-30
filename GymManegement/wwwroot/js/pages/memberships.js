/* pages/memberships.js */
async function init_memberships() {
  // Load member list into dropdown
  try {
    const members = await api.getMembers();
    document.getElementById('ms-member-select').innerHTML =
      '<option value="">-- Chọn hội viên --</option>' +
      members.map(m => `<option value="${m.memberId}">${m.fullName}</option>`).join('');
  } catch (e) { toast(e.message, 'error'); }
}

async function loadMemberMemberships() {
  const memberId = document.getElementById('ms-member-select').value;
  if (!memberId) { toast('Chọn hội viên trước', 'info'); return; }
  loading('memberships-tbody');
  try {
    const list = await api.getMemberships(memberId);
    const tbody = document.getElementById('memberships-tbody');
    if (!list.length) { emptyRow('memberships-tbody', 7, 'Chưa có gói tập nào'); return; }
    tbody.innerHTML = list.map(m => {
      const days = m.daysRemaining ?? Math.max(0, Math.floor((new Date(m.endDate) - new Date()) / 86400000));
      return `<tr>
        <td>${m.membershipId}</td>
        <td>${m.membershipType}</td>
        <td>${moneyFmt(m.price)}</td>
        <td>${dateFmt(m.startDate)}</td>
        <td>${dateFmt(m.endDate)}</td>
        <td><span class="badge ${days <= 7 ? 'badge-red' : days <= 30 ? 'badge-yellow' : 'badge-green'}">${days} ngày</span></td>
        <td>${badge(m.isActive ? 'Còn hiệu lực' : 'Đã hết hạn', m.isActive ? 'green' : 'gray')}</td>
      </tr>`;
    }).join('');
  } catch (e) { toast(e.message, 'error'); }
}

async function openAddMembership() {
  try {
    const members = await api.getMembers();
    document.getElementById('ms-member').innerHTML =
      members.map(m => `<option value="${m.memberId}">${m.fullName}</option>`).join('');
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('ms-start').value = today;
    openModal('modal-membership');
  } catch (e) { toast(e.message, 'error'); }
}

// Auto-set end date based on type
document.getElementById('ms-type')?.addEventListener('change', () => {
  const start = document.getElementById('ms-start').value;
  if (!start) return;
  const d = new Date(start);
  const type = document.getElementById('ms-type').value;
  if (type === 'Monthly')   d.setMonth(d.getMonth() + 1);
  if (type === 'Quarterly') d.setMonth(d.getMonth() + 3);
  if (type === 'Annual')    d.setFullYear(d.getFullYear() + 1);
  document.getElementById('ms-end').value = d.toISOString().split('T')[0];
});

document.getElementById('membership-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    memberId:       +document.getElementById('ms-member').value,
    membershipType: document.getElementById('ms-type').value,
    price:          +document.getElementById('ms-price').value,
    startDate:      document.getElementById('ms-start').value,
    endDate:        document.getElementById('ms-end').value,
  };
  try {
    await api.createMembership(body);
    toast('Đăng ký gói tập thành công!', 'success');
    closeModal('modal-membership');
    loadMemberMemberships();
  } catch (err) { toast(err.message, 'error'); }
});
