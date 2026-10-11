/**
 * Facilities Management Module
 */

let facilitiesCurrentPage = 1;
let facilitiesPageSize = 10;

// Inject modal styles once
function injectFacilityModalStyles() {
    if (document.getElementById('facility-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'facility-modal-styles';
    style.textContent = `
        .gym-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .gym-modal {
            background: white;
            border-radius: 12px;
            padding: 32px;
            max-width: 500px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
        }
        .gym-modal h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: #2c3e50;
        }
        .gym-modal-close {
            position: absolute;
            top: 16px;
            right: 16px;
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #999;
        }
        .gym-modal-close:hover {
            color: #333;
        }
        .form-group {
            margin-bottom: 16px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #3498db;
        }
        .form-group .error {
            color: #e74c3c;
            font-size: 12px;
            margin-top: 4px;
        }
        .form-group input.invalid,
        .form-group textarea.invalid,
        .form-group select.invalid {
            border-color: #e74c3c;
        }
        .gym-modal-buttons {
            display: flex;
            gap: 12px;
            margin-top: 24px;
            justify-content: flex-end;
        }
        .required {
            color: #e74c3c;
        }
    `;
    document.head.appendChild(style);
}

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
    injectFacilityModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal" style="position: relative;">
            <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
            <h3>➕ Thêm Cơ Sở Vật Chất</h3>
            <form id="createFacilityForm">
                <div class="form-group">
                    <label>Tên cơ sở <span class="required">*</span></label>
                    <input type="text" id="facilityName" name="name" required maxlength="100">
                    <div class="error" id="nameError"></div>
                </div>
                <div class="form-group">
                    <label>Mô tả</label>
                    <textarea id="facilityDescription" name="description" rows="3" maxlength="500"></textarea>
                    <div class="error" id="descriptionError"></div>
                </div>
                <div class="form-group">
                    <label>Trạng thái <span class="required">*</span></label>
                    <select id="facilityStatus" name="status" required>
                        <option value="Active" selected>Active</option>
                        <option value="Maintenance">Maintenance</option>
                        <option value="Inactive">Inactive</option>
                    </select>
                    <div class="error" id="statusError"></div>
                </div>
                <div class="gym-modal-buttons">
                    <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                    <button type="submit" class="btn btn-primary">Tạo Cơ Sở</button>
                </div>
            </form>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Add blur validation for name field
    const nameInput = document.getElementById('facilityName');
    nameInput.addEventListener('blur', () => {
        const nameError = document.getElementById('nameError');
        nameError.textContent = '';
        nameInput.classList.remove('invalid');
        
        if (!nameInput.value.trim()) {
            nameError.textContent = 'Vui lòng nhập tên cơ sở';
            nameInput.classList.add('invalid');
        } else if (nameInput.value.trim().length < 3) {
            nameError.textContent = 'Tên cơ sở phải có ít nhất 3 ký tự';
            nameInput.classList.add('invalid');
        }
    });
    
    // Form submit handler
    const form = document.getElementById('createFacilityForm');
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Validate form
        if (!validateFacilityForm()) {
            return;
        }
        
        // Gather data
        const formData = {
            name: document.getElementById('facilityName').value.trim(),
            description: document.getElementById('facilityDescription').value.trim() || null,
            status: document.getElementById('facilityStatus').value
        };
        
        try {
            showLoading();
            await apiFetch('/api/Facility', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });
            hideLoading();
            showSuccess('Tạo cơ sở thành công!');
            modal.remove();
            await loadFacilities();
        } catch (error) {
            hideLoading();
            showError('Lỗi tạo cơ sở: ' + error.message);
        }
    });
}

async function showEditFacilityModal(facilityId) {
    injectFacilityModalStyles();
    
    try {
        showLoading();
        const facility = await apiFetch(`/api/Facility/${facilityId}`);
        hideLoading();
        
        if (!facility) {
            showError('Không tìm thấy cơ sở');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>✏️ Sửa Thông Tin Cơ Sở</h3>
                <form id="editFacilityForm">
                    <div class="form-group">
                        <label>Tên cơ sở <span class="required">*</span></label>
                        <input type="text" id="editFacilityName" name="name" value="${escapeHtml(facility.name)}" required maxlength="100">
                        <div class="error" id="editNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>Mô tả</label>
                        <textarea id="editFacilityDescription" name="description" rows="3" maxlength="500">${escapeHtml(facility.description || '')}</textarea>
                        <div class="error" id="editDescriptionError"></div>
                    </div>
                    <div class="form-group">
                        <label>Trạng thái <span class="required">*</span></label>
                        <select id="editFacilityStatus" name="status" required>
                            <option value="Active" ${facility.status === 'Active' ? 'selected' : ''}>Active</option>
                            <option value="Maintenance" ${facility.status === 'Maintenance' ? 'selected' : ''}>Maintenance</option>
                            <option value="Inactive" ${facility.status === 'Inactive' ? 'selected' : ''}>Inactive</option>
                        </select>
                        <div class="error" id="editStatusError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                        <button type="submit" class="btn btn-primary">Cập Nhật</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Form submit handler
        const form = document.getElementById('editFacilityForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            // Validate form
            if (!validateFacilityForm(true)) {
                return;
            }
            
            // Gather data
            const formData = {
                name: document.getElementById('editFacilityName').value.trim(),
                description: document.getElementById('editFacilityDescription').value.trim() || null,
                status: document.getElementById('editFacilityStatus').value
            };
            
            try {
                showLoading();
                await apiFetch(`/api/Facility/${facilityId}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Cập nhật cơ sở thành công!');
                modal.remove();
                await loadFacilities();
            } catch (error) {
                hideLoading();
                showError('Lỗi cập nhật cơ sở: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải thông tin cơ sở: ' + error.message);
    }
}

function validateFacilityForm(isEdit = false) {
    const prefix = isEdit ? 'edit' : '';
    const nameInputId = isEdit ? 'editFacilityName' : 'facilityName';
    const statusInputId = isEdit ? 'editFacilityStatus' : 'facilityStatus';
    const nameErrorId = isEdit ? 'editNameError' : 'nameError';
    const statusErrorId = isEdit ? 'editStatusError' : 'statusError';
    
    const nameInput = document.getElementById(nameInputId);
    const statusInput = document.getElementById(statusInputId);
    const nameError = document.getElementById(nameErrorId);
    const statusError = document.getElementById(statusErrorId);
    
    let isValid = true;
    
    // Clear previous errors
    nameError.textContent = '';
    statusError.textContent = '';
    nameInput.classList.remove('invalid');
    statusInput.classList.remove('invalid');
    
    // Validate name
    const nameValue = nameInput.value.trim();
    if (!nameValue) {
        nameError.textContent = 'Vui lòng nhập tên cơ sở';
        nameInput.classList.add('invalid');
        isValid = false;
    } else if (nameValue.length < 3) {
        nameError.textContent = 'Tên cơ sở phải có ít nhất 3 ký tự';
        nameInput.classList.add('invalid');
        isValid = false;
    }
    
    // Validate status
    const validStatuses = ['Active', 'Maintenance', 'Inactive'];
    if (!validStatuses.includes(statusInput.value)) {
        statusError.textContent = 'Trạng thái không hợp lệ';
        statusInput.classList.add('invalid');
        isValid = false;
    }
    
    return isValid;
}
