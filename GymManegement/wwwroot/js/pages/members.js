/* pages/members.js */
let membersCurrentPage = 1;
let membersPageSize = 10;
let membersTotalPages = 1;

async function loadMembers(page = 1) {
  loading('members-tbody');
  membersCurrentPage = page;
  try {
    const res = await api.getMembers({ pageNumber: page, pageSize: membersPageSize });
    const data = res.data ?? [];
    const total = res.total ?? 0;
    membersTotalPages = Math.ceil(total / membersPageSize);

    const tbody = document.getElementById('members-tbody');
    if (!data.length) { emptyRow('members-tbody', 7); }
    else {
      tbody.innerHTML = data.map(m => `
        <tr>
          <td>${m.memberId}</td>
          <td><strong>${m.fullName}</strong></td>
          <td>${m.phone || '—'}</td>
          <td>${m.email || '—'}</td>
          <td>${dateFmt(m.joinDate)}</td>
          <td>${statusBadge(m.status)}</td>
          <td>
            <button class="btn btn-icon btn-sm" onclick="openEditMember(${m.memberId})" data-tip="Sửa"><span>✏️</span></button>
            <button class="btn btn-icon btn-sm" onclick="confirmDelete('member', ${m.memberId})" data-tip="Xóa"><span>🗑️</span></button>
          </td>
        </tr>
      `).join('');
    }
    renderPagination('members-pagination', membersCurrentPage, membersTotalPages, loadMembers);
  } catch (e) { console.error(e); emptyRow('members-tbody', 7, 'Lỗi tải dữ liệu'); }
}

function openAddMember() {
  document.getElementById('member-form').reset();
  document.getElementById('modal-member-title').textContent = 'Thêm hội viên';
  document.getElementById('member-form').dataset.id = '';
  document.getElementById('m-join-date').value = new Date().toISOString().split('T')[0];
  openModal('modal-member');
}

async function openEditMember(id) {
  try {
    const res = await api.getMember(id);
    const m = res.data ?? res;
    document.getElementById('m-fullname').value = m.fullName || '';
    document.getElementById('m-phone').value = m.phone || '';
    document.getElementById('m-email').value = m.email || '';
    document.getElementById('m-dob').value = m.dateOfBirth ? m.dateOfBirth.split('T')[0] : '';
    document.getElementById('m-join-date').value = m.joinDate ? m.joinDate.split('T')[0] : new Date().toISOString().split('T')[0];
    document.getElementById('m-status').value = m.status || 'Active';
    document.getElementById('modal-member-title').textContent = 'Sửa hội viên';
    document.getElementById('member-form').dataset.id = id;
    openModal('modal-member');
  } catch (e) { toast('Không tải được thông tin hội viên', 'error'); }
}

document.getElementById('member-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const id = e.target.dataset.id;
  const body = {
    fullName: document.getElementById('m-fullname').value.trim(),
    phone: document.getElementById('m-phone').value.trim() || null,
    email: document.getElementById('m-email').value.trim(),
    dateOfBirth: document.getElementById('m-dob').value || null,
    joinDate: document.getElementById('m-join-date').value,
    status: document.getElementById('m-status').value
  };
  if (!body.fullName || !body.email) return toast('Vui lòng nhập đầy đủ họ tên và email', 'warning');
  try {
    if (id) { await api.updateMember(id, body); toast('Cập nhật thành công', 'success'); }
    else { await api.createMember(body); toast('Thêm thành công', 'success'); }
    closeModal('modal-member'); loadMembers(membersCurrentPage);
  } catch (err) { toast(err.message || 'Lỗi lưu dữ liệu', 'error'); }
});

function confirmDelete(type, id) {
  document.getElementById('confirm-msg').textContent = `Bạn có chắc muốn xóa ${type === 'member' ? 'hội viên' : 'mục'} này?`;
  document.getElementById('confirm-ok').onclick = async () => {
    try { await api.deleteMember(id); toast('Đã xóa', 'success'); loadMembers(membersCurrentPage); }
    catch (err) { toast(err.message || 'Lỗi xóa', 'error'); }
    closeModal('modal-confirm');
  };
  openModal('modal-confirm');
}

document.getElementById('member-search')?.addEventListener('input', (e) => {
  clearTimeout(window._memberSearchTimer);
  window._memberSearchTimer = setTimeout(() => loadMembers(1), 300);
});

function init_members() { loadMembers(1); }
