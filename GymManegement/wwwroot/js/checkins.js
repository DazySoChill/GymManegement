/**
 * Check-ins Management Module
 */

let checkinsCurrentPage = 1;
let checkinsPageSize = 10;

async function renderCheckins(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if (role === 'Member' && memberId) {
        await renderMemberCheckins(container, memberId);
    } else {
        await renderAllCheckins(container);
    }
}

async function renderMemberCheckins(container, memberId) {
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Lịch Sử Check-in</h2>
            </div>
            
            <div class="filters">
                <input type="date" id="checkinFromDate">
                <input type="date" id="checkinToDate">
                <button class="btn btn-info" onclick="loadMemberCheckinsByDateRange(${memberId})">🔍 Lọc</button>
            </div>
            
            <div id="myCheckinsContainer"></div>
        </div>
    `;
    
    try {
        showLoading();
        const checkins = await apiFetch(`/api/Checkin/member/${memberId}`);
        hideLoading();
        
        renderMemberCheckinsTable(checkins);
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch sử check-in: ' + error.message);
    }
}

function renderMemberCheckinsTable(checkins) {
    const container = document.getElementById('myCheckinsContainer');
    
    if (!checkins || checkins.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><div class="empty-state-text">Chưa có check-in nào</div></div>';
        return;
    }
    
    let html = '<table><thead><tr><th>ID</th><th>Thời gian vào</th><th>Thời gian ra</th></tr></thead><tbody>';
    
    checkins.forEach(c => {
        html += `
            <tr>
                <td>${c.checkinId}</td>
                <td>${formatDateTime(c.checkinTime)}</td>
                <td>${c.checkoutTime ? formatDateTime(c.checkoutTime) : 'Chưa ra'}</td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

async function renderAllCheckins(container) {
    const role = getRole();
    const canManage = role === 'Admin' || role === 'Trainer';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Check-in</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showManualCheckinModal()">➕ Check-in thủ công</button>' : ''}
            </div>
            
            <div class="filters">
                <input type="date" id="checkinDate" onchange="loadCheckinsByDate()">
                <button class="btn btn-info" onclick="loadCheckins()">🔍 Tất cả</button>
            </div>
            
            <div class="table-container" id="checkinsTableContainer"></div>
            <div id="checkinsPagination" class="pagination"></div>
        </div>
    `;
    
    await loadCheckins();
}

async function loadCheckins() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Checkin?pageNumber=${checkinsCurrentPage}&pageSize=${checkinsPageSize}`);
        hideLoading();
        
        renderCheckinsTable(data);
        renderCheckinsPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách check-in: ' + error.message);
    }
}

async function loadCheckinsByDate() {
    const dateInput = document.getElementById('checkinDate');
    const date = dateInput.value;
    
    if (!date) {
        loadCheckins();
        return;
    }
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Checkin/date/${date}`);
        hideLoading();
        
        renderCheckinsTable({ items: data, pageNumber: 1, totalPages: 1 });
    } catch (error) {
        hideLoading();
        showError('Lỗi tải check-in: ' + error.message);
    }
}

function renderCheckinsTable(data) {
    const container = document.getElementById('checkinsTableContainer');
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><div class="empty-state-text">Không có check-in nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Member</th>
                    <th>Thời gian vào</th>
                    <th>Thời gian ra</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(c => {
        html += `
            <tr>
                <td>${c.checkinId}</td>
                <td>${escapeHtml(c.memberName || '-')}</td>
                <td>${formatDateTime(c.checkinTime)}</td>
                <td>${c.checkoutTime ? formatDateTime(c.checkoutTime) : 'Chưa ra'}</td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderCheckinsPagination(data) {
    const container = document.getElementById('checkinsPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeCheckinsPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeCheckinsPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeCheckinsPage(page) {
    checkinsCurrentPage = page;
    loadCheckins();
}

async function loadMemberCheckinsByDateRange(memberId) {
    const from = document.getElementById('checkinFromDate').value;
    const to = document.getElementById('checkinToDate').value;
    
    if (!from || !to) {
        showError('Vui lòng chọn ngày bắt đầu và kết thúc');
        return;
    }
    
    try {
        showLoading();
        const checkins = await apiFetch(`/api/Checkin/date-range?from=${from}&to=${to}`);
        hideLoading();
        
        // Filter by member
        const filtered = checkins.filter(c => c.memberId === memberId);
        renderMemberCheckinsTable(filtered);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải check-in: ' + error.message);
    }
}

function showManualCheckinModal() {
    showError('Chức năng check-in thủ công chưa được triển khai đầy đủ');
}
