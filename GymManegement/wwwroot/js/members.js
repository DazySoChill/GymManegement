/**
 * Members Management Module
 */

let membersCurrentPage = 1;
let membersPageSize = 10;

async function renderMembers(container) {
    const role = getRole();
    const canManage = role === 'Admin';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Members</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showCreateMemberModal()">➕ Thêm Member</button>' : ''}
            </div>
            
            <div class="filters">
                <input type="text" id="memberSearch" placeholder="Tìm kiếm theo tên, email..." style="width: 300px;">
                <button class="btn btn-info" onclick="loadMembers()">🔍 Tìm</button>
            </div>
            
            <div class="table-container" id="membersTableContainer">
                <!-- Table will be loaded here -->
            </div>
            
            <div id="membersPagination" class="pagination"></div>
        </div>
    `;
    
    await loadMembers();
}

async function loadMembers() {
    const searchTerm = document.getElementById('memberSearch')?.value || '';
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Member?pageNumber=${membersCurrentPage}&pageSize=${membersPageSize}&searchTerm=${encodeURIComponent(searchTerm)}`);
        hideLoading();
        
        renderMembersTable(data);
        renderMembersPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách members: ' + error.message);
    }
}

function renderMembersTable(data) {
    const container = document.getElementById('membersTableContainer');
    const role = getRole();
    const canManage = role === 'Admin';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">👥</div><div class="empty-state-text">Không có member nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Họ tên</th>
                    <th>Email</th>
                    <th>SĐT</th>
                    <th>Ngày sinh</th>
                    <th>QR Code</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(member => {
        html += `
            <tr>
                <td>${member.memberId}</td>
                <td>${escapeHtml(member.fullName)}</td>
                <td>${escapeHtml(member.email)}</td>
                <td>${escapeHtml(member.phone || '-')}</td>
                <td>${formatDate(member.dateOfBirth)}</td>
                <td>${escapeHtml(member.qrCode)}</td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-info" onclick="showEditMemberModal(${member.memberId})">✏️</button>
                        </div>
                    </td>
                ` : ''}
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderMembersPagination(data) {
    const container = document.getElementById('membersPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeMembersPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeMembersPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeMembersPage(page) {
    membersCurrentPage = page;
    loadMembers();
}

function showCreateMemberModal() {
    showError('Chức năng tạo member chưa được triển khai đầy đủ');
}

function showEditMemberModal(memberId) {
    showError('Chức năng sửa member chưa được triển khai đầy đủ');
}
