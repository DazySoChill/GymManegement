/* pages/schedules.js */
let schedulesList = [];
async function init_schedules() { loadSchedules(); }
async function loadSchedules() {
  loading('schedules-tbody');
  try { schedulesList = await api.getSchedules(); renderSchedules(); } catch (e) { toast(e.message, 'error'); }
}
function renderSchedules() {
  const tbody = document.getElementById('schedules-tbody');
  if (!schedulesList.length) { emptyRow('schedules-tbody', 7); return; }
  tbody.innerHTML = schedulesList.map(s => `
    <tr>
      <td>${s.scheduleId}</td><td>${s.memberName || s.memberId}</td><td>${s.trainerName || s.trainerId}</td>
      <td>${s.facilityName || s.facilityId}</td><td>${datetimeFmt(s.startTime)}</td><td>${datetimeFmt(s.endTime)}</td>
      <td><button class="btn btn-danger btn-sm" onclick="deleteSchedule(${s.scheduleId})">🗑️</button></td>
    </tr>`).join('');
}
async function openAddSchedule() {
  await populateScheduleDropdowns();
  document.getElementById('sch-form').reset();
  openModal('modal-schedule');
}
async function populateScheduleDropdowns() {
  try {
    const [members, trainers, facilities] = await Promise.all([api.getMembers(), api.getTrainers(), api.getActiveFacilities()]);
    document.getElementById('sch-member').innerHTML   = members.map(m => `<option value="${m.memberId}">${m.fullName}</option>`).join('');
    document.getElementById('sch-trainer').innerHTML  = trainers.map(t => `<option value="${t.trainerId}">${t.fullName}</option>`).join('');
    document.getElementById('sch-facility').innerHTML = facilities.map(f => `<option value="${f.facilityId}">${f.name}</option>`).join('');
  } catch (e) { toast(e.message, 'error'); }
}
document.getElementById('sch-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = { memberId: +document.getElementById('sch-member').value, trainerId: +document.getElementById('sch-trainer').value, facilityId: +document.getElementById('sch-facility').value, startTime: document.getElementById('sch-start').value, endTime: document.getElementById('sch-end').value };
  try { await api.createSchedule(body); toast('Tạo lịch thành công', 'success'); closeModal('modal-schedule'); loadSchedules(); }
  catch (err) { toast(err.message, 'error'); }
});
async function deleteSchedule(id) {
  if (!confirm('Xoá lịch tập?')) return;
  try { await api.deleteSchedule(id); toast('Đã xoá', 'success'); loadSchedules(); } catch (e) { toast(e.message, 'error'); }
}
