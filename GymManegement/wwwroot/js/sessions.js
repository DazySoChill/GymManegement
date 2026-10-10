/**
 * Sessions Management Module
 */

let sessionsCurrentPage = 1;
let sessionsPageSize = 10;

// Member name cache to avoid duplicate API calls
// Cache stores { status: 'success' | 'error', value: string, timestamp: number }
const memberNameCache = {};

async function fetchMemberName(memberId) {
    const cached = memberNameCache[memberId];
    const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
    
    // Return cached success if still fresh
    if (cached && cached.status === 'success' && (Date.now() - cached.timestamp) < CACHE_TTL) {
        return cached.value;
    }
    
    // Retry transient failures after 30 seconds
    if (cached && cached.status === 'error' && (Date.now() - cached.timestamp) < 30000) {
        return cached.value;
    }
    
    try {
        const member = await apiFetch(`/api/Member/${memberId}`);
        const name = member?.fullName || member?.name || `Member ${memberId}`;
        memberNameCache[memberId] = { status: 'success', value: name, timestamp: Date.now() };
        return name;
    } catch (error) {
        console.error(`Error fetching member ${memberId}:`, error);
        const fallback = `Member ${memberId}`;
        // Cache error with timestamp to allow retry after delay
        memberNameCache[memberId] = { status: 'error', value: fallback, timestamp: Date.now() };
        return fallback;
    }
}

// Schedule details cache
// Cache stores { status: 'success' | 'error', value: object, timestamp: number }
const scheduleDetailsCache = {};

async function fetchScheduleDetails(scheduleId) {
    const cached = scheduleDetailsCache[scheduleId];
    const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
    
    // Return cached success if still fresh
    if (cached && cached.status === 'success' && (Date.now() - cached.timestamp) < CACHE_TTL) {
        return cached.value;
    }
    
    // Retry transient failures after 30 seconds
    if (cached && cached.status === 'error' && (Date.now() - cached.timestamp) < 30000) {
        return cached.value;
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
        scheduleDetailsCache[scheduleId] = { status: 'success', value: details, timestamp: Date.now() };
        return details;
    } catch (error) {
        console.error(`Error fetching schedule ${scheduleId}:`, error);
        const fallback = { className: '-', trainerName: '-', facilityName: '-', startTime: null, endTime: null };
        // Cache error with timestamp to allow retry after delay
        scheduleDetailsCache[scheduleId] = { status: 'error', value: fallback, timestamp: Date.now() };
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
    
    // Reload current view
    const role = getRole();
    const memberId = getMemberId();
    if (role === 'Member' && memberId) {
        loadMemberSessionsData(memberId, mySessionWeekFilter);
    } else {
        loadSessions();
    }
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
    const [yearStr, weekStr] = input.value.split('-W');
    const year = parseInt(yearStr);
    const week = parseInt(weekStr);
    
    // ISO 8601: Week 1 is the week with the first Thursday of the year
    // Find January 4th (always in week 1) and go back to Monday
    // NOTE: Edge case exists around January 1st where browser week picker
    // and manual calculation may disagree. Affects <1% of use cases.
    // If issues arise, consider replacing with date range picker.
    const jan4 = new Date(year, 0, 4); // January 4th
    const jan4Day = jan4.getDay(); // 0=Sunday, 1=Monday, ...
    const jan4ToMonday = jan4Day === 0 ? -6 : 1 - jan4Day; // Days back to Monday
    
    // Get Monday of week 1
    const week1Monday = new Date(year, 0, 4 + jan4ToMonday);
    
    // Add (week - 1) weeks to get target week's Monday
    const targetMonday = new Date(week1Monday);
    targetMonday.setDate(week1Monday.getDate() + (week - 1) * 7);
    
    currentWeekFilter = getWeekBounds(targetMonday);
    
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
                <h2 class="card-title">Đăng Ký Class</h2>
            </div>
            
            <!-- Available Classes to Register -->
            <div style="padding: 20px; border-bottom: 2px solid #e0e0e0;">
                <h3 style="margin: 0 0 16px 0; color: #2c3e50;">📚 Lớp Có Thể Đăng Ký</h3>
                <div id="availableClassesContainer">
                    <div style="text-align: center; padding: 20px;">
                        <div class="spinner"></div>
                    </div>
                </div>
            </div>
            
            <!-- My Registered Sessions -->
            <div style="padding: 20px;">
                <h3 style="margin: 0 0 16px 0; color: #2c3e50;">📝 Lớp Đã Đăng Ký</h3>
                <div class="filters" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;margin-bottom:16px;">
                    <button class="btn btn-sm btn-info" onclick="filterMySessionsByWeek('current')">📅 Tuần Này</button>
                    <button class="btn btn-sm btn-info" onclick="filterMySessionsByWeek('next')">📅 Tuần Sau</button>
                    <button class="btn btn-sm btn-secondary" onclick="filterMySessionsByWeek('all')">✖️ Tất cả</button>
                    <span id="myWeekFilterDisplay" style="margin-left:12px;color:#666;font-size:14px;"></span>
                </div>
                <div id="mySessionsContainer">
                    <div style="text-align: center; padding: 20px;">
                        <div class="spinner"></div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    await Promise.all([
        loadAvailableClasses(memberId),
        loadMemberSessionsData(memberId, null)
    ]);
}

// Load available classes that member can register
async function loadAvailableClasses(memberId) {
    const container = document.getElementById('availableClassesContainer');
    if (!container) return;
    
    try {
        showLoading();
        
        // Get all upcoming schedules
        console.log('[DEBUG] Fetching schedules...');
        const allSchedules = await apiFetch('/api/Schedule?pageNumber=1&pageSize=100');
        console.log('[DEBUG] Raw API response:', allSchedules);
        
        // Handle different response formats
        // API returns PagedResult<T> with structure: { data: [...], total, pageNumber, pageSize, totalPages }
        let schedulesList = [];
        if (Array.isArray(allSchedules)) {
            schedulesList = allSchedules;
            console.log('[DEBUG] Response is array');
        } else if (allSchedules && Array.isArray(allSchedules.data)) {
            schedulesList = allSchedules.data;
            console.log('[DEBUG] Response has data property (PagedResult format)');
        } else if (allSchedules && Array.isArray(allSchedules.items)) {
            schedulesList = allSchedules.items;
            console.log('[DEBUG] Response has items property');
        } else {
            console.error('[DEBUG] Unknown response format:', allSchedules);
            schedulesList = []; // Ensure it's an array
        }
        
        console.log('[DEBUG] Schedules list:', schedulesList);
        console.log('[DEBUG] Number of schedules:', schedulesList ? schedulesList.length : 0);
        
        const now = new Date();
        const upcomingSchedules = schedulesList.filter(s => {
            const startTime = new Date(s.startTime);
            const isFuture = startTime > now;
            console.log(`[DEBUG] Schedule ${s.scheduleId}: ${s.className}, StartTime: ${s.startTime}, IsFuture: ${isFuture}`);
            return isFuture;
        });
        
        console.log('[DEBUG] Upcoming schedules:', upcomingSchedules.length);
        
        // Get member's sessions to check what's already registered
        const memberSessions = await apiFetch(`/api/Session/member/${memberId}`);
        console.log('[DEBUG] Member sessions:', memberSessions);
        
        const registeredScheduleIds = memberSessions
            .filter(s => s.status !== 'Cancelled')
            .map(s => s.scheduleId);
        
        console.log('[DEBUG] Registered schedule IDs:', registeredScheduleIds);
        
        hideLoading();
        
        if (!upcomingSchedules || upcomingSchedules.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📚</div>
                    <div class="empty-state-text">Hiện không có lớp nào sắp diễn ra</div>
                </div>`;
            return;
        }
        
        // Sort by start time (nearest first)
        upcomingSchedules.sort((a, b) => new Date(a.startTime) - new Date(b.startTime));
        
        let html = '<div class="available-classes" style="display: grid; gap: 12px;">';
        
        upcomingSchedules.forEach(schedule => {
            const isRegistered = registeredScheduleIds.includes(schedule.scheduleId);
            const registeredSession = isRegistered ? memberSessions.find(s => s.scheduleId === schedule.scheduleId && s.status !== 'Cancelled') : null;
            
            html += `
                <div class="class-card" style="background: white; border: 1px solid #e0e0e0; border-radius: 6px; padding: 16px; display: flex; justify-content: space-between; align-items: center;">
                    <div style="flex: 1;">
                        <h4 style="margin: 0 0 8px 0; color: #2c3e50;">${escapeHtml(schedule.className)}</h4>
                        <div style="color: #666; font-size: 0.9em; line-height: 1.6;">
                            <div><strong>🏋️ HLV:</strong> ${escapeHtml(schedule.trainerName || '-')}</div>
                            <div><strong>📍 Phòng:</strong> ${escapeHtml(schedule.facilityName || '-')}</div>
                            <div><strong>🕐 Thời gian:</strong> ${formatDateTime(schedule.startTime)}</div>
                            <div><strong>👥 Sức chứa:</strong> ${schedule.maxCapacity} người</div>
                        </div>
                    </div>
                    <div style="margin-left: 16px;">
                        ${isRegistered 
                            ? `<button class="btn btn-sm btn-warning" onclick="quickUnregisterClass(${registeredSession.sessionId})" style="min-width: 100px;">❌ Hủy</button>`
                            : `<button class="btn btn-sm btn-success" onclick="quickRegisterClass(${schedule.scheduleId}, ${memberId})" style="min-width: 100px;">✅ Đăng Ký</button>`
                        }
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        container.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        console.error('[DEBUG] Error loading available classes:', error);
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">⚠️</div>
                <div class="empty-state-text">Lỗi tải danh sách lớp: ${error.message}</div>
            </div>`;
    }
}

// Quick register for a class (without modal)
async function quickRegisterClass(scheduleId, memberId) {
    if (!confirm('Bạn có chắc muốn đăng ký lớp này?')) {
        return;
    }
    
    try {
        showLoading();
        
        await apiFetch('/api/Session', {
            method: 'POST',
            body: JSON.stringify({
                scheduleId: scheduleId,
                memberId: memberId,
                status: 'Registered'
            })
        });
        
        hideLoading();
        showToast('✅ Đăng ký thành công! Vui lòng chờ duyệt.', 'success');
        
        // Reload both sections
        await Promise.all([
            loadAvailableClasses(memberId),
            loadMemberSessionsData(memberId, mySessionWeekFilter)
        ]);
        
    } catch (error) {
        hideLoading();
        
        if (error.message.includes('403') || error.message.includes('Forbidden')) {
            showError('Bạn không có quyền đăng ký. Vui lòng liên hệ Admin/Trainer.');
        } else if (error.message.includes('already') || error.message.includes('duplicate')) {
            showError('Bạn đã đăng ký lớp này rồi!');
        } else {
            showError('Lỗi đăng ký: ' + error.message);
        }
    }
}

// Quick unregister from a class
async function quickUnregisterClass(sessionId) {
    if (!confirm('Bạn có chắc muốn hủy đăng ký lớp này?')) {
        return;
    }
    
    try {
        showLoading();
        
        await apiFetch(`/api/Session/${sessionId}`, {
            method: 'PUT',
            body: JSON.stringify({
                status: 'Cancelled'
            })
        });
        
        hideLoading();
        showToast('✅ Đã hủy đăng ký!', 'success');
        
        // Reload both sections
        const memberId = getMemberId();
        if (memberId) {
            await Promise.all([
                loadAvailableClasses(memberId),
                loadMemberSessionsData(memberId, mySessionWeekFilter)
            ]);
        }
        
    } catch (error) {
        hideLoading();
        showError('Lỗi hủy: ' + error.message);
    }
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
    
    let html = '<table><thead><tr><th>ID</th><th>Lớp</th><th>HLV</th><th>Thời gian tập</th><th>Ngày đăng ký</th><th>Trạng thái</th><th>Ghi chú</th><th>Thao tác</th></tr></thead><tbody>';
    
    for (const s of sessions) {
        const scheduleDetails = await fetchScheduleDetails(s.scheduleId);
        const note = getSessionNote(s.sessionId);
        const hasNote = note.length > 0;
        
        const scheduleTime = scheduleDetails.startTime 
            ? `${formatDateTime(scheduleDetails.startTime)} - ${formatDateTime(scheduleDetails.endTime)}` 
            : '-';
        
        const badge = s.status === 'Attended' ? 'badge-success' :
                     s.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
        
        // Member can only cancel "Registered" sessions
        const canCancel = s.status === 'Registered';
        
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
                <td>
                    ${canCancel 
                        ? `<button class="btn btn-sm btn-danger" onclick="cancelMySession(${s.sessionId})" title="Hủy đăng ký">❌ Hủy</button>`
                        : '<span style="color:#999;">-</span>'
                    }
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
            const allData = await apiFetch(`/api/Session?pageNumber=1&pageSize=10000`);
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
                            <button class="btn btn-sm btn-info" onclick="showEditSessionModal(${s.sessionId})">✏️</button>
                            <button class="btn btn-sm btn-danger" onclick="deleteSession(${s.sessionId})">🗑️</button>
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
        
        // Use PUT /api/Session/{id} endpoint to update status
        // UpdateSessionRequest only requires Status field
        await apiFetch(`/api/Session/${sessionId}`, {
            method: 'PUT',
            body: JSON.stringify({
                status: status
            })
        });
        
        hideLoading();
        showToast('✅ Cập nhật trạng thái thành công', 'success');
        
        // Reload appropriate view
        const role = getRole();
        const memberId = getMemberId();
        if (role === 'Member' && memberId) {
            loadMemberSessionsData(memberId, mySessionWeekFilter);
        } else {
            loadSessions();
        }
    } catch (error) {
        hideLoading();
        showError('Lỗi cập nhật: ' + error.message);
    }
}

// Get session by ID (helper function) - NO LONGER NEEDED
// async function getSessionById(sessionId) {
//     try {
//         const response = await apiFetch(`/api/Session/${sessionId}`);
//         return response;
//     } catch (error) {
//         console.error('Error fetching session:', error);
//         return null;
//     }
// }

// Show modal for member to register for a class (create session)
async function showRegisterSessionModal() {
    const memberId = getMemberId();
    if (!memberId) {
        showError('Không tìm thấy thông tin member');
        return;
    }
    
    try {
        showLoading();
        
        // Fetch available schedules (upcoming only)
        const allSchedules = await apiFetch('/api/Schedule?pageNumber=1&pageSize=100');
        const now = new Date();
        const upcomingSchedules = allSchedules.items.filter(s => new Date(s.startTime) > now);
        
        hideLoading();
        
        if (upcomingSchedules.length === 0) {
            showError('Không có lớp học nào sắp tới');
            return;
        }
        
        // Create modal with schedule list
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal">
                <div class="gym-modal-header">
                    <h3>Đăng Ký Lớp Học</h3>
                    <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">✕</button>
                </div>
                <div class="gym-modal-body">
                    <form id="registerSessionForm">
                        <div class="form-group">
                            <label for="scheduleSelect">Chọn lớp học:</label>
                            <select id="scheduleSelect" name="scheduleId" required style="width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;">
                                <option value="">-- Chọn lớp --</option>
                                ${upcomingSchedules.map(s => `
                                    <option value="${s.scheduleId}">
                                        ${escapeHtml(s.className)} - ${escapeHtml(s.trainerName || 'N/A')} 
                                        (${formatDateTime(s.startTime)})
                                    </option>
                                `).join('')}
                            </select>
                        </div>
                        
                        <div class="gym-modal-actions">
                            <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                            <button type="submit" class="btn btn-primary">✅ Đăng Ký</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // Handle form submission
        document.getElementById('registerSessionForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            await submitSessionRegistration(memberId);
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách lớp: ' + error.message);
    }
}

// Submit session registration
async function submitSessionRegistration(memberId) {
    const form = document.getElementById('registerSessionForm');
    const scheduleId = parseInt(form.querySelector('#scheduleSelect').value);
    
    if (!scheduleId) {
        showError('Vui lòng chọn lớp học');
        return;
    }
    
    try {
        showLoading();
        
        // Create session with status "Registered"
        await apiFetch('/api/Session', {
            method: 'POST',
            body: JSON.stringify({
                scheduleId: scheduleId,
                memberId: memberId,
                status: 'Registered'
            })
        });
        
        hideLoading();
        showToast('✅ Đăng ký lớp học thành công! Vui lòng chờ Trainer/Admin duyệt.', 'success');
        
        // Close modal
        document.querySelector('.gym-modal-overlay').remove();
        
        // Reload member sessions
        await loadMemberSessionsData(memberId, mySessionWeekFilter);
        
    } catch (error) {
        hideLoading();
        
        // Handle specific errors
        if (error.message.includes('403') || error.message.includes('Forbidden')) {
            showError('Bạn không có quyền đăng ký lớp. Vui lòng liên hệ Admin/Trainer.');
        } else if (error.message.includes('already registered') || error.message.includes('duplicate')) {
            showError('Bạn đã đăng ký lớp này rồi!');
        } else {
            showError('Lỗi đăng ký lớp: ' + error.message);
        }
    }
}

// Member cancels their own session
async function cancelMySession(sessionId) {
    if (!confirm('Bạn có chắc muốn hủy đăng ký lớp này?')) {
        return;
    }
    
    await updateSessionStatus(sessionId, 'Cancelled');
}

// Admin/Trainer creates session for a member
async function showCreateSessionModal() {
    try {
        showLoading();
        
        // Fetch available schedules and members
        const [schedulesData, membersData] = await Promise.all([
            apiFetch('/api/Schedule?pageNumber=1&pageSize=100'),
            apiFetch('/api/Member?pageNumber=1&pageSize=100')
        ]);
        
        hideLoading();
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal">
                <div class="gym-modal-header">
                    <h3>Tạo Session Mới</h3>
                    <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">✕</button>
                </div>
                <div class="gym-modal-body">
                    <form id="createSessionForm">
                        <div class="form-group">
                            <label for="memberSelect">Member:</label>
                            <select id="memberSelect" name="memberId" required style="width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;">
                                <option value="">-- Chọn member --</option>
                                ${membersData.items.map(m => `
                                    <option value="${m.memberId}">
                                        ${escapeHtml(m.fullName || m.name || 'N/A')} (ID: ${m.memberId})
                                    </option>
                                `).join('')}
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label for="scheduleSelect2">Lớp học:</label>
                            <select id="scheduleSelect2" name="scheduleId" required style="width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;">
                                <option value="">-- Chọn lớp --</option>
                                ${schedulesData.items.map(s => `
                                    <option value="${s.scheduleId}">
                                        ${escapeHtml(s.className)} - ${escapeHtml(s.trainerName || 'N/A')} 
                                        (${formatDateTime(s.startTime)})
                                    </option>
                                `).join('')}
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label for="statusSelect">Trạng thái:</label>
                            <select id="statusSelect" name="status" required style="width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;">
                                <option value="Registered">Registered</option>
                                <option value="Attended">Attended</option>
                                <option value="Cancelled">Cancelled</option>
                            </select>
                        </div>
                        
                        <div class="gym-modal-actions">
                            <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                            <button type="submit" class="btn btn-primary">💾 Tạo</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // Handle form submission
        document.getElementById('createSessionForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            await submitCreateSession();
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

// Submit create session form
async function submitCreateSession() {
    const form = document.getElementById('createSessionForm');
    const memberId = parseInt(form.querySelector('#memberSelect').value);
    const scheduleId = parseInt(form.querySelector('#scheduleSelect2').value);
    const status = form.querySelector('#statusSelect').value;
    
    if (!memberId || !scheduleId || !status) {
        showError('Vui lòng điền đầy đủ thông tin');
        return;
    }
    
    try {
        showLoading();
        
        await apiFetch('/api/Session', {
            method: 'POST',
            body: JSON.stringify({
                scheduleId: scheduleId,
                memberId: memberId,
                status: status
            })
        });
        
        hideLoading();
        showToast('✅ Tạo session thành công!', 'success');
        
        // Close modal
        document.querySelector('.gym-modal-overlay').remove();
        
        // Reload sessions
        await loadSessions();
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tạo session: ' + error.message);
    }
}

// Admin/Trainer edits session status
async function showEditSessionModal(sessionId) {
    try {
        showLoading();
        const session = await apiFetch(`/api/Session/${sessionId}`);
        hideLoading();
        
        if (!session) {
            showError('Không tìm thấy session');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal">
                <div class="gym-modal-header">
                    <h3>Sửa Session #${sessionId}</h3>
                    <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">✕</button>
                </div>
                <div class="gym-modal-body">
                    <form id="editSessionForm">
                        <div class="form-group">
                            <label>Member ID:</label>
                            <input type="text" value="${session.memberId}" disabled style="width:100%;padding:8px;background:#f5f5f5;border:1px solid #ddd;border-radius:6px;">
                        </div>
                        
                        <div class="form-group">
                            <label>Schedule ID:</label>
                            <input type="text" value="${session.scheduleId}" disabled style="width:100%;padding:8px;background:#f5f5f5;border:1px solid #ddd;border-radius:6px;">
                        </div>
                        
                        <div class="form-group">
                            <label for="editStatusSelect">Trạng thái:</label>
                            <select id="editStatusSelect" name="status" required style="width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;">
                                <option value="Registered" ${session.status === 'Registered' ? 'selected' : ''}>Registered</option>
                                <option value="Attended" ${session.status === 'Attended' ? 'selected' : ''}>Attended</option>
                                <option value="Cancelled" ${session.status === 'Cancelled' ? 'selected' : ''}>Cancelled</option>
                            </select>
                        </div>
                        
                        <div class="gym-modal-actions">
                            <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                            <button type="submit" class="btn btn-primary">💾 Cập Nhật</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // Handle form submission
        document.getElementById('editSessionForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            await submitEditSession(sessionId);
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải session: ' + error.message);
    }
}

// Submit edit session form
async function submitEditSession(sessionId) {
    const form = document.getElementById('editSessionForm');
    const status = form.querySelector('#editStatusSelect').value;
    
    if (!status) {
        showError('Vui lòng chọn trạng thái');
        return;
    }
    
    try {
        showLoading();
        
        await apiFetch(`/api/Session/${sessionId}`, {
            method: 'PUT',
            body: JSON.stringify({
                status: status
            })
        });
        
        hideLoading();
        showToast('✅ Cập nhật session thành công!', 'success');
        
        // Close modal
        document.querySelector('.gym-modal-overlay').remove();
        
        // Reload sessions
        await loadSessions();
        
    } catch (error) {
        hideLoading();
        showError('Lỗi cập nhật session: ' + error.message);
    }
}

// Admin/Trainer deletes session
async function deleteSession(sessionId) {
    if (!confirm('Bạn có chắc chắn muốn xóa session này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Session/${sessionId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa session thành công!');
        await loadSessions();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa session: ' + error.message);
    }
}
