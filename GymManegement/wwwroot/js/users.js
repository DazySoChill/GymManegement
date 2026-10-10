/**
 * Users Management Module (Admin only)
 */

let usersCurrentPage = 1;
let usersPageSize = 10;

async function renderUsers(container) {
    const role = getRole();
    
    if (role !== 'Admin') {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔒</div><div class="empty-state-text">Bạn không có quyền truy cập trang này</div></div>';
        return;
    }
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Tài Khoản Users</h2>
                <button class="btn btn-primary" onclick="showCreateStaffModal()">➕ Tạo Admin/Trainer</button>
            </div>
            
            <div class="table-container" id="usersTableContainer"></div>
        </div>
        
        <!-- Change Password Modal -->
        <div id="changePasswordModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3 class="modal-title">Đổi Mật Khẩu</h3>
                    <button class="modal-close" onclick="closeChangePasswordModal()">×</button>
                </div>
                <form id="changePasswordForm">
                    <div class="form-group">
                        <label>Mật khẩu cũ</label>
                        <input type="password" id="oldPassword" required minlength="6">
                    </div>
                    <div class="form-group">
                        <label>Mật khẩu mới</label>
                        <input type="password" id="newPassword" required minlength="6">
                    </div>
                    <div class="form-group">
                        <label>Xác nhận mật khẩu mới</label>
                        <input type="password" id="confirmNewPassword" required minlength="6">
                    </div>
                    <div id="changePasswordError" class="error-message" style="display: none;"></div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-sm" onclick="closeChangePasswordModal()">Hủy</button>
                        <button type="submit" class="btn btn-sm btn-primary">Đổi mật khẩu</button>
                    </div>
                </form>
            </div>
        </div>
        
        <!-- Create Staff Modal -->
        <div id="createStaffModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3 class="modal-title">Tạo Tài Khoản Admin/Trainer</h3>
                    <button class="modal-close" onclick="closeCreateStaffModal()">×</button>
                </div>
                <form id="createStaffForm">
                    <div class="form-group">
                        <label>Họ và tên *</label>
                        <input type="text" id="staffFullName" required maxlength="100">
                    </div>
                    <div class="form-group">
                        <label>Email *</label>
                        <input type="email" id="staffEmail" required>
                    </div>
                    <div class="form-group">
                        <label>Tên đăng nhập *</label>
                        <input type="text" id="staffUsername" required maxlength="50">
                    </div>
                    <div class="form-group">
                        <label>Mật khẩu *</label>
                        <input type="password" id="staffPassword" required minlength="6">
                    </div>
                    <div class="form-group">
                        <label>Vai trò *</label>
                        <select id="staffRole" required>
                            <option value="">-- Chọn vai trò --</option>
                            <option value="Admin">Admin</option>
                            <option value="Trainer">Trainer</option>
                        </select>
                    </div>
                    <div id="createStaffError" class="error-message" style="display: none;"></div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-sm" onclick="closeCreateStaffModal()">Hủy</button>
                        <button type="submit" class="btn btn-sm btn-primary">Tạo tài khoản</button>
                    </div>
                </form>
            </div>
        </div>
    `;
    
    await loadUsers();
    
    // Setup change password form handler
    document.getElementById('changePasswordForm').addEventListener('submit', handleChangePassword);
    document.getElementById('createStaffForm').addEventListener('submit', handleCreateStaff);
}

async function loadUsers() {
    try {
        showLoading();
        const users = await apiFetch('/api/Auth/users');
        hideLoading();
        
        renderUsersTable(users);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách users: ' + error.message);
    }
}

function renderUsersTable(users) {
    const container = document.getElementById('usersTableContainer');
    const currentUser = getUser();
    
    if (!users || users.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">👤</div><div class="empty-state-text">Không có user nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Username</th>
                    <th>Họ tên</th>
                    <th>Email</th>
                    <th>Vai trò</th>
                    <th>Trạng thái</th>
                    <th>Đăng nhập cuối</th>
                    <th>Thao tác</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    users.forEach(user => {
        const isActive = user.isActive !== false;
        const statusBadge = isActive ? 'badge-success' : 'badge-danger';
        const statusText = isActive ? 'Hoạt động' : 'Bị khóa';
        const isCurrentUser = user.userId === currentUser.userId;
        
        html += `
            <tr>
                <td>${user.userId}</td>
                <td>${escapeHtml(user.username)}</td>
                <td>${escapeHtml(user.fullName)}</td>
                <td>${escapeHtml(user.email || '-')}</td>
                <td><span class="badge badge-info">${user.role}</span></td>
                <td><span class="badge ${statusBadge}">${statusText}</span></td>
                <td>${formatDateTime(user.lastLoginAt)}</td>
                <td>
                    <div class="action-buttons">
                        ${!isCurrentUser ? `
                            ${isActive 
                                ? `<button class="btn btn-sm btn-danger" onclick="toggleUserStatus(${user.userId}, false)">🔒 Khóa</button>`
                                : `<button class="btn btn-sm btn-success" onclick="toggleUserStatus(${user.userId}, true)">🔓 Mở</button>`
                            }
                        ` : '<span class="text-muted">Tài khoản hiện tại</span>'}
                    </div>
                </td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

async function toggleUserStatus(userId, isActive) {
    const action = isActive ? 'mở khóa' : 'khóa';
    
    if (!confirm(`Bạn có chắc muốn ${action} tài khoản này?`)) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Auth/users/${userId}/active?isActive=${isActive}`, {
            method: 'PUT'
        });
        hideLoading();
        showSuccess(`${action.charAt(0).toUpperCase() + action.slice(1)} tài khoản thành công`);
        await loadUsers();
    } catch (error) {
        hideLoading();
        showError(`Lỗi ${action} tài khoản: ` + error.message);
    }
}

function showChangePasswordModal() {
    document.getElementById('changePasswordModal').classList.add('show');
    document.getElementById('changePasswordForm').reset();
    document.getElementById('changePasswordError').style.display = 'none';
}

function closeChangePasswordModal() {
    document.getElementById('changePasswordModal').classList.remove('show');
}

async function handleChangePassword(e) {
    e.preventDefault();
    
    const oldPassword = document.getElementById('oldPassword').value;
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmNewPassword').value;
    const errorDiv = document.getElementById('changePasswordError');
    
    errorDiv.style.display = 'none';
    
    if (newPassword !== confirmPassword) {
        errorDiv.textContent = 'Mật khẩu xác nhận không khớp';
        errorDiv.style.display = 'block';
        return;
    }
    
    if (newPassword.length < 6) {
        errorDiv.textContent = 'Mật khẩu mới phải có ít nhất 6 ký tự';
        errorDiv.style.display = 'block';
        return;
    }
    
    try {
        showLoading();
        await apiFetch('/api/Auth/change-password', {
            method: 'POST',
            body: JSON.stringify({
                oldPassword,
                newPassword
            })
        });
        hideLoading();
        showSuccess('Đổi mật khẩu thành công');
        closeChangePasswordModal();
    } catch (error) {
        hideLoading();
        errorDiv.textContent = 'Đổi mật khẩu thất bại: ' + error.message;
        errorDiv.style.display = 'block';
    }
}

function showCreateStaffModal() {
    document.getElementById('createStaffModal').classList.add('show');
    document.getElementById('createStaffForm').reset();
    document.getElementById('createStaffError').style.display = 'none';
}

function closeCreateStaffModal() {
    document.getElementById('createStaffModal').classList.remove('show');
}

async function handleCreateStaff(e) {
    e.preventDefault();
    
    const fullName = document.getElementById('staffFullName').value.trim();
    const email = document.getElementById('staffEmail').value.trim();
    const username = document.getElementById('staffUsername').value.trim();
    const password = document.getElementById('staffPassword').value;
    const role = document.getElementById('staffRole').value;
    const errorDiv = document.getElementById('createStaffError');
    
    errorDiv.style.display = 'none';
    
    if (!fullName || !email || !username || !password || !role) {
        errorDiv.textContent = 'Vui lòng nhập đầy đủ thông tin';
        errorDiv.style.display = 'block';
        return;
    }
    
    if (role !== 'Admin' && role !== 'Trainer') {
        errorDiv.textContent = 'Vai trò không hợp lệ';
        errorDiv.style.display = 'block';
        return;
    }
    
    try {
        showLoading();
        await apiFetch('/api/Auth/create-staff', {
            method: 'POST',
            body: JSON.stringify({
                username,
                password,
                fullName,
                email,
                role
            })
        });
        hideLoading();
        showSuccess(`Tạo tài khoản ${role} thành công`);
        closeCreateStaffModal();
        await loadUsers();
    } catch (error) {
        hideLoading();
        errorDiv.textContent = 'Tạo tài khoản thất bại: ' + error.message;
        errorDiv.style.display = 'block';
    }
}
