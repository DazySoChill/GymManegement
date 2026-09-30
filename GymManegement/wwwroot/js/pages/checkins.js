/* pages/checkins.js */
async function init_checkins() { loadCheckins(); }

async function loadCheckins() {
  loading('checkins-tbody');
  try {
    const list = await api.getCheckins();
    const tbody = document.getElementById('checkins-tbody');
    if (!list.length) { emptyRow('checkins-tbody', 5); return; }
    tbody.innerHTML = list.map(c => `
      <tr>
        <td>${c.checkinId}</td>
        <td>${c.memberName || c.memberId}</td>
        <td>${c.sessionId}</td>
        <td>${datetimeFmt(c.checkinTime)}</td>
        <td>${badge(c.checkinMethod, c.checkinMethod === 'QRCode' ? 'blue' : c.checkinMethod === 'Card' ? 'green' : 'gray')}</td>
      </tr>`).join('');
  } catch (e) { toast(e.message, 'error'); }
}

async function openManualCheckin() {
  await populateCheckinDropdowns();
  document.getElementById('checkin-manual-form').reset();
  openModal('modal-checkin-manual');
}

async function openQRCheckin() {
  await populateCheckinDropdowns();
  document.getElementById('qr-form').reset();
  openModal('modal-qr-checkin');
}

async function populateCheckinDropdowns() {
  try {
    const [members, sessions] = await Promise.all([api.getMembers(), api.getSessions()]);
    const scheduledSessions = sessions.filter(s => s.status === 'Scheduled');
    const memberOpts = members.map(m => `<option value="${m.memberId}">${m.fullName}</option>`).join('');
    const sessionOpts = scheduledSessions.map(s => `<option value="${s.sessionId}">Session #${s.sessionId} – ${dateFmt(s.sessionDate)}</option>`).join('');
    ['ci-member'].forEach(id => { const el = document.getElementById(id); if (el) el.innerHTML = memberOpts; });
    ['ci-session', 'qr-session'].forEach(id => { const el = document.getElementById(id); if (el) el.innerHTML = sessionOpts; });
  } catch (e) { console.error(e); }
}

document.getElementById('checkin-manual-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    memberId:      +document.getElementById('ci-member').value,
    sessionId:     +document.getElementById('ci-session').value,
    checkinTime:   new Date().toISOString(),
    checkinMethod: document.getElementById('ci-method').value
  };
  try { await api.checkinManual(body); toast('Check-in thành công!', 'success'); closeModal('modal-checkin-manual'); loadCheckins(); }
  catch (err) { toast(err.message, 'error'); }
});

document.getElementById('qr-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    qrCodeValue: document.getElementById('qr-value').value.trim(),
    sessionId:   +document.getElementById('qr-session').value
  };
  try {
    const res = await api.checkinQR(body);
    toast(res.message || 'OK', res.checkinId > 0 ? 'success' : 'error');
    if (res.checkinId > 0) { closeModal('modal-qr-checkin'); loadCheckins(); }
  } catch (err) { toast(err.message, 'error'); }
});
