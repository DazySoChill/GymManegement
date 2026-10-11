/**
 * Trainers Management Module
 */

let trainersCurrentPage = 1;
let trainersPageSize = 10;

// Inject modal styles once
function injectTrainerModalStyles() {
    if (document.getElementById('trainer-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'trainer-modal-styles';
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
        .form-group textarea.invalid {
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
    
    // Defensive accessor for items
    const items = data?.data || data?.items || [];
    if (items.length === 0) {
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
    
    items.forEach(trainer => {
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
                        <button class="btn btn-sm btn-danger" onclick="deleteTrainer(${trainer.trainerId})">🗑️</button>
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
    
    // Defensive accessors for pagination metadata
    const pageNumber = data?.pageNumber || 1;
    const totalPages = data?.totalPages || 1;
    
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
    injectTrainerModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal" style="position: relative;">
            <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
            <h3>➕ Thêm Huấn Luyện Viên Mới</h3>
            <form id="createTrainerForm">
                <div class="form-group">
                    <label>Họ và tên <span class="required">*</span></label>
                    <input type="text" id="fullName" name="fullName" required>
                    <div class="error" id="fullNameError"></div>
                </div>
                <div class="form-group">
                    <label>Email <span class="required">*</span></label>
                    <input type="email" id="email" name="email" required>
                    <div class="error" id="emailError"></div>
                </div>
                <div class="form-group">
                    <label>Số điện thoại <span class="required">*</span></label>
                    <input type="tel" id="phone" name="phone" required>
                    <div class="error" id="phoneError"></div>
                </div>
                <div class="form-group">
                    <label>Chuyên môn <span class="required">*</span></label>
                    <textarea id="specialization" name="specialization" rows="3" required placeholder="VD: Yoga, Cardio, Boxing..."></textarea>
                    <div class="error" id="specializationError"></div>
                </div>
                <div class="gym-modal-buttons">
                    <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                    <button type="submit" class="btn btn-primary">Tạo HLV</button>
                </div>
            </form>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Form submit handler
    const form = document.getElementById('createTrainerForm');
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Validate form
        if (!validateTrainerForm()) {
            return;
        }
        
        // Gather data
        const formData = {
            fullName: document.getElementById('fullName').value.trim(),
            email: document.getElementById('email').value.trim(),
            phone: document.getElementById('phone').value.trim(),
            specialization: document.getElementById('specialization').value.trim()
        };
        
        try {
            showLoading();
            await apiFetch('/api/Trainer', {
                method: 'POST',
                body: JSON.stringify(formData)
            });
            hideLoading();
            showSuccess('Tạo HLV thành công!');
            modal.remove();
            await loadTrainers();
        } catch (error) {
            hideLoading();
            showError('Lỗi tạo HLV: ' + error.message);
        }
    });
}

async function showEditTrainerModal(trainerId) {
    injectTrainerModalStyles();
    
    try {
        showLoading();
        const trainer = await apiFetch(`/api/Trainer/${trainerId}`);
        hideLoading();
        
        if (!trainer) {
            showError('Không tìm thấy HLV');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>✏️ Sửa Thông Tin Huấn Luyện Viên</h3>
                <form id="editTrainerForm">
                    <div class="form-group">
                        <label>Họ và tên <span class="required">*</span></label>
                        <input type="text" id="editFullName" name="fullName" value="${escapeHtml(trainer.fullName)}" required>
                        <div class="error" id="editFullNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>Email <span class="required">*</span></label>
                        <input type="email" id="editEmail" name="email" value="${escapeHtml(trainer.email)}" required>
                        <div class="error" id="editEmailError"></div>
                    </div>
                    <div class="form-group">
                        <label>Số điện thoại <span class="required">*</span></label>
                        <input type="tel" id="editPhone" name="phone" value="${escapeHtml(trainer.phone || '')}" required>
                        <div class="error" id="editPhoneError"></div>
                    </div>
                    <div class="form-group">
                        <label>Chuyên môn <span class="required">*</span></label>
                        <textarea id="editSpecialization" name="specialization" rows="3" required>${escapeHtml(trainer.specialization || '')}</textarea>
                        <div class="error" id="editSpecializationError"></div>
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
        const form = document.getElementById('editTrainerForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            console.log('Form submitted!');
            
            // Simplified validation - just check required fields
            const fullName = document.getElementById('editFullName').value.trim();
            const email = document.getElementById('editEmail').value.trim();
            const phone = document.getElementById('editPhone').value.trim();
            const specialization = document.getElementById('editSpecialization').value.trim();
            
            if (!fullName) {
                showError('Vui lòng nhập họ tên');
                return;
            }
            
            if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
                showError('Email không hợp lệ');
                return;
            }
            
            if (!phone) {
                showError('Vui lòng nhập số điện thoại');
                return;
            }
            
            if (!specialization) {
                showError('Vui lòng nhập chuyên môn');
                return;
            }
            
            // Gather data
            const formData = {
                fullName: fullName,
                email: email,
                phone: phone,
                specialization: specialization
            };
            
            console.log('Updating trainer with data:', formData);
            
            try {
                showLoading();
                const result = await apiFetch(`/api/Trainer/${trainerId}`, {
                    method: 'PUT',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                console.log('Update success:', result);
                showSuccess('Cập nhật HLV thành công!');
                modal.remove();
                await loadTrainers();
            } catch (error) {
                hideLoading();
                console.error('Update error:', error);
                showError('Lỗi cập nhật HLV: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải thông tin HLV: ' + error.message);
    }
}

function validateTrainerForm(isEdit = false) {
    const prefix = isEdit ? 'edit' : '';
    const fullName = document.getElementById(prefix + 'fullName');
    const email = document.getElementById(prefix + 'email');
    const phone = document.getElementById(prefix + 'phone');
    const specialization = document.getElementById(prefix + 'specialization');
    
    // Check if elements exist
    if (!fullName || !email || !phone || !specialization) {
        console.error('Form elements not found');
        return false;
    }
    
    let isValid = true;
    
    // Clear previous errors - with defensive checks
    const fullNameError = document.getElementById(prefix + 'fullNameError');
    const emailError = document.getElementById(prefix + 'emailError');
    const phoneError = document.getElementById(prefix + 'phoneError');
    const specializationError = document.getElementById(prefix + 'specializationError');
    
    if (fullNameError) fullNameError.textContent = '';
    if (emailError) emailError.textContent = '';
    if (phoneError) phoneError.textContent = '';
    if (specializationError) specializationError.textContent = '';
    
    fullName.classList.remove('invalid');
    email.classList.remove('invalid');
    phone.classList.remove('invalid');
    specialization.classList.remove('invalid');
    
    // Validate full name
    if (!fullName.value.trim()) {
        if (fullNameError) fullNameError.textContent = 'Vui lòng nhập họ tên';
        fullName.classList.add('invalid');
        isValid = false;
    }
    
    // Validate email
    const emailValue = email.value.trim();
    if (!emailValue) {
        if (emailError) emailError.textContent = 'Vui lòng nhập email';
        email.classList.add('invalid');
        isValid = false;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailValue)) {
        if (emailError) emailError.textContent = 'Email không hợp lệ';
        email.classList.add('invalid');
        isValid = false;
    }
    
    // Validate phone
    if (!phone.value.trim()) {
        if (phoneError) phoneError.textContent = 'Vui lòng nhập số điện thoại';
        phone.classList.add('invalid');
        isValid = false;
    }
    
    // Validate specialization
    if (!specialization.value.trim()) {
        if (specializationError) specializationError.textContent = 'Vui lòng nhập chuyên môn';
        specialization.classList.add('invalid');
        isValid = false;
    }
    
    return isValid;
}

async function deleteTrainer(trainerId) {
    if (!confirm('Bạn có chắc chắn muốn xóa HLV này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Trainer/${trainerId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa HLV thành công!');
        await loadTrainers();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa HLV: ' + error.message);
    }
}
