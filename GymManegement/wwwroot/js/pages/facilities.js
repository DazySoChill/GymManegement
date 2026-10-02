/* pages/facilities.js */
async function loadFacilities() {
  loading('facilities-tbody');
  try {
    const res = await api.getFacilities({ pageSize: 200 });
    const data = res.data ?? [];
    const tbody = document.getElementById('facilities-tbody');
    if (!data.length) { emptyRow('facilities-tbody', 5); }
    else {
      tbody.innerHTML = data.map(f => `
        <tr>
          <td>${f.facilityId}</td>
          <td><strong>${f.name}</strong></td>
          <td>${f.description || '—'}</td>
          <td>${statusBadge(f.isActive ? 'Active' : 'Inactive')}</td>
          <td>
            <button class="btn btn-icon btn-sm" onclick="openEditFacility(${f.facilityId})" data-tip="Sửa"><span>✏️</span></button>
            <button class="btn btn-icon btn-sm" onclick="confirmDeleteFacility(${f.facilityId})" data-tip="Xóa"><span>🗑️</span></button>
          </td>
        </tr>
      `).join('');
    }
  } catch (e) { console.error(e); emptyRow('facilities-tbody', 5, 'Lỗi tải dữ liệu'); }
}

function openAddFacility() {
  document.getElementById('facility-form').reset();
  document.getElementById('modal-facility-title').textContent = 'Thêm phòng';
  document.getElementById('facility-form').dataset.id = '';
  document.getElementById('f-active').value = 'true';
  openModal('modal-facility');
}

async function openEditFacility(id) {
  try {
    const res = await api.getFacility(id);
    const f = res.data ?? res;
    document.getElementById('f-name').value = f.name || '';
    document.getElementById('f-desc').value = f.description || '';
    document.getElementById('f-active').value = f.isActive ? 'true' : 'false';
    document.getElementById('modal-facility-title').textContent = 'Sửa phòng';
    document.getElementById('facility-form').dataset.id = id;
    openModal('modal-facility');
  } catch (e) { toast('Không tải được thông tin phòng', 'error'); }
}

document.getElementById('facility-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const id = e.target.dataset.id;
  const body = { name: document.getElementById('f-name').value.trim(), description: document.getElementById('f-desc').value.trim() || null, isActive: document.getElementById('f-active').value === 'true' };
  if (!body.name) return toast('Vui lòng nhập tên phòng', 'warning');
  try {
    if (id) { await api.updateFacility(id, body); toast('Cập nhật thành công', 'success'); }
    else { await api.createFacility(body); toast('Thêm thành công', 'success'); }
    closeModal('modal-facility'); loadFacilities();
  } catch (err) { toast(err.message || 'Lỗi lưu', 'error'); }
});

function confirmDeleteFacility(id) {
  document.getElementById('confirm-msg').textContent = 'Bạn có chắc muốn xóa phòng này?';
  document.getElementById('confirm-ok').onclick = async () => {
    try { await api.deleteFacility(id); toast('Đã xóa', 'success'); loadFacilities(); }
    catch (err) { toast(err.message || 'Lỗi xóa', 'error'); }
    closeModal('modal-confirm');
  };
  openModal('modal-confirm');
}

function init_facilities() { loadFacilities(); }
