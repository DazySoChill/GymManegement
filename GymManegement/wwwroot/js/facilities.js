/**
 * Facilities Management Module
 */

let facilitiesCurrentPage = 1;
let facilitiesPageSize = 10;

async function renderFacilities(container) {
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Cơ Sở Vật Chất</h2>
                <button class="btn btn-primary" onclick="showCreateFacilityModal()">➕ Thêm cơ sở</button>
            </div>
            
            <div class="filters">
                <select id="facilityStatusFilter" onchange="loadFacilities()">
                    <option value="">Tất cả trạng thái</option>
                    <option value="Active">Active</option>
                    <option value="Maintenance">Maintenance</option>
                    <option value="Inactive">Inactive</option>
                </select>
                <button class="btn btn-info" onclick="loadFacilities()">🔍 Tìm</button>
            </div>
            
            <div class="table-container" id="facilitiesTableContainer"></div>
            <div id="facilitiesPagination" class="pagination"></div>
        </div>
    `;
    
    await loadFacilities();
}

async function loadFacilities() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Facility?pageNumber=${facilitiesCurrentPage}&pageSize=${facilitiesPageSize}`);
        hideLoading();
        
        renderFacilitiesTable(data);
        renderFacilitiesPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách cơ sở: ' + error.message);
    }
}

function renderFacilitiesTable(data) {
    const container = document.getElementById('facilitiesTableContainer');
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏢</div><div class="empty-state-text">Không có cơ sở nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Tên</th>
                    <th>Mô tả</th>
                    <th>Trạng thái</th>
                    <th>Thao tác</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(facility => {
        const statusClass = facility.status === 'Active' ? 'badge-success' :
                           facility.status === 'Maintenance' ? 'badge-warning' : 'badge-danger';
        html += `
            <tr>
                <td>${facility.facilityId}</td>
                <td>${escapeHtml(facility.name)}</td>
                <td>${escapeHtml(facility.description || '-')}</td>
                <td><span class="badge ${statusClass}">${facility.status}</span></td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-info" onclick="showEditFacilityModal(${facility.facilityId})">✏️</button>
                    </div>
                </td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderFacilitiesPagination(data) {
    const container = document.getElementById('facilitiesPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeFacilitiesPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeFacilitiesPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeFacilitiesPage(page) {
    facilitiesCurrentPage = page;
    loadFacilities();
}

function showCreateFacilityModal() {
    showError('Chức năng tạo cơ sở chưa được triển khai đầy đủ');
}

function showEditFacilityModal(id) {
    showError('Chức năng sửa cơ sở chưa được triển khai đầy đủ');
}
