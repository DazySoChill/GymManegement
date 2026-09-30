/* ============================================================
   pages/trainers.js
   ============================================================ */
let trainersList = [];

async function init_trainers() { loadTrainers(); }

async function loadTrainers() {
  loading('trainers-tbody');
  try { trainersList = await api.getTrainers(); renderTrainers(); }
  catch (e) { toast(e.message, 'error'); }
}

function renderTrainers(search = '') {
  const tbody = document.getElementById('trainers-tbody');
  let data = trainersList;
  if (search) { const q = search.toLowerCase(); data = data.filter(t => t.fullName?.toLowerCase().includes(q) || t.email?.toLowerCase().includes(q)); }
  if (!data.length) { emptyRow('trainers-tbody', 6); return; }
  tbody.innerHTML = data.map(t => `
    <tr>
      <td>${t.trainerId}</td><td><strong>${t.fullName}</strong></td>
      <td>${t.phone || '—'}</td><td>${t.email}</td><td>${t.specialization || '—'}</td>
      <td>
        <button class="btn btn-ghost btn-sm" onclick="editTrainer(${t.trainerId})">✏️</button>
        <button class="btn btn-danger btn-sm" onclick="deleteTrainer(${t.trainerId})">🗑️</button>
      </td>
    </tr>`).join('');
}

document.getElementById('trainer-search')?.addEventListener('input', e => renderTrainers(e.target.value));

let editingTrainerId = null;

function openAddTrainer() {
  editingTrainerId = null;
  document.getElementById('trainer-form').reset();
  document.getElementById('modal-trainer-title').textContent = 'Thêm HLV';
  openModal('modal-trainer');
}

function editTrainer(id) {
  const t = trainersList.find(x => x.trainerId === id); if (!t) return;
  editingTrainerId = id;
  document.getElementById('modal-trainer-title').textContent = 'Sửa HLV';
  document.getElementById('t-fullname').value       = t.fullName;
  document.getElementById('t-phone').value          = t.phone || '';
  document.getElementById('t-email').value          = t.email;
  document.getElementById('t-specialization').value = t.specialization || '';
  openModal('modal-trainer');
}

document.getElementById('trainer-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = { fullName: document.getElementById('t-fullname').value, phone: document.getElementById('t-phone').value, email: document.getElementById('t-email').value, specialization: document.getElementById('t-specialization').value };
  try {
    if (editingTrainerId) { await api.updateTrainer(editingTrainerId, body); toast('Cập nhật HLV thành công', 'success'); }
    else { await api.createTrainer(body); toast('Thêm HLV thành công', 'success'); }
    closeModal('modal-trainer'); loadTrainers();
  } catch (err) { toast(err.message, 'error'); }
});

async function deleteTrainer(id) {
  if (!confirm('Xoá huấn luyện viên?')) return;
  try { await api.deleteTrainer(id); toast('Đã xoá HLV', 'success'); loadTrainers(); }
  catch (e) { toast(e.message, 'error'); }
}
