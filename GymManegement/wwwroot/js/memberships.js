/**
 * Memberships Management Module
 */

let membershipsCurrentPage = 1;
let membershipsPageSize = 10;

async function renderMemberships(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if (role === 'Member' && memberId) {
        // Member view - show only own memberships
        await renderMemberMemberships(container, memberId);
    } else {
        // Admin/Trainer view - show all memberships
        await renderAllMemberships(container);
    }
}

async function renderMemberMemberships(container, memberId) {
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Gói Tập Của Tôi</h2>
            </div>
            <div id="myMembershipsContainer"></div>
        </div>
    `;
    
    try {
        showLoading();
        const memberships = await apiFetch(`/api/Membership/member/${memberId}`);
        hideLoading();
        
        const myContainer = document.getElementById('myMembershipsContainer');
        if (!memberships || memberships.length === 0) {
            myContainer.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🎫</div><div class="empty-state-text">Bạn chưa có gói tập nào</div></div>';
            return;
        }
        
        let html = '<table><thead><tr><th>Gói</th><th>Giá</th><th>Ngày bắt đầu</th><th>Ngày kết thúc</th><th>Còn lại</th></tr></thead><tbody>';
        
        memberships.forEach(m => {
            const daysClass = m.daysRemaining < 7 ? 'badge-danger' : m.daysRemaining < 30 ? 'badge-warning' : 'badge-success';
            html += `
                <tr>
                    <td>${escapeHtml(m.packageName)}</td>
                    <td>${formatCurrency(m.price)}</td>
                    <td>${formatDate(m.startDate)}</td>
                    <td>${formatDate(m.endDate)}</td>
                    <td><span class="badge ${daysClass}">${m.daysRemaining} ngày</span></td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        myContainer.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải gói tập: ' + error.message);
    }
}

async function renderAllMemberships(container) {
    const role = getRole();
    const canManage = role === 'Admin';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Gói Tập</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showCreateMembershipModal()">➕ Thêm gói tập</button>' : ''}
            </div>
            
            <div class="filters">
                <input type="text" id="membershipSearch" placeholder="Tìm kiếm..." style="width: 300px;">
                <button class="btn btn-info" onclick="loadMemberships()">🔍 Tìm</button>
            </div>
            
            <div class="table-container" id="membershipsTableContainer"></div>
            <div id="membershipsPagination" class="pagination"></div>
        </div>
    `;
    
    await loadMemberships();
}

async function loadMemberships() {
    const searchTerm = document.getElementById('membershipSearch')?.value || '';
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Membership?pageNumber=${membershipsCurrentPage}&pageSize=${membershipsPageSize}&searchTerm=${encodeURIComponent(searchTerm)}`);
        hideLoading();
        
        renderMembershipsTable(data);
        renderMembershipsPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách gói tập: ' + error.message);
    }
}

function renderMembershipsTable(data) {
    const container = document.getElementById('membershipsTableContainer');
    const role = getRole();
    const canManage = role === 'Admin';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🎫</div><div class="empty-state-text">Không có gói tập nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Member ID</th>
                    <th>Gói</th>
                    <th>Giá</th>
                    <th>Ngày bắt đầu</th>
                    <th>Ngày kết thúc</th>
                    <th>Còn lại</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(m => {
        const daysClass = m.daysRemaining < 7 ? 'badge-danger' : m.daysRemaining < 30 ? 'badge-warning' : 'badge-success';
        html += `
            <tr>
                <td>${m.membershipId}</td>
                <td>${m.memberId}</td>
                <td>${escapeHtml(m.packageName)}</td>
                <td>${formatCurrency(m.price)}</td>
                <td>${formatDate(m.startDate)}</td>
                <td>${formatDate(m.endDate)}</td>
                <td><span class="badge ${daysClass}">${m.daysRemaining} ngày</span></td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-info" onclick="showEditMembershipModal(${m.membershipId})">✏️</button>
                        </div>
                    </td>
                ` : ''}
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderMembershipsPagination(data) {
    const container = document.getElementById('membershipsPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeMembershipsPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeMembershipsPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeMembershipsPage(page) {
    membershipsCurrentPage = page;
    loadMemberships();
}

function showCreateMembershipModal() {
    showError('Chức năng tạo gói tập chưa được triển khai đầy đủ');
}

function showEditMembershipModal(id) {
    showError('Chức năng sửa gói tập chưa được triển khai đầy đủ');
}
