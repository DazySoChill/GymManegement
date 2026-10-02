/* pages/trainers.js */
let trainersCurrentPage = 1;
let trainersPageSize = 10;
let trainersTotalPages = 1;

async function loadTrainers(page = 1) {
  loading('trainers-tbody');
  trainersCurrentPage = page;
  try {
    const res = await api.getTrainers({ pageNumber: page, pageSize: trainersPageSize });
    const data = res.data ?? [];
    const total = res.total ?? 0;
    trainersTotalPages = Math.ceil(total / trainersPageSize);

    const tbody = document.getElementById('trainers-tbody');
    if (!data.length) { emptyRow('trainers-tbody', 6); }
    else {
      tbody.innerHTML = data.map(t => `
        <tr>
          <td>${t.trainerId}</td>
          <td><strong>${t.fullName}</strong></td>
          <td>${t.phone || '—'}</td>
          <td>${t.email || '—'}</td>
          <td>${t.specialization || '—'}</td>
          <td>
            <button class="btn btn-icon btn-sm" onclick="openEditTrainer(${t.trainerId})" data-tip="Sửa"><span>✏️</span></button>
            <button class="btn btn-icon btn-sm" onclick="confirmDeleteTrainer(${t.trainerId})" data-tip="Xóa"><span>🗑️</span></button>
          </td>
        </tr>
      `).join('');
    }
    renderPagination('trainers-pagination', trainersCurrentPage, trainersTotalPages, loadTrainers);
  } catch (e) { console.error(e); emptyRow('trainers-tbody', 6, 'Lỗi tải dữ liệu'); }
}

function openAddTrainer() {
  document.getElementById('trainer-form').reset();
  document.getElementById('modal-trainer-title').textContent = 'Thêm HLV';
  document.getElementById('trainer-form').dataset.id = '';
  openModal('modal-trainer');
}

async function openEditTrainer(id) {
  try {
    const res = await api.getTrainer(id);
    const t = res.data ?? res;
    document.getElementById('t-fullname').value = t.fullName || '';
    document.getElementById('t-phone').value = t.phone || '';
    document.getElementById('t-email').value = t.email || '';
    document.getElementById('t-specialization').value = t.specialization || '';
    document.getElementById('modal-trainer-title').textContent = 'Sửa HLV';
    document.getElementById('trainer-form').dataset.id = id;
    openModal('modal-trainer');
  } catch (e) { toast('Không tải được thông tin HLV', 'error'); }
}

document.getElementById('trainer-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const id = e.target.dataset.id;
  const body = { fullName: document.getElementById('t-fullname').value.trim(), phone: document.getElementById('t-phone').value.trim() || null, email: document.getElementById('t-email').value.trim(), specialization: document.getElementById('t-specialization').value.trim() || null };
  if (!body.fullName || !body.email) return toast('Vui lòng nhập đầy đủ họ tên và email', 'warning');
  try {
    if (id) { await api.updateTrainer(id, body); toast('Cập nhật thành công', 'success'); }
    else { await api.createTrainer(body); toast('Thêm thành công', 'success'); }
    closeModal('modal-trainer'); loadTrainers(trainersCurrentPage);
  } catch (err) { toast(err.message || 'Lỗi lưu', 'error'); }
});

function confirmDeleteTrainer(id) {
  document.getElementById('confirm-msg').textContent = 'Bạn có chắc muốn xóa HLV này?';
  document.getElementById('confirm-ok').onclick = async () => {
    try { await api.deleteTrainer(id); toast('Đã xóa', 'success'); loadTrainers(trainersCurrentPage); }
    catch (err) { toast(err.message || 'Lỗi xóa', 'error'); }
    closeModal('modal-confirm');
  };
  openModal('modal-confirm');
}

document.getElementById('trainer-search')?.addEventListener('input', (e) => {
  clearTimeout(window._trainerSearchTimer);
  window._trainerSearchTimer = setTimeout(() => loadTrainers(1), 300);
});

function init_trainers() { loadTrainers(1); }
