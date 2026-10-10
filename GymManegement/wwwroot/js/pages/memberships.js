/* pages/memberships.js */
let membershipsMemberId = null;

async function loadMemberMemberships() {
  const user = getCurrentUser();
  
  // For members, use their own memberId, for admins use the selected one
  let memberId;
  if (isMember()) {
    memberId = user.memberId;
    if (!memberId) {
      toast('Không tìm thấy thông tin hội viên', 'error');
      return;
    }
  } else {
    memberId = document.getElementById('ms-member-select').value;
    if (!memberId) return toast('Vui lòng chọn hội viên', 'warning');
  }
  
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
  // POST /api/membership returns 500 error - disable this feature
  toast('Chức năng tạm thời không khả dụng (API lỗi)', 'warning');
  return;
  
  /* Commented out until API is fixed
  if (!membershipsMemberId) { const sel = document.getElementById('ms-member-select').value; if (!sel) return toast('Vui lòng chọn hội viên trước', 'warning'); membershipsMemberId = sel; }
  document.getElementById('membership-form').reset();
  document.getElementById('ms-member').value = membershipsMemberId;
  document.getElementById('ms-start').value = new Date().toISOString().split('T')[0];
  const end = new Date(); end.setMonth(end.getMonth() + 1); document.getElementById('ms-end').value = end.toISOString().split('T')[0];
  loadMemberSelectForMembership('ms-member');
  openModal('modal-membership');
  */
}

document.getElementById('membership-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  
  // POST /api/membership returns 500 error - block submission
  toast('Chức năng tạm thời không khả dụng (API lỗi)', 'warning');
  return;
  
  /* Commented out until API is fixed
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
  */
});

function init_memberships() {
  const user = getCurrentUser();
  
  if (isMember()) {
    // Member view: hide selector and create button, auto-load own memberships
    const card = document.querySelector('#page-memberships .card');
    const toolbar = card.querySelector('.card-toolbar');
    if (toolbar) toolbar.style.display = 'none';
    
    // Change title
    const title = card.querySelector('h2');
    if (title) title.textContent = '🎫 Gói tập của bạn';
    
    // Auto-load own memberships
    loadMemberMemberships();
  } else if (isAdmin()) {
    // Admin view: show selector and create button
    loadMemberSelectForMembership('ms-member-select');
    
    // Hide create button (API returns 500)
    const createBtn = document.querySelector('button[onclick="openAddMembership()"]');
    if (createBtn) {
      createBtn.style.display = 'none';
      createBtn.insertAdjacentHTML('afterend', '<span style="color:var(--text-muted);font-size:0.85rem;margin-left:12px">⚠️ Tạo gói tập tạm thời không khả dụng</span>');
    }
  }
}
