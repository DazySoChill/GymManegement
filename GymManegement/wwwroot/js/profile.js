/**
 * Profile Management Module - Change Password
 */

async function renderProfile(container) {
    const user = getUser();
    const role = getRole();
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">👤 Thông Tin Cá Nhân</h2>
            </div>
            
            <div style="padding: 24px;">
                <div style="margin-bottom: 24px;">
                    <strong>Họ tên:</strong> ${escapeHtml(user.fullName)}<br>
                    <strong>Username:</strong> ${escapeHtml(user.username)}<br>
                    <strong>Email:</strong> ${escapeHtml(user.email)}<br>
                    <strong>Vai trò:</strong> ${escapeHtml(role)}
                </div>
                
                <hr style="margin: 24px 0;">
                
                <h3 style="margin-bottom: 16px;">🔒 Đổi Mật Khẩu</h3>
                
                <form id="changePasswordForm" style="max-width: 400px;">
                    <div class="form-group">
                        <label>Mật khẩu cũ *</label>
                        <input type="password" id="oldPassword" class="form-control" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Mật khẩu mới *</label>
                        <input type="password" id="newPassword" class="form-control" required minlength="6">
                        <small style="color: #7f8c8d;">Tối thiểu 6 ký tự</small>
                    </div>
                    
                    <div class="form-group">
                        <label>Xác nhận mật khẩu mới *</label>
                        <input type="password" id="confirmPassword" class="form-control" required>
                    </div>
                    
                    <div style="display: flex; gap: 12px; margin-top: 24px;">
                        <button type="submit" class="btn btn-primary">💾 Đổi Mật Khẩu</button>
                        <button type="button" class="btn btn-secondary" onclick="document.getElementById('changePasswordForm').reset()">🔄 Reset</button>
                    </div>
                </form>
            </div>
        </div>
    `;
    
    // Handle form submit
    document.getElementById('changePasswordForm').addEventListener('submit', handleChangePassword);
}

async function handleChangePassword(e) {
    e.preventDefault();
    
    const oldPassword = document.getElementById('oldPassword').value;
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;
    
    // Validation
    if (newPassword.length < 6) {
        showToast('Mật khẩu mới phải có ít nhất 6 ký tự', 'error');
        return;
    }
    
    if (newPassword !== confirmPassword) {
        showToast('Mật khẩu xác nhận không khớp', 'error');
        return;
    }
    
    try {
        showLoading();
        
        const response = await apiFetch('/api/Auth/change-password', {
            method: 'POST',
            body: JSON.stringify({
                oldPassword: oldPassword,
                newPassword: newPassword
            })
        });
        
        hideLoading();
        
        if (response && response.message) {
            showToast(response.message, 'success');
            document.getElementById('changePasswordForm').reset();
        } else {
            showToast('Đổi mật khẩu thành công!', 'success');
            document.getElementById('changePasswordForm').reset();
        }
        
    } catch (error) {
        hideLoading();
        showToast('Lỗi đổi mật khẩu: ' + error.message, 'error');
    }
}
