/**
 * Check-ins Management Module
 */

let checkinsCurrentPage = 1;
let checkinsPageSize = 10;

// Ensure modal styles are available (shared with memberships)
function ensureModalStyles() {
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
        .qr-code-display {
            background: #f8f9fa;
            padding: 16px;
            border-radius: 8px;
            border: 1px solid #dee2e6;
            font-family: monospace;
            font-size: 14px;
            text-align: center;
            margin: 16px 0;
            word-break: break-all;
            color: #2c3e50;
        }
    `;
    document.head.appendChild(style);
}

function showQRCheckinModal(memberId) {
    ensureModalStyles();
    
    const qrValue = `MEMBER_${memberId}_${Date.now()}`;
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Check-in bằng QR</h3>
            <div class="qr-placeholder">📱</div>
            <div class="qr-code-display">${escapeHtml(qrValue)}</div>
            <input id="qrCodeInput" type="text" value="${escapeHtml(qrValue)}" placeholder="Nhập hoặc scan QR code" style="width:100%;padding:8px;margin:12px 0;border:1px solid #ddd;border-radius:6px;">
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                <button class="btn btn-success" onclick="processQRCheckin(${memberId}); this.closest('.gym-modal-overlay').remove();">✅ Xác Nhận Check-in</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

async function processQRCheckin(memberId) {
    const qrCode = document.getElementById('qrCodeInput')?.value?.trim();
    
    if (!qrCode) {
        showError('Vui lòng nhập mã QR');
        return;
    }
    
    try {
        showLoading();
        
        await apiFetch('/api/Checkin/qr', {
            method: 'POST',
            body: JSON.stringify({
                qrCode: qrCode,
                memberId: memberId
            })
        });
        
        hideLoading();
        showToast('✅ Check-in thành công!', 'success');
        reloadCurrentPage();
        
    } catch (error) {
        hideLoading();
        const errorMsg = error.message.toLowerCase();
        if (errorMsg.includes('already') || errorMsg.includes('đã check-in')) {
            showError('Bạn đã check-in rồi. Vui lòng checkout trước.');
        } else {
            showError('Lỗi check-in: ' + error.message);
        }
    }
}

async function renderCheckins(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if (role === 'Member' && memberId) {
        await renderMemberCheckins(container, memberId);
    } else {
        await renderAllCheckins(container);
    }
}

async function renderMemberCheckins(container, memberId) {
    ensureModalStyles();
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
                <h2 class="card-title">Lịch Sử Check-in</h2>
                <button class="btn btn-primary" onclick="showQRCheckinModal(${memberId})">📱 Check-in QR</button>
            </div>
            
            <div class="filters">
                <input type="date" id="checkinFromDate">
                <input type="date" id="checkinToDate">
                <button class="btn btn-info" onclick="loadMemberCheckinsByDateRange(${memberId})">🔍 Lọc</button>
            </div>
            
            <div id="myCheckinsContainer"></div>
        </div>
    `;
    
    try {
        showLoading();
        const checkins = await apiFetch(`/api/Checkin/member/${memberId}`);
        hideLoading();
        
        renderMemberCheckinsTable(checkins);
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch sử check-in: ' + error.message);
    }
}

function renderMemberCheckinsTable(checkins) {
    const container = document.getElementById('myCheckinsContainer');
    
    if (!checkins || checkins.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><div class="empty-state-text">Chưa có check-in nào</div></div>';
        return;
    }
    
    let html = '<table><thead><tr><th>ID</th><th>Thời gian vào</th><th>Thời gian ra</th></tr></thead><tbody>';
    
    checkins.forEach(c => {
        html += `
            <tr>
                <td>${c.checkinId}</td>
                <td>${formatDateTime(c.checkinTime)}</td>
                <td>${c.checkoutTime ? formatDateTime(c.checkoutTime) : 'Chưa ra'}</td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

async function renderAllCheckins(container) {
    const role = getRole();
    const canManage = role === 'Admin' || role === 'Trainer';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Check-in</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showManualCheckinModal()">➕ Check-in thủ công</button>' : ''}
            </div>
            
            <div class="filters">
                <input type="date" id="checkinDate" onchange="loadCheckinsByDate()">
                <button class="btn btn-info" onclick="loadCheckins()">🔍 Tất cả</button>
            </div>
            
            <div class="table-container" id="checkinsTableContainer"></div>
            <div id="checkinsPagination" class="pagination"></div>
        </div>
    `;
    
    await loadCheckins();
}

async function loadCheckins() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Checkin?pageNumber=${checkinsCurrentPage}&pageSize=${checkinsPageSize}`);
        hideLoading();
        
        renderCheckinsTable(data);
        renderCheckinsPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách check-in: ' + error.message);
    }
}

async function loadCheckinsByDate() {
    const dateInput = document.getElementById('checkinDate');
    const date = dateInput.value;
    
    if (!date) {
        loadCheckins();
        return;
    }
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Checkin/date/${date}`);
        hideLoading();
        
        renderCheckinsTable({ items: data, pageNumber: 1, totalPages: 1 });
    } catch (error) {
        hideLoading();
        showError('Lỗi tải check-in: ' + error.message);
    }
}

function renderCheckinsTable(data) {
    const container = document.getElementById('checkinsTableContainer');
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><div class="empty-state-text">Không có check-in nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Member</th>
                    <th>Thời gian vào</th>
                    <th>Thời gian ra</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(c => {
        html += `
            <tr>
                <td>${c.checkinId}</td>
                <td>${escapeHtml(c.memberName || '-')}</td>
                <td>${formatDateTime(c.checkinTime)}</td>
                <td>${c.checkoutTime ? formatDateTime(c.checkoutTime) : 'Chưa ra'}</td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderCheckinsPagination(data) {
    const container = document.getElementById('checkinsPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeCheckinsPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeCheckinsPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeCheckinsPage(page) {
    checkinsCurrentPage = page;
    loadCheckins();
}

async function loadMemberCheckinsByDateRange(memberId) {
    const from = document.getElementById('checkinFromDate').value;
    const to = document.getElementById('checkinToDate').value;
    
    if (!from || !to) {
        showError('Vui lòng chọn ngày bắt đầu và kết thúc');
        return;
    }
    
    try {
        showLoading();
        const checkins = await apiFetch(`/api/Checkin/date-range?from=${from}&to=${to}`);
        hideLoading();
        
        // Filter by member
        const filtered = checkins.filter(c => c.memberId === memberId);
        renderMemberCheckinsTable(filtered);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải check-in: ' + error.message);
    }
}

function showManualCheckinModal() {
    showError('Chức năng check-in thủ công chưa được triển khai đầy đủ');
}
