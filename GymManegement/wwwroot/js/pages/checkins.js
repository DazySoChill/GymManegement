/* pages/checkins.js */
let checkinsCurrentPage = 1;
let checkinsPageSize = 10;
let checkinsTotalPages = 1;

async function loadCheckins(page = 1) {
  loading('checkins-tbody');
  checkinsCurrentPage = page;
  try {
    const user = getCurrentUser();
    let params = { pageNumber: page, pageSize: checkinsPageSize };
    
    // Members only see their own checkins
    if (isMember() && user.memberId) {
      params.memberId = user.memberId;
    }
    
    const res = await api.getCheckins(params);
    const data = res.data ?? [];
    const total = res.total ?? 0;
    checkinsTotalPages = Math.ceil(total / checkinsPageSize);

    const tbody = document.getElementById('checkins-tbody');
    if (!data.length) { emptyRow('checkins-tbody', 5); }
    else {
      tbody.innerHTML = data.map(c => `
        <tr>
          <td>${c.checkinId}</td>
          <td>${c.memberName || '—'}</td>
          <td>${c.sessionName || '—'}</td>
          <td>${datetimeFmt(c.checkinTime)}</td>
          <td><span class="badge badge-${c.method === 'QR' ? 'purple' : 'blue'}">${c.method || 'Manual'}</span></td>
        </tr>
      `).join('');
    }
    renderPagination('checkins-pagination', checkinsCurrentPage, checkinsTotalPages, loadCheckins);
  } catch (e) { console.error(e); emptyRow('checkins-tbody', 5, 'Lỗi tải dữ liệu'); }
}

function openManualCheckin() {
  document.getElementById('checkin-manual-form').reset();
  Promise.all([
    api.getMembers({ pageSize: 200 }).then(r => populateSelect('ci-member', r.data ?? [], 'memberId', 'fullName')),
    api.getSessions({ pageSize: 200 }).then(r => populateSelect('ci-session', r.data ?? [], 'sessionId', 'sessionId'))
  ]);
  openModal('modal-checkin-manual');
}

document.getElementById('checkin-manual-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = { memberId: parseInt(document.getElementById('ci-member').value), sessionId: parseInt(document.getElementById('ci-session').value), method: document.getElementById('ci-method').value };
  if (!body.memberId || !body.sessionId) return toast('Vui lòng chọn hội viên và session', 'warning');
  try { await api.checkinManual(body); toast('Check-in thành công', 'success'); closeModal('modal-checkin-manual'); loadCheckins(checkinsCurrentPage); }
  catch (err) { toast(err.message || 'Lỗi check-in', 'error'); }
});

function openQRCheckin() {
  document.getElementById('qr-form').reset();
  api.getSessions({ pageSize: 200 }).then(r => populateSelect('qr-session', r.data ?? [], 'sessionId', 'sessionId'));
  openModal('modal-qr-checkin');
}

document.getElementById('qr-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = { qrCodeValue: document.getElementById('qr-value').value.trim(), sessionId: parseInt(document.getElementById('qr-session').value) };
  if (!body.qrCodeValue || !body.sessionId) return toast('Vui lòng nhập QR và chọn session', 'warning');
  try { await api.checkinQR(body); toast('Check-in QR thành công', 'success'); closeModal('modal-qr-checkin'); loadCheckins(checkinsCurrentPage); }
  catch (err) { toast(err.message || 'Lỗi check-in', 'error'); }
});

function init_checkins() {
  // For members, hide manual checkin button, only show QR
  if (isMember()) {
    const manualBtn = document.querySelector('button[onclick="openManualCheckin()"]');
    if (manualBtn) manualBtn.style.display = 'none';
    
    // Change title
    const title = document.querySelector('#page-checkins .card h2');
    if (title) title.textContent = '✅ Lịch sử Check-in của bạn';
  }
  
  loadCheckins(1);
}
