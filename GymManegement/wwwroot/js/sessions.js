/**
 * Sessions Management Module
 */

let sessionsCurrentPage = 1;
let sessionsPageSize = 10;

// Member name cache to avoid duplicate API calls
const memberNameCache = {};

async function fetchMemberName(memberId) {
    if (memberNameCache[memberId]) {
        return memberNameCache[memberId];
    }
    
    try {
        const member = await apiFetch(`/api/Member/${memberId}`);
        const name = member?.fullName || member?.name || `Member ${memberId}`;
        memberNameCache[memberId] = name;
        return name;
    } catch (error) {
        console.error(`Error fetching member ${memberId}:`, error);
        memberNameCache[memberId] = `Member ${memberId}`;
        return memberNameCache[memberId];
    }
}

// Schedule details cache
const scheduleDetailsCache = {};

async function fetchScheduleDetails(scheduleId) {
    if (scheduleDetailsCache[scheduleId]) {
        return scheduleDetailsCache[scheduleId];
    }
    
    try {
        const schedule = await apiFetch(`/api/Schedule/${scheduleId}`);
        const details = {
            className: schedule?.className || '-',
            trainerName: schedule?.trainerName || '-',
            facilityName: schedule?.facilityName || '-',
            startTime: schedule?.startTime || null,
            endTime: schedule?.endTime || null
        };
        scheduleDetailsCache[scheduleId] = details;
        return details;
    } catch (error) {
        console.error(`Error fetching schedule ${scheduleId}:`, error);
        const fallback = { className: '-', trainerName: '-', facilityName: '-', startTime: null, endTime: null };
        scheduleDetailsCache[scheduleId] = fallback;
        return fallback;
    }
}

// Session notes - stored in localStorage
function getSessionNote(sessionId) {
    const key = `gym_session_note_${sessionId}`;
    return localStorage.getItem(key) || '';
}

function saveSessionNote(sessionId, note) {
    const key = `gym_session_note_${sessionId}`;
    if (note && note.trim()) {
        localStorage.setItem(key, note.trim());
    } else {
        localStorage.removeItem(key);
    }
}

function showNoteModal(sessionId) {
    const currentNote = getSessionNote(sessionId);
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Ghi Chú - Session #${sessionId}</h3>
            <textarea id="noteTextarea" style="width:100%;min-height:120px;padding:8px;border:1px solid #ddd;border-radius:6px;resize:vertical;">${escapeHtml(currentNote)}</textarea>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                <button class="btn btn-primary" onclick="saveNoteFromModal(${sessionId}); this.closest('.gym-modal-overlay').remove();">💾 Lưu</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Focus textarea
    setTimeout(() => document.getElementById('noteTextarea')?.focus(), 100);
}

function saveNoteFromModal(sessionId) {
    const note = document.getElementById('noteTextarea')?.value || '';
    saveSessionNote(sessionId, note);
    showToast('💾 Đã lưu ghi chú', 'success');
    reloadCurrentPage();
}

// Week calculation utilities
function getWeekBounds(dateInWeek) {
    const d = new Date(dateInWeek);
    const day = d.getDay(); // 0=Sunday, 1=Monday, ...
    const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust to Monday
    
    const monday = new Date(d.setDate(diff));
    monday.setHours(0, 0, 0, 0);
    
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);
    
    return { start: monday, end: sunday };
}

function getCurrentWeekBounds() {
    return getWeekBounds(new Date());
}

function getNextWeekBounds() {
    const nextWeek = new Date();
    nextWeek.setDate(nextWeek.getDate() + 7);
    return getWeekBounds(nextWeek);
}

function formatWeekRange(start, end) {
    return `${formatDate(start)} - ${formatDate(end)}`;
}

// Filter sessions by week
function filterSessionsByWeek(sessions, weekStart, weekEnd) {
    return sessions.filter(s => {
        const regDate = new Date(s.registrationDate);
        return regDate >= weekStart && regDate <= weekEnd;
    });
}

// Global week filter state
let currentWeekFilter = null; // null means no filter

function filterByWeek(type) {
    if (type === 'current') {
        currentWeekFilter = getCurrentWeekBounds();
    } else if (type === 'next') {
        currentWeekFilter = getNextWeekBounds();
    }
    
    const display = document.getElementById('weekFilterDisplay');
    if (display) {
        display.textContent = `Tuần: ${formatWeekRange(currentWeekFilter.start, currentWeekFilter.end)}`;
    }
    
    loadSessions();
}

function filterByCustomWeek() {
    const input = document.getElementById('customWeekInput');
    if (!input || !input.value) {
        showError('Vui lòng chọn tuần');
        return;
    }
    
    // input.value format: "YYYY-Www" (e.g., "2024-W15")
    const [year, week] = input.value.split('-W');
    const firstDayOfYear = new Date(parseInt(year), 0, 1);
    const daysOffset = (parseInt(week) - 1) * 7;
    const targetDate = new Date(firstDayOfYear.setDate(firstDayOfYear.getDate() + daysOffset));
    
    currentWeekFilter = getWeekBounds(targetDate);
    
    const display = document.getElementById('weekFilterDisplay');
    if (display) {
        display.textContent = `Tuần: ${formatWeekRange(currentWeekFilter.start, currentWeekFilter.end)}`;
    }
    
    loadSessions();
}

function clearWeekFilter() {
    currentWeekFilter = null;
    const display = document.getElementById('weekFilterDisplay');
    if (display) {
        display.textContent = '';
    }
    loadSessions();
}

// Member session week filter
let mySessionWeekFilter = null;

function filterMySessionsByWeek(type) {
    const memberId = getMemberId();
    if (!memberId) return;
    
    if (type === 'current') {
        mySessionWeekFilter = getCurrentWeekBounds();
    } else if (type === 'next') {
        mySessionWeekFilter = getNextWeekBounds();
    } else {
        mySessionWeekFilter = null;
    }
    
    const display = document.getElementById('myWeekFilterDisplay');
    if (display) {
        display.textContent = mySessionWeekFilter 
            ? `Tuần: ${formatWeekRange(mySessionWeekFilter.start, mySessionWeekFilter.end)}` 
            : '';
    }
    
    loadMemberSessionsData(memberId, mySessionWeekFilter);
}

async function renderSessions(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if (role === 'Member' && memberId) {
        await renderMemberSessions(container, memberId);
    } else {
        await renderAllSessions(container);
    }
}

async function renderMemberSessions(container, memberId) {
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Buổi Tập Của Tôi</h2>
                <button class="btn btn-primary" onclick="showRegisterSessionModal()">➕ Đăng ký lớp</button>
            </div>
            
            <div class="filters" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
                <button class="btn btn-info" onclick="filterMySessionsByWeek('current')">📅 Tuần Này</button>
                <button class="btn btn-info" onclick="filterMySessionsByWeek('next')">📅 Tuần Sau</button>
                <button class="btn btn-secondary" onclick="filterMySessionsByWeek('all')">✖️ Tất cả</button>
                <span id="myWeekFilterDisplay" style="margin-left:12px;color:#666;font-size:14px;"></span>
            </div>
            
            <div id="mySessionsContainer"></div>
        </div>
    `;
    
    await loadMemberSessionsData(memberId, null);
}

async function loadMemberSessionsData(memberId, weekFilter) {
    try {
        showLoading();
        let sessions = await apiFetch(`/api/Session/member/${memberId}`);
        hideLoading();
        
        if (weekFilter) {
            sessions = filterSessionsByWeek(sessions, weekFilter.start, weekFilter.end);
        }
        
        await renderMemberSessionsTable(sessions);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải buổi tập: ' + error.message);
    }
}

async function renderMemberSessionsTable(sessions) {
    const myContainer = document.getElementById('mySessionsContainer');
    
    if (!sessions || sessions.length === 0) {
        myContainer.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💪</div><div class="empty-state-text">Bạn chưa đăng ký buổi tập nào</div></div>';
        return;
    }
    
    // Fetch schedule details
    const scheduleIds = [...new Set(sessions.map(s => s.scheduleId))];
    await Promise.all(scheduleIds.map(id => fetchScheduleDetails(id)));
    
    let html = '<table><thead><tr><th>ID</th><th>Lớp</th><th>HLV</th><th>Thời gian tập</th><th>Ngày đăng ký</th><th>Trạng thái</th><th>Ghi chú</th></tr></thead><tbody>';
    
    for (const s of sessions) {
        const scheduleDetails = await fetchScheduleDetails(s.scheduleId);
        const note = getSessionNote(s.sessionId);
        const hasNote = note.length > 0;
        
        const scheduleTime = scheduleDetails.startTime 
            ? `${formatDateTime(scheduleDetails.startTime)} - ${formatDateTime(scheduleDetails.endTime)}` 
            : '-';
        
        const badge = s.status === 'Attended' ? 'badge-success' :
                     s.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
        
        html += `
            <tr>
                <td>${s.sessionId}</td>
                <td>${escapeHtml(scheduleDetails.className)}</td>
                <td>${escapeHtml(scheduleDetails.trainerName)}</td>
                <td>${scheduleTime}</td>
                <td>${formatDate(s.registrationDate)}</td>
                <td><span class="badge ${badge}">${s.status}</span></td>
                <td>
                    <button class="btn btn-sm ${hasNote ? 'btn-info' : 'btn-secondary'}" 
                            onclick="showNoteModal(${s.sessionId})"
                            title="${hasNote ? 'Xem/Sửa ghi chú' : 'Thêm ghi chú'}">
                        ${hasNote ? '📝' : '📄'}
                    </button>
                </td>
            </tr>
        `;
    }
    
    html += '</tbody></table>';
    myContainer.innerHTML = html;
}

async function renderAllSessions(container) {
    const role = getRole();
    const canManage = role === 'Admin' || role === 'Trainer';
    
    const currentWeek = getCurrentWeekBounds();
    const nextWeek = getNextWeekBounds();
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Buổi Tập</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showCreateSessionModal()">➕ Tạo session</button>' : ''}
            </div>
            
            <div class="filters" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
                <button class="btn btn-info" onclick="filterByWeek('current')">📅 Tuần Này</button>
                <button class="btn btn-info" onclick="filterByWeek('next')">📅 Tuần Sau</button>
                <input type="week" id="customWeekInput" style="padding:8px;border:1px solid #ddd;border-radius:6px;">
                <button class="btn btn-info" onclick="filterByCustomWeek()">🔍 Lọc tuần</button>
                <button class="btn btn-secondary" onclick="clearWeekFilter()">✖️ Xóa lọc</button>
                <span id="weekFilterDisplay" style="margin-left:12px;color:#666;font-size:14px;"></span>
            </div>
            
            <div class="table-container" id="sessionsTableContainer"></div>
            <div id="sessionsPagination" class="pagination"></div>
        </div>
    `;
    
    // Set default to current week
    filterByWeek('current');
}

async function loadSessions() {
    try {
        showLoading();
        
        // If week filter is active, fetch all sessions (pagination doesn't work well with client-side filtering)
        if (currentWeekFilter) {
            const allData = await apiFetch(`/api/Session?pageNumber=1&pageSize=1000`);
            const filtered = filterSessionsByWeek(allData.items || [], currentWeekFilter.start, currentWeekFilter.end);
            
            hideLoading();
            await renderSessionsTable({ items: filtered, pageNumber: 1, totalPages: 1 });
            renderSessionsPagination({ pageNumber: 1, totalPages: 1 });
        } else {
            const data = await apiFetch(`/api/Session?pageNumber=${sessionsCurrentPage}&pageSize=${sessionsPageSize}`);
            hideLoading();
            await renderSessionsTable(data);
            renderSessionsPagination(data);
        }
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách buổi tập: ' + error.message);
    }
}

async function renderSessionsTable(data) {
    const container = document.getElementById('sessionsTableContainer');
    const role = getRole();
    const canManage = role === 'Admin' || role === 'Trainer';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💪</div><div class="empty-state-text">Không có buổi tập nào</div></div>';
        return;
    }
    
    // Fetch all member names and schedule details in parallel
    const sessions = data.items;
    const memberIds = [...new Set(sessions.map(s => s.memberId))];
    const scheduleIds = [...new Set(sessions.map(s => s.scheduleId))];
    
    await Promise.all([
        ...memberIds.map(id => fetchMemberName(id)),
        ...scheduleIds.map(id => fetchScheduleDetails(id))
    ]);
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Member ID</th>
                    <th>Tên Member</th>
                    <th>Lớp</th>
                    <th>HLV</th>
                    <th>Thời gian tập</th>
                    <th>Ngày đăng ký</th>
                    <th>Trạng thái</th>
                    <th>Ghi chú</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    for (const s of sessions) {
        const memberName = await fetchMemberName(s.memberId);
        const scheduleDetails = await fetchScheduleDetails(s.scheduleId);
        const note = getSessionNote(s.sessionId);
        const hasNote = note.length > 0;
        
        const scheduleTime = scheduleDetails.startTime 
            ? `${formatDateTime(scheduleDetails.startTime)} - ${formatDateTime(scheduleDetails.endTime)}` 
            : '-';
        
        const badge = s.status === 'Attended' ? 'badge-success' :
                     s.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
        
        html += `
            <tr>
                <td>${s.sessionId}</td>
                <td>${s.memberId}</td>
                <td>${escapeHtml(memberName)}</td>
                <td>${escapeHtml(scheduleDetails.className)}</td>
                <td>${escapeHtml(scheduleDetails.trainerName)}</td>
                <td>${scheduleTime}</td>
                <td>${formatDate(s.registrationDate)}</td>
                <td><span class="badge ${badge}">${s.status}</span></td>
                <td>
                    <button class="btn btn-sm ${hasNote ? 'btn-info' : 'btn-secondary'}" 
                            onclick="showNoteModal(${s.sessionId})" 
                            title="${hasNote ? 'Xem/Sửa ghi chú' : 'Thêm ghi chú'}">
                        ${hasNote ? '📝' : '📄'}
                    </button>
                </td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-success" onclick="updateSessionStatus(${s.sessionId}, 'Attended')">✓</button>
                            <button class="btn btn-sm btn-danger" onclick="updateSessionStatus(${s.sessionId}, 'Cancelled')">✗</button>
                        </div>
                    </td>
                ` : ''}
            </tr>
        `;
    }
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderSessionsPagination(data) {
    const container = document.getElementById('sessionsPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeSessionsPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeSessionsPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeSessionsPage(page) {
    sessionsCurrentPage = page;
    loadSessions();
}

async function updateSessionStatus(sessionId, status) {
    try {
        showLoading();
        await apiFetch(`/api/Session/${sessionId}/status`, {
            method: 'PUT',
            body: JSON.stringify({ status })
        });
        hideLoading();
        showSuccess('Cập nhật trạng thái thành công');
        loadSessions();
    } catch (error) {
        hideLoading();
        showError('Lỗi cập nhật: ' + error.message);
    }
}

function showCreateSessionModal() {
    showError('Chức năng tạo session chưa được triển khai đầy đủ');
}

function showRegisterSessionModal() {
    showError('Chức năng đăng ký lớp chưa được triển khai đầy đủ');
}
