/* pages/memberships.js */
let membershipsMemberId = null;

async function loadMemberMemberships() {
  const memberId = document.getElementById('ms-member-select').value;
  if (!memberId) return toast('Vui lòng chọn hội viên', 'warning');
  membershipsMemberId = memberId;
  loading('memberships-tbody');
  try {
    const res = await api.getMemberships(memberId);
    const data = res.data ?? [];
    const tbody = document.getElementById('memberships-tbody');
    if (!data.length) { emptyRow('memberships-tbody', 7); }
    else {
      tbody.innerHTML = data.map(m => `
        <tr>
          <td>${m.membershipId}</td>
          <td>${m.membershipType || '—'}</td>
          <td>${moneyFmt(m.price || 0)}</td>
          <td>${dateFmt(m.startDate)}</td>
          <td>${dateFmt(m.endDate)}</td>
          <td><span class="badge badge-${m.daysRemaining <= 7 ? 'yellow' : 'green'}">${m.daysRemaining} ngày</span></td>
          <td>${statusBadge(m.isActive ? 'Active' : 'Inactive')}</td>
        </tr>
      `).join('');
    }
  } catch (e) { console.error(e); emptyRow('memberships-tbody', 7, 'Lỗi tải dữ liệu'); }
}

async function loadMemberSelectForMembership(selectId) {
  try {
    const res = await api.getMembers({ pageSize: 200 });
    populateSelect(selectId, res.data ?? [], 'memberId', 'fullName');
  } catch (e) { console.error(e); }
}

function openAddMembership() {
  if (!membershipsMemberId) { const sel = document.getElementById('ms-member-select').value; if (!sel) return toast('Vui lòng chọn hội viên trước', 'warning'); membershipsMemberId = sel; }
  document.getElementById('membership-form').reset();
  document.getElementById('ms-member').value = membershipsMemberId;
  document.getElementById('ms-start').value = new Date().toISOString().split('T')[0];
  const end = new Date(); end.setMonth(end.getMonth() + 1); document.getElementById('ms-end').value = end.toISOString().split('T')[0];
  loadMemberSelectForMembership('ms-member');
  openModal('modal-membership');
}

document.getElementById('membership-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    memberId: parseInt(document.getElementById('ms-member').value),
    membershipType: document.getElementById('ms-type').value,
    price: parseFloat(document.getElementById('ms-price').value),
    startDate: document.getElementById('ms-start').value,
    endDate: document.getElementById('ms-end').value,
    isActive: true
  };
  if (!body.memberId || !body.price) return toast('Vui lòng nhập đầy đủ', 'warning');
  try {
    await api.createMembership(body);
    toast('Đăng ký gói tập thành công', 'success');
    closeModal('modal-membership');
    if (membershipsMemberId) loadMemberMemberships();
  } catch (err) { toast(err.message || 'Lỗi lưu', 'error'); }
});

function init_memberships() { loadMemberSelectForMembership('ms-member-select'); }
