/**
 * Trainers Management Module
 */

let trainersCurrentPage = 1;
let trainersPageSize = 10;

async function renderTrainers(container) {
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Huấn Luyện Viên</h2>
                <button class="btn btn-primary" onclick="showCreateTrainerModal()">➕ Thêm HLV</button>
            </div>
            
            <div class="filters">
                <input type="text" id="trainerSearch" placeholder="Tìm kiếm..." style="width: 300px;">
                <button class="btn btn-info" onclick="loadTrainers()">🔍 Tìm</button>
            </div>
            
            <div class="table-container" id="trainersTableContainer"></div>
            <div id="trainersPagination" class="pagination"></div>
        </div>
    `;
    
    await loadTrainers();
}

async function loadTrainers() {
    const searchTerm = document.getElementById('trainerSearch')?.value || '';
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Trainer?pageNumber=${trainersCurrentPage}&pageSize=${trainersPageSize}&searchTerm=${encodeURIComponent(searchTerm)}`);
        hideLoading();
        
        renderTrainersTable(data);
        renderTrainersPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách HLV: ' + error.message);
    }
}

function renderTrainersTable(data) {
    const container = document.getElementById('trainersTableContainer');
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏋️</div><div class="empty-state-text">Không có HLV nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Họ tên</th>
                    <th>SĐT</th>
                    <th>Email</th>
                    <th>Chuyên môn</th>
                    <th>Thao tác</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(trainer => {
        html += `
            <tr>
                <td>${trainer.trainerId}</td>
                <td>${escapeHtml(trainer.fullName)}</td>
                <td>${escapeHtml(trainer.phone || '-')}</td>
                <td>${escapeHtml(trainer.email)}</td>
                <td>${escapeHtml(trainer.specialization || '-')}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-info" onclick="showEditTrainerModal(${trainer.trainerId})">✏️</button>
                    </div>
                </td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderTrainersPagination(data) {
    const container = document.getElementById('trainersPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeTrainersPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeTrainersPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeTrainersPage(page) {
    trainersCurrentPage = page;
    loadTrainers();
}

function showCreateTrainerModal() {
    showError('Chức năng tạo HLV chưa được triển khai đầy đủ');
}

function showEditTrainerModal(id) {
    showError('Chức năng sửa HLV chưa được triển khai đầy đủ');
}
