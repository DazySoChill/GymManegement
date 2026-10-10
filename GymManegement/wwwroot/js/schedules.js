/**
 * Schedules Management Module
 */

let schedulesCurrentPage = 1;
let schedulesPageSize = 10;

// LocalStorage helpers for member schedule registration
function getMyScheduleIds(memberId) {
    const key = `memberSchedules_${memberId}`;
    const data = localStorage.getItem(key);
    return data ? JSON.parse(data) : [];
}

function saveMyScheduleIds(memberId, ids) {
    const key = `memberSchedules_${memberId}`;
    localStorage.setItem(key, JSON.stringify(ids));
}

async function registerSchedule(scheduleId) {
    const memberId = getMemberId();
    if (!memberId) {
        showError('Không tìm thấy thông tin member');
        return;
    }
    
    let ids = getMyScheduleIds(memberId);
    if (ids.includes(scheduleId)) {
        showToast('Lịch này đã được đăng ký rồi', 'warning');
        return;
    }
    
    ids.push(scheduleId);
    saveMyScheduleIds(memberId, ids);
    showToast('✅ Đã đăng ký lịch tập!', 'success');
    reloadCurrentPage();
}

async function cancelSchedule(scheduleId) {
    if (!confirm('Bạn có chắc muốn hủy lịch này?')) {
        return;
    }
    
    const memberId = getMemberId();
    if (!memberId) {
        showError('Không tìm thấy thông tin member');
        return;
    }
    
    let ids = getMyScheduleIds(memberId);
    ids = ids.filter(id => id !== scheduleId);
    saveMyScheduleIds(memberId, ids);
    showToast('🗑️ Đã hủy lịch tập', 'success');
    reloadCurrentPage();
}

async function renderMySchedules(container, memberId) {
    const scheduleIds = getMyScheduleIds(memberId);
    
    if (scheduleIds.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-text">Chưa có lịch nào được đăng ký</div></div>';
        return;
    }
    
    try {
        showLoading();
        const allSchedules = await apiFetch('/api/Schedule?pageNumber=1&pageSize=1000');
        hideLoading();
        
        const mySchedules = allSchedules.items.filter(s => scheduleIds.includes(s.scheduleId));
        
        if (mySchedules.length === 0) {
            container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-text">Chưa có lịch nào được đăng ký</div></div>';
            return;
        }
        
        let html = `
            <table>
                <thead>
                    <tr>
                        <th>Lớp</th>
                        <th>HLV</th>
                        <th>Phòng</th>
                        <th>Bắt đầu</th>
                        <th>Kết thúc</th>
                        <th>Thao tác</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        mySchedules.forEach(schedule => {
            html += `
                <tr>
                    <td>${escapeHtml(schedule.className)}</td>
                    <td>${escapeHtml(schedule.trainerName || '-')}</td>
                    <td>${escapeHtml(schedule.facilityName || '-')}</td>
                    <td>${formatDateTime(schedule.startTime)}</td>
                    <td>${formatDateTime(schedule.endTime)}</td>
                    <td>
                        <button class="btn btn-sm btn-danger" onclick="cancelSchedule(${schedule.scheduleId})">🗑️ Hủy</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        container.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch của tôi: ' + error.message);
    }
}

async function renderSchedules(container) {
    const role = getRole();
    const memberId = getMemberId();
    const canManage = role === 'Admin' || role === 'Trainer';
    
    if (role === 'Member') {
        // Member view - show available schedules + my schedules
        container.innerHTML = `
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <h2 class="card-title">Lịch Tập Có Sẵn</h2>
                </div>
                
                <div class="filters">
                    <input type="date" id="scheduleDate" onchange="loadSchedulesByDate()">
                    <button class="btn btn-info" onclick="loadSchedules()">🔍 Tất cả</button>
                </div>
                
                <div class="table-container" id="schedulesTableContainer"></div>
                <div id="schedulesPagination" class="pagination"></div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <h2 class="card-title">Lịch Của Tôi</h2>
                </div>
                <div id="mySchedulesContainer"></div>
            </div>
        `;
        
        await loadSchedules();
        await renderMySchedules(document.getElementById('mySchedulesContainer'), memberId);
        
    } else {
        // Admin/Trainer view
        container.innerHTML = `
            <div class="card">
                <div class="card-header">
                    <h2 class="card-title">Lịch Tập</h2>
                    ${canManage ? '<button class="btn btn-primary" onclick="showCreateScheduleModal()">➕ Thêm lịch</button>' : ''}
                </div>
                
                <div class="filters">
                    <input type="date" id="scheduleDate" onchange="loadSchedulesByDate()">
                    <button class="btn btn-info" onclick="loadSchedules()">🔍 Tất cả</button>
                </div>
                
                <div class="table-container" id="schedulesTableContainer"></div>
                <div id="schedulesPagination" class="pagination"></div>
            </div>
        `;
        
        await loadSchedules();
    }
}

async function loadSchedules() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Schedule?pageNumber=${schedulesCurrentPage}&pageSize=${schedulesPageSize}`);
        hideLoading();
        
        renderSchedulesTable(data);
        renderSchedulesPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch tập: ' + error.message);
    }
}

async function loadSchedulesByDate() {
    const dateInput = document.getElementById('scheduleDate');
    const date = dateInput.value;
    
    if (!date) {
        loadSchedules();
        return;
    }
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Schedule/date/${date}`);
        hideLoading();
        
        renderSchedulesTable({ items: data, pageNumber: 1, totalPages: 1 });
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch tập: ' + error.message);
    }
}

function renderSchedulesTable(data) {
    const container = document.getElementById('schedulesTableContainer');
    const role = getRole();
    const memberId = getMemberId();
    const canManage = role === 'Admin' || role === 'Trainer';
    const isMember = role === 'Member';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-text">Không có lịch tập nào</div></div>';
        return;
    }
    
    const registeredIds = isMember ? getMyScheduleIds(memberId) : [];
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Lớp</th>
                    <th>HLV</th>
                    <th>Phòng</th>
                    <th>Bắt đầu</th>
                    <th>Kết thúc</th>
                    <th>Sức chứa</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                    ${isMember ? '<th>Đăng Ký</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(schedule => {
        const isRegistered = registeredIds.includes(schedule.scheduleId);
        
        html += `
            <tr>
                <td>${schedule.scheduleId}</td>
                <td>${escapeHtml(schedule.className)}</td>
                <td>${escapeHtml(schedule.trainerName || '-')}</td>
                <td>${escapeHtml(schedule.facilityName || '-')}</td>
                <td>${formatDateTime(schedule.startTime)}</td>
                <td>${formatDateTime(schedule.endTime)}</td>
                <td>${schedule.maxCapacity}</td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-info" onclick="showEditScheduleModal(${schedule.scheduleId})">✏️</button>
                        </div>
                    </td>
                ` : ''}
                ${isMember ? `
                    <td>
                        ${isRegistered 
                            ? '<button class="btn btn-sm btn-secondary" disabled>✅ Đã đăng ký</button>'
                            : `<button class="btn btn-sm btn-success" onclick="registerSchedule(${schedule.scheduleId})">📌 Đăng Ký</button>`
                        }
                    </td>
                ` : ''}
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderSchedulesPagination(data) {
    const container = document.getElementById('schedulesPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeSchedulesPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeSchedulesPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeSchedulesPage(page) {
    schedulesCurrentPage = page;
    loadSchedules();
}

function showCreateScheduleModal() {
    showError('Chức năng tạo lịch chưa được triển khai đầy đủ');
}

function showEditScheduleModal(id) {
    showError('Chức năng sửa lịch chưa được triển khai đầy đủ');
}
