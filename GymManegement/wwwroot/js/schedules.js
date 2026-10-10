/**
 * Schedules Management Module
 */

let schedulesCurrentPage = 1;
let schedulesPageSize = 10;

async function renderSchedules(container) {
    const role = getRole();
    const canManage = role === 'Admin' || role === 'Trainer';
    
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
    const canManage = role === 'Admin' || role === 'Trainer';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-text">Không có lịch tập nào</div></div>';
        return;
    }
    
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
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(schedule => {
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
