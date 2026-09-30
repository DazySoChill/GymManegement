/* ============================================================
   pages/members.js – Hội viên CRUD
   ============================================================ */

let membersList = [];

async function init_members() { loadMembers(); }

async function loadMembers(search = '') {
  loading('members-tbody');
  try {
    membersList = await api.getMembers();
    renderMembers(search);
  } catch (e) { toast(e.message, 'error'); }
}

function renderMembers(search = '') {
  const tbody = document.getElementById('members-tbody');
  let data = membersList;
  if (search) {
    const q = search.toLowerCase();
    data = data.filter(m =>
      m.fullName?.toLowerCase().includes(q) ||
      m.email?.toLowerCase().includes(q) ||
      m.phone?.includes(q));
  }
  if (!data.length) { emptyRow('members-tbody', 7); return; }
  tbody.innerHTML = data.map(m => `
    <tr>
      <td>${m.memberId}</td>
      <td><strong>${m.fullName}</strong></td>
      <td>${m.phone || '—'}</td>
      <td>${m.email}</td>
      <td>${dateFmt(m.joinDate)}</td>
      <td>${statusBadge(m.status)}</td>
      <td>
        <button class="btn btn-ghost btn-sm" onclick="editMember(${m.memberId})">✏️ Sửa</button>
        <button class="btn btn-danger btn-sm" onclick="confirmDeleteMember(${m.memberId})">🗑️</button>
      </td>
    </tr>`).join('');
}

document.getElementById('member-search')?.addEventListener('input', e => renderMembers(e.target.value));

let editingMemberId = null;

function openAddMember() {
  editingMemberId = null;
  document.getElementById('member-form').reset();
  document.getElementById('modal-member-title').textContent = 'Thêm hội viên';
  openModal('modal-member');
}

async function editMember(id) {
  const m = membersList.find(x => x.memberId === id);
  if (!m) return;
  editingMemberId = id;
  document.getElementById('modal-member-title').textContent = 'Sửa hội viên';
  document.getElementById('m-fullname').value = m.fullName;
  document.getElementById('m-phone').value    = m.phone || '';
  document.getElementById('m-email').value    = m.email;
  document.getElementById('m-dob').value      = m.dateOfBirth?.substring(0, 10) || '';
  document.getElementById('m-status').value   = m.status;
  openModal('modal-member');
}

document.getElementById('member-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    fullName:    document.getElementById('m-fullname').value,
    phone:       document.getElementById('m-phone').value,
    email:       document.getElementById('m-email').value,
    dateOfBirth: document.getElementById('m-dob').value,
    status:      document.getElementById('m-status')?.value || 'Active',
  };
  try {
    if (editingMemberId) {
      await api.updateMember(editingMemberId, body);
      toast('Cập nhật hội viên thành công', 'success');
    } else {
      await api.createMember(body);
      toast('Thêm hội viên thành công', 'success');
    }
    closeModal('modal-member');
    loadMembers();
  } catch (err) { toast(err.message, 'error'); }
});

let deleteMemberId = null;

function confirmDeleteMember(id) {
  const m = membersList.find(x => x.memberId === id);
  deleteMemberId = id;
  document.getElementById('confirm-msg').textContent = `Xoá hội viên "${m?.fullName}"?`;
  openModal('modal-confirm');
}

document.getElementById('confirm-ok')?.addEventListener('click', async () => {
  if (!deleteMemberId) return;
  try {
    await api.deleteMember(deleteMemberId);
    toast('Đã xoá hội viên', 'success');
    closeModal('modal-confirm');
    loadMembers();
  } catch (e) { toast(e.message, 'error'); }
});
