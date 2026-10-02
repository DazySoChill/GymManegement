/* pages/schedules.js */
let schedulesCurrentPage = 1;
let schedulesPageSize = 10;
let schedulesTotalPages = 1;

async function loadSchedules(page = 1) {
  loading('schedules-tbody');
  schedulesCurrentPage = page;
  try {
    const res = await api.getSchedules({ pageNumber: page, pageSize: schedulesPageSize });
    const data = res.data ?? [];
    const total = res.total ?? 0;
    schedulesTotalPages = Math.ceil(total / schedulesPageSize);

    const tbody = document.getElementById('schedules-tbody');
    if (!data.length) { emptyRow('schedules-tbody', 7); }
    else {
      tbody.innerHTML = data.map(s => `
        <tr>
          <td>${s.scheduleId}</td>
          <td>${s.memberName || '—'}</td>
          <td>${s.trainerName || '—'}</td>
          <td>${s.facilityName || '—'}</td>
          <td>${datetimeFmt(s.startTime)}</td>
          <td>${datetimeFmt(s.endTime)}</td>
          <td>
            <button class="btn btn-icon btn-sm" onclick="confirmDeleteSchedule(${s.scheduleId})" data-tip="Xóa"><span>🗑️</span></button>
          </td>
        </tr>
      `).join('');
    }
    renderPagination('schedules-pagination', schedulesCurrentPage, schedulesTotalPages, loadSchedules);
  } catch (e) { console.error(e); emptyRow('schedules-tbody', 7, 'Lỗi tải dữ liệu'); }
}

function openAddSchedule() {
  document.getElementById('sch-form').reset();
  document.getElementById('sch-start').value = new Date().toISOString().slice(0, 16);
  const end = new Date(); end.setHours(end.getHours() + 1); document.getElementById('sch-end').value = end.toISOString().slice(0, 16);
  Promise.all([
    api.getMembers({ pageSize: 200 }).then(r => populateSelect('sch-member', r.data ?? [], 'memberId', 'fullName')),
    api.getTrainers({ pageSize: 200 }).then(r => populateSelect('sch-trainer', r.data ?? [], 'trainerId', 'fullName')),
    api.getActiveFacilities().then(r => populateSelect('sch-facility', r.data ?? [], 'facilityId', 'name'))
  ]);
  openModal('modal-schedule');
}

document.getElementById('sch-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    memberId: parseInt(document.getElementById('sch-member').value),
    trainerId: parseInt(document.getElementById('sch-trainer').value),
    facilityId: parseInt(document.getElementById('sch-facility').value),
    startTime: document.getElementById('sch-start').value,
    endTime: document.getElementById('sch-end').value
  };
  if (!body.memberId || !body.trainerId || !body.facilityId || !body.startTime || !body.endTime) return toast('Vui lòng nhập đầy đủ', 'warning');
  try {
    await api.createSchedule(body);
    toast('Đặt lịch thành công', 'success');
    closeModal('modal-schedule');
    loadSchedules(schedulesCurrentPage);
  } catch (err) { toast(err.message || 'Lỗi lưu', 'error'); }
});

function confirmDeleteSchedule(id) {
  document.getElementById('confirm-msg').textContent = 'Bạn có chắc muốn xóa lịch tập này?';
  document.getElementById('confirm-ok').onclick = async () => {
    try { await api.deleteSchedule(id); toast('Đã xóa', 'success'); loadSchedules(schedulesCurrentPage); }
    catch (err) { toast(err.message || 'Lỗi xóa', 'error'); }
    closeModal('modal-confirm');
  };
  openModal('modal-confirm');
}

function init_schedules() { loadSchedules(1); }
