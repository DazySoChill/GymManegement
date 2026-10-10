/**
 * Sessions Management Module
 */

let sessionsCurrentPage = 1;
let sessionsPageSize = 10;

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
            <div id="mySessionsContainer"></div>
        </div>
    `;
    
    try {
        showLoading();
        const sessions = await apiFetch(`/api/Session/member/${memberId}`);
        hideLoading();
        
        const myContainer = document.getElementById('mySessionsContainer');
        if (!sessions || sessions.length === 0) {
            myContainer.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💪</div><div class="empty-state-text">Bạn chưa đăng ký buổi tập nào</div></div>';
            return;
        }
        
        let html = '<table><thead><tr><th>ID</th><th>Lịch</th><th>Ngày đăng ký</th><th>Trạng thái</th></tr></thead><tbody>';
        
        sessions.forEach(s => {
            const badge = s.status === 'Attended' ? 'badge-success' :
                         s.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
            html += `
                <tr>
                    <td>${s.sessionId}</td>
                    <td>Schedule #${s.scheduleId}</td>
                    <td>${formatDate(s.registrationDate)}</td>
                    <td><span class="badge ${badge}">${s.status}</span></td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        myContainer.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải buổi tập: ' + error.message);
    }
}

async function renderAllSessions(container) {
    const role = getRole();
    const canManage = role === 'Admin' || role === 'Trainer';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Buổi Tập</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showCreateSessionModal()">➕ Tạo session</button>' : ''}
            </div>
            
            <div class="table-container" id="sessionsTableContainer"></div>
            <div id="sessionsPagination" class="pagination"></div>
        </div>
    `;
    
    await loadSessions();
}

async function loadSessions() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Session?pageNumber=${sessionsCurrentPage}&pageSize=${sessionsPageSize}`);
        hideLoading();
        
        renderSessionsTable(data);
        renderSessionsPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách buổi tập: ' + error.message);
    }
}

function renderSessionsTable(data) {
    const container = document.getElementById('sessionsTableContainer');
    const role = getRole();
    const canManage = role === 'Admin' || role === 'Trainer';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💪</div><div class="empty-state-text">Không có buổi tập nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Member ID</th>
                    <th>Schedule ID</th>
                    <th>Ngày đăng ký</th>
                    <th>Trạng thái</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(s => {
        const badge = s.status === 'Attended' ? 'badge-success' :
                     s.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
        html += `
            <tr>
                <td>${s.sessionId}</td>
                <td>${s.memberId}</td>
                <td>${s.scheduleId}</td>
                <td>${formatDate(s.registrationDate)}</td>
                <td><span class="badge ${badge}">${s.status}</span></td>
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
    });
    
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
