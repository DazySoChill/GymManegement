/* pages/facilities.js */
let facilitiesList = [];
async function init_facilities() { loadFacilities(); }
async function loadFacilities() {
  loading('facilities-tbody');
  try { facilitiesList = await api.getFacilities(); renderFacilities(); } catch (e) { toast(e.message, 'error'); }
}
function renderFacilities() {
  const tbody = document.getElementById('facilities-tbody');
  if (!facilitiesList.length) { emptyRow('facilities-tbody', 5); return; }
  tbody.innerHTML = facilitiesList.map(f => `
    <tr>
      <td>${f.facilityId}</td><td><strong>${f.name}</strong></td><td>${f.description || '—'}</td>
      <td>${badge(f.isActive ? 'Hoạt động' : 'Dừng', f.isActive ? 'green' : 'red')}</td>
      <td>
        <button class="btn btn-ghost btn-sm" onclick="editFacility(${f.facilityId})">✏️</button>
        <button class="btn btn-danger btn-sm" onclick="deleteFacility(${f.facilityId})">🗑️</button>
      </td>
    </tr>`).join('');
}
let editingFacilityId = null;
function openAddFacility() { editingFacilityId = null; document.getElementById('facility-form').reset(); document.getElementById('modal-facility-title').textContent = 'Thêm phòng/thiết bị'; openModal('modal-facility'); }
function editFacility(id) {
  const f = facilitiesList.find(x => x.facilityId === id); if (!f) return;
  editingFacilityId = id; document.getElementById('modal-facility-title').textContent = 'Sửa phòng/thiết bị';
  document.getElementById('f-name').value   = f.name;
  document.getElementById('f-desc').value   = f.description || '';
  document.getElementById('f-active').value = f.isActive ? 'true' : 'false';
  openModal('modal-facility');
}
document.getElementById('facility-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = { name: document.getElementById('f-name').value, description: document.getElementById('f-desc').value, isActive: document.getElementById('f-active').value === 'true' };
  try {
    if (editingFacilityId) { await api.updateFacility(editingFacilityId, body); toast('Cập nhật thành công', 'success'); }
    else { await api.createFacility(body); toast('Thêm thành công', 'success'); }
    closeModal('modal-facility'); loadFacilities();
  } catch (err) { toast(err.message, 'error'); }
});
async function deleteFacility(id) {
  if (!confirm('Xoá phòng/thiết bị?')) return;
  try { await api.deleteFacility(id); toast('Đã xoá', 'success'); loadFacilities(); } catch (e) { toast(e.message, 'error'); }
}
