/**
 * Memberships Management Module
 */

let membershipsCurrentPage = 1;
let membershipsPageSize = 10;

// Available packages for purchase
const AVAILABLE_PACKAGES = [
  { id: 'basic', name: 'Gói Cơ Bản', price: 500000, durationDays: 30, description: '1 tháng - Sử dụng tất cả thiết bị' },
  { id: 'advanced', name: 'Gói Nâng Cao', price: 1200000, durationDays: 90, description: '3 tháng - Bao gồm 2 buổi PT/tháng' },
  { id: 'vip', name: 'Gói VIP', price: 2000000, durationDays: 180, description: '6 tháng - Không giới hạn PT + dinh dưỡng' },
  { id: 'annual', name: 'Gói Năm', price: 3500000, durationDays: 365, description: '12 tháng - Tất cả dịch vụ cao cấp' }
];

// Inject modal styles once
function injectModalStyles() {
    if (document.getElementById('membership-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'membership-modal-styles';
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
            max-width: 420px;
            width: 90%;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
        }
        .gym-modal h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: #2c3e50;
        }
        .gym-modal-buttons {
            display: flex;
            gap: 12px;
            margin-top: 24px;
            justify-content: flex-end;
        }
        .qr-placeholder {
            width: 180px;
            height: 180px;
            background: #f0f0f0;
            border: 2px dashed #999;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
            margin: 20px auto;
            border-radius: 8px;
        }
        .date-picker-group {
            margin: 16px 0;
        }
        .date-picker-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        .date-picker-group input[type="date"] {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .date-display {
            margin-top: 12px;
            padding: 12px;
            background: #f8f9fa;
            border-radius: 6px;
            color: #495057;
        }
        .confirm-input-group {
            margin: 20px 0;
        }
        .confirm-input-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        .confirm-input-group input {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .warning-text {
            background: #fff3cd;
            border: 1px solid #ffc107;
            padding: 12px;
            border-radius: 6px;
            color: #856404;
            margin: 16px 0;
        }
    `;
    document.head.appendChild(style);
}

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

function renderAvailablePackages(memberId) {
    let html = '<div class="packages-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin-bottom: 20px;">';
    
    AVAILABLE_PACKAGES.forEach(pkg => {
        html += `
            <div class="package-card" style="border: 2px solid #27ae60; border-radius: 12px; padding: 20px; background: #f8fff8;">
                <h4 style="margin: 0 0 12px 0; color: #27ae60; font-size: 18px;">${escapeHtml(pkg.name)}</h4>
                <div style="font-size: 24px; font-weight: bold; color: #2c3e50; margin-bottom: 8px;">${formatCurrency(pkg.price)}</div>
                <div style="color: #7f8c8d; margin-bottom: 12px; font-size: 14px;">${escapeHtml(pkg.description)}</div>
                <div style="margin-bottom: 16px; color: #555;">⏱️ ${pkg.durationDays} ngày</div>
                <button class="btn btn-success" onclick="showPurchaseModal(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId})" style="width: 100%;">💳 Mua Gói</button>
            </div>
        `;
    });
    
    html += '</div>';
    return html;
}

function showPurchaseModal(pkg, memberId) {
    injectModalStyles();
    
    const today = new Date().toISOString().split('T')[0];
    const oneYearFromNow = new Date();
    oneYearFromNow.setFullYear(oneYearFromNow.getFullYear() + 1);
    const maxDate = oneYearFromNow.toISOString().split('T')[0];
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Xác Nhận Mua Gói</h3>
            <div style="margin-bottom: 16px;">
                <strong>Gói:</strong> ${escapeHtml(pkg.name)}
            </div>
            <div style="margin-bottom: 16px;">
                <strong>Giá:</strong> ${formatCurrency(pkg.price)}
            </div>
            <div style="margin-bottom: 16px;">
                <strong>Thời hạn:</strong> ${pkg.durationDays} ngày
            </div>
            <div class="date-picker-group">
                <label for="startDatePicker">Ngày bắt đầu:</label>
                <input type="date" id="startDatePicker" value="${today}" min="${today}" max="${maxDate}">
            </div>
            <div class="date-display" id="endDateDisplay">
                <strong>Ngày kết thúc:</strong> <span id="endDateValue">Đang tính toán...</span>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                <button class="btn btn-success" onclick="processPurchaseWithDate(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}, 'Cash'); this.closest('.gym-modal-overlay').remove();">💵 Tiền Mặt</button>
                <button class="btn btn-primary" onclick="showQRPaymentModalWithDate(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}); this.closest('.gym-modal-overlay').remove();">📱 Thanh Toán QR</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Update end date when start date changes
    const startDatePicker = document.getElementById('startDatePicker');
    const updateEndDate = () => {
        const startDate = startDatePicker.value;
        const endDate = calculateEndDate(startDate, pkg.durationDays);
        document.getElementById('endDateValue').textContent = formatDate(endDate);
    };
    startDatePicker.addEventListener('change', updateEndDate);
    updateEndDate(); // Initial calculation
}

function calculateEndDate(startDate, durationDays) {
    const start = new Date(startDate);
    const end = new Date(start);
    end.setDate(start.getDate() + durationDays - 1); // -1 because if you start on day 1 of a 30-day package, it ends on day 30
    return end.toISOString().split('T')[0];
}

function processPurchaseWithDate(pkg, memberId, paymentMethod) {
    const startDatePicker = document.getElementById('startDatePicker');
    const startDate = startDatePicker ? startDatePicker.value : new Date().toISOString().split('T')[0];
    processPurchase(pkg, memberId, paymentMethod, startDate);
}

function showQRPaymentModal(pkg, memberId) {
    injectModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Thanh Toán QR</h3>
            <div class="qr-placeholder">📱</div>
            <div style="text-align: center; margin: 16px 0; font-size: 16px; color: #2c3e50;">
                Quét mã QR để thanh toán <strong>${formatCurrency(pkg.price)}</strong>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                <button class="btn btn-success" onclick="processPurchase(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}, 'QRCode'); this.closest('.gym-modal-overlay').remove();">✅ Xác Nhận Đã Thanh Toán</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

function showQRPaymentModalWithDate(pkg, memberId) {
    const startDatePicker = document.getElementById('startDatePicker');
    const startDate = startDatePicker ? startDatePicker.value : new Date().toISOString().split('T')[0];
    
    injectModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Thanh Toán QR</h3>
            <div class="qr-placeholder">📱</div>
            <div style="text-align: center; margin: 16px 0; font-size: 16px; color: #2c3e50;">
                Quét mã QR để thanh toán <strong>${formatCurrency(pkg.price)}</strong>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                <button class="btn btn-success" onclick="processPurchase(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}, 'QRCode', '${startDate}'); this.closest('.gym-modal-overlay').remove();">✅ Xác Nhận Đã Thanh Toán</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

async function processPurchase(pkg, memberId, method = 'QRCode', startDate = null) {
    try {
        showLoading();
        
        // Use provided start date or default to today
        const start = startDate ? new Date(startDate) : new Date();
        const end = new Date(start);
        end.setDate(start.getDate() + pkg.durationDays - 1);
        // Set end time to end of day
        end.setHours(23, 59, 59, 999);
        
        // Step 1: Create payment record (using /process endpoint for Members)
        const paymentData = {
            memberId: memberId,
            amount: pkg.price,
            paymentMethod: method,
            paymentDate: new Date().toISOString(),
            transactionId: (method === 'Cash' ? 'CASH_' : 'QR_') + Date.now(),
            status: 'Completed'
        };
        
        await apiFetch('/api/Payment/process', {
            method: 'POST',
            body: JSON.stringify(paymentData)
        });
        
        // Step 2: Create membership (using /purchase endpoint for Members)
        const membershipData = {
            memberId: memberId,
            packageName: pkg.name,
            price: pkg.price,
            startDate: start.toISOString(),
            endDate: end.toISOString()
        };
        
        await apiFetch('/api/Membership/purchase', {
            method: 'POST',
            body: JSON.stringify(membershipData)
        });
        
        hideLoading();
        showToast('Mua gói tập thành công!', 'success');
        
        // Reload to show new membership
        setTimeout(() => {
            reloadCurrentPage();
        }, 1500);
        
    } catch (error) {
        hideLoading();
        let errorMessage = 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.';
        
        // Check for specific error messages
        if (error.message) {
            if (error.message.toLowerCase().includes('active membership') || 
                error.message.toLowerCase().includes('đã có gói tập')) {
                errorMessage = 'Bạn đã có gói tập đang hoạt động. Vui lòng hủy gói hiện tại trước khi mua gói mới.';
            } else if (error.message.toLowerCase().includes('payment')) {
                errorMessage = 'Lỗi thanh toán. Vui lòng thử lại sau.';
            } else if (error.message.toLowerCase().includes('membership')) {
                errorMessage = 'Lỗi tạo gói tập. Vui lòng liên hệ quản trị viên.';
            } else {
                errorMessage = error.message;
            }
        }
        
        showToast('Lỗi mua gói tập: ' + errorMessage, 'error');
    }
}

async function renderMemberMemberships(container, memberId) {
    injectModalStyles();
    
    container.innerHTML = `
        <div class="card" style="margin-bottom: 24px;">
            <div class="card-header">
                <h2 class="card-title">Gói Tập Có Sẵn</h2>
            </div>
            <div id="availablePackagesContainer" style="padding: 20px;"></div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Gói Tập Của Tôi</h2>
            </div>
            <div id="myMembershipsContainer"></div>
        </div>
    `;
    
    // Render available packages
    document.getElementById('availablePackagesContainer').innerHTML = renderAvailablePackages(memberId);
    
    try {
        showLoading();
        const memberships = await apiFetch(`/api/Membership/member/${memberId}`);
        hideLoading();
        
        const myContainer = document.getElementById('myMembershipsContainer');
        if (!memberships || memberships.length === 0) {
            myContainer.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🎫</div><div class="empty-state-text">Bạn chưa có gói tập nào</div></div>';
            return;
        }
        
        let html = '<table><thead><tr><th>Gói</th><th>Giá</th><th>Ngày bắt đầu</th><th>Ngày kết thúc</th><th>Còn lại</th><th>Thao tác</th></tr></thead><tbody>';
        
        memberships.forEach(m => {
            const daysClass = m.daysRemaining < 7 ? 'badge-danger' : m.daysRemaining < 30 ? 'badge-warning' : 'badge-success';
            const isActive = m.daysRemaining > 0;
            html += `
                <tr>
                    <td>${escapeHtml(m.packageName)}</td>
                    <td>${formatCurrency(m.price)}</td>
                    <td>${formatDate(m.startDate)}</td>
                    <td>${formatDate(m.endDate)}</td>
                    <td><span class="badge ${daysClass}">${m.daysRemaining} ngày</span></td>
                    <td>
                        ${isActive ? `<button class="btn btn-sm btn-danger" onclick="cancelMembership(${m.membershipId})">❌ Hủy Gói</button>` : '<span style="color: #999;">Đã hết hạn</span>'}
                    </td>
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

async function cancelMembership(membershipId) {
    // Show custom confirmation modal
    injectModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Xác Nhận Hủy Gói Tập</h3>
            <div class="warning-text">
                ⚠️ Gói tập sẽ kết thúc ngay hôm nay. Hành động này không thể hoàn tác.
            </div>
            <div class="confirm-input-group">
                <label for="cancelConfirmInput">Nhập "Xác Nhận" để tiếp tục:</label>
                <input type="text" id="cancelConfirmInput" placeholder='Nhập "Xác Nhận"'>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy Bỏ</button>
                <button class="btn btn-danger" id="confirmCancelBtn" disabled onclick="executeCancelMembership(${membershipId}); this.closest('.gym-modal-overlay').remove();">Hủy Gói Tập</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Enable button only when exact text is entered
    const input = document.getElementById('cancelConfirmInput');
    const confirmBtn = document.getElementById('confirmCancelBtn');
    input.addEventListener('input', () => {
        confirmBtn.disabled = input.value !== 'Xác Nhận';
    });
    input.focus();
}

async function executeCancelMembership(membershipId) {
    try {
        showLoading();
        await apiFetch(`/api/Membership/${membershipId}/cancel`, { method: 'POST' });
        hideLoading();
        showToast('Hủy gói tập thành công!', 'success');
        
        // Reload membership list
        const role = getRole();
        const memberId = getMemberId();
        const container = document.querySelector('.main-content');
        if (container) {
            await renderMemberships(container);
        } else {
            reloadCurrentPage();
        }
    } catch (err) {
        hideLoading();
        showToast('Lỗi hủy gói: ' + err.message, 'error');
    }
}
