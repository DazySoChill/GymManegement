/**
 * Members Management Module
 */

let membersCurrentPage = 1;
let membersPageSize = 10;

// Inject modal styles once
function injectMemberModalStyles() {
    if (document.getElementById('member-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'member-modal-styles';
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
        .form-group input.invalid {
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
                            <button class="btn btn-sm btn-danger" onclick="deleteMember(${member.memberId})">🗑️</button>
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
    injectMemberModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal" style="position: relative;">
            <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
            <h3>➕ Thêm Member Mới</h3>
            <form id="createMemberForm">
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
                    <label>Số điện thoại</label>
                    <input type="tel" id="phone" name="phone">
                    <div class="error" id="phoneError"></div>
                </div>
                <div class="form-group">
                    <label>Ngày sinh</label>
                    <input type="date" id="dateOfBirth" name="dateOfBirth">
                    <div class="error" id="dateOfBirthError"></div>
                </div>
                <div class="gym-modal-buttons">
                    <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                    <button type="submit" class="btn btn-primary">Tạo Member</button>
                </div>
            </form>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Form submit handler
    const form = document.getElementById('createMemberForm');
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Validate form
        if (!validateMemberForm()) {
            return;
        }
        
        // Gather data
        const formData = {
            fullName: document.getElementById('fullName').value.trim(),
            email: document.getElementById('email').value.trim(),
            phone: document.getElementById('phone').value.trim() || null,
            dateOfBirth: document.getElementById('dateOfBirth').value || null
        };
        
        try {
            showLoading();
            await apiFetch('/api/Member', {
                method: 'POST',
                body: JSON.stringify(formData)
            });
            hideLoading();
            showSuccess('Tạo member thành công!');
            modal.remove();
            await loadMembers();
        } catch (error) {
            hideLoading();
            showError('Lỗi tạo member: ' + error.message);
        }
    });
}

async function showEditMemberModal(memberId) {
    injectMemberModalStyles();
    
    try {
        showLoading();
        const member = await apiFetch(`/api/Member/${memberId}`);
        hideLoading();
        
        if (!member) {
            showError('Không tìm thấy member');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>✏️ Sửa Thông Tin Member</h3>
                <form id="editMemberForm">
                    <div class="form-group">
                        <label>Họ và tên <span class="required">*</span></label>
                        <input type="text" id="editFullName" name="fullName" value="${escapeHtml(member.fullName)}" required>
                        <div class="error" id="editFullNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>Email <span class="required">*</span></label>
                        <input type="email" id="editEmail" name="email" value="${escapeHtml(member.email)}" required>
                        <div class="error" id="editEmailError"></div>
                    </div>
                    <div class="form-group">
                        <label>Số điện thoại</label>
                        <input type="tel" id="editPhone" name="phone" value="${escapeHtml(member.phone || '')}">
                        <div class="error" id="editPhoneError"></div>
                    </div>
                    <div class="form-group">
                        <label>Ngày sinh</label>
                        <input type="date" id="editDateOfBirth" name="dateOfBirth" value="${member.dateOfBirth ? member.dateOfBirth.split('T')[0] : ''}">
                        <div class="error" id="editDateOfBirthError"></div>
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
        const form = document.getElementById('editMemberForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            // Validate form
            if (!validateMemberForm(true)) {
                return;
            }
            
            // Gather data
            const formData = {
                fullName: document.getElementById('editFullName').value.trim(),
                email: document.getElementById('editEmail').value.trim(),
                phone: document.getElementById('editPhone').value.trim() || null,
                dateOfBirth: document.getElementById('editDateOfBirth').value || null
            };
            
            try {
                showLoading();
                await apiFetch(`/api/Member/${memberId}`, {
                    method: 'PUT',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Cập nhật member thành công!');
                modal.remove();
                await loadMembers();
            } catch (error) {
                hideLoading();
                showError('Lỗi cập nhật member: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải thông tin member: ' + error.message);
    }
}

function validateMemberForm(isEdit = false) {
    const prefix = isEdit ? 'edit' : '';
    const fullName = document.getElementById(prefix + 'fullName');
    const email = document.getElementById(prefix + 'email');
    const dateOfBirth = document.getElementById(prefix + 'dateOfBirth');
    
    let isValid = true;
    
    // Clear previous errors
    document.getElementById(prefix + 'fullNameError').textContent = '';
    document.getElementById(prefix + 'emailError').textContent = '';
    document.getElementById(prefix + 'dateOfBirthError').textContent = '';
    fullName.classList.remove('invalid');
    email.classList.remove('invalid');
    dateOfBirth.classList.remove('invalid');
    
    // Validate full name
    if (!fullName.value.trim()) {
        document.getElementById(prefix + 'fullNameError').textContent = 'Vui lòng nhập họ tên';
        fullName.classList.add('invalid');
        isValid = false;
    }
    
    // Validate email
    const emailValue = email.value.trim();
    if (!emailValue) {
        document.getElementById(prefix + 'emailError').textContent = 'Vui lòng nhập email';
        email.classList.add('invalid');
        isValid = false;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailValue)) {
        document.getElementById(prefix + 'emailError').textContent = 'Email không hợp lệ';
        email.classList.add('invalid');
        isValid = false;
    }
    
    // Validate date of birth (not in future)
    if (dateOfBirth.value) {
        const selectedDate = new Date(dateOfBirth.value);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        if (selectedDate > today) {
            document.getElementById(prefix + 'dateOfBirthError').textContent = 'Ngày sinh không được là ngày tương lai';
            dateOfBirth.classList.add('invalid');
            isValid = false;
        }
    }
    
    return isValid;
}

async function deleteMember(memberId) {
    if (!confirm('Bạn có chắc chắn muốn xóa member này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Member/${memberId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa member thành công!');
        await loadMembers();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa member: ' + error.message);
    }
}
