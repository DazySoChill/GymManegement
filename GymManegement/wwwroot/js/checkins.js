/**
 * Check-ins Management Module
 */

let checkinsCurrentPage = 1;
let checkinsPageSize = 10;

// Member name cache to avoid duplicate API calls
// Cache stores { status: 'success' | 'error', value: string, timestamp: number }
const checkinMemberNameCache = {};

// Cache for full checkin dataset and calculated counts
// NOTE: Cache is in-memory only and doesn't sync across browser tabs.
// If a user opens multiple tabs, checkin counts may be stale until manual refresh.
let fullCheckinsCache = null;
let checkinsCountsCache = null;

async function fetchCheckinMemberName(memberId) {
    const cached = checkinMemberNameCache[memberId];
    const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
    
    // Return cached success if still fresh
    if (cached && cached.status === 'success' && (Date.now() - cached.timestamp) < CACHE_TTL) {
        return cached.value;
    }
    
    // Retry transient failures after 30 seconds
    if (cached && cached.status === 'error' && (Date.now() - cached.timestamp) < 30000) {
        return cached.value;
    }
    
    try {
        const member = await apiFetch(`/api/Member/${memberId}`);
        const name = member?.fullName || member?.name || `Member ${memberId}`;
        checkinMemberNameCache[memberId] = { status: 'success', value: name, timestamp: Date.now() };
        return name;
    } catch (error) {
        console.error(`Error fetching member ${memberId}:`, error);
        const fallback = `Member ${memberId}`;
        // Cache error with timestamp to allow retry after delay
        checkinMemberNameCache[memberId] = { status: 'error', value: fallback, timestamp: Date.now() };
        return fallback;
    }
}

/**
 * Calculate checkin counts for all checkins
 * Groups by memberId, sorts by checkinTime ascending, assigns Lần 1, Lần 2, etc.
 */
function calculateCheckinCounts(checkins) {
    // Group by memberId
    const byMember = {};
    checkins.forEach(c => {
        if (!byMember[c.memberId]) {
            byMember[c.memberId] = [];
        }
        byMember[c.memberId].push(c);
    });
    
    // Sort each group by checkinTime and assign counts
    const countsMap = {}; // checkinId -> count
    
    Object.keys(byMember).forEach(memberId => {
        const memberCheckins = byMember[memberId];
        memberCheckins.sort((a, b) => new Date(a.checkinTime) - new Date(b.checkinTime));
        
        memberCheckins.forEach((c, index) => {
            countsMap[c.checkinId] = index + 1;
        });
    });
    
    return countsMap;
}

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
        .gym-modal-header {
            margin-bottom: 20px;
        }
        .gym-modal-header h3 {
            margin: 0;
            color: #2c3e50;
        }
        .gym-modal h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: #2c3e50;
        }
        .gym-modal-body {
            margin-bottom: 0;
        }
        .gym-modal-body .form-group {
            margin-bottom: 16px;
        }
        .gym-modal-body .form-group label {
            display: block;
            margin-bottom: 6px;
            font-weight: 500;
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

/**
 * Quick check-in - simple button click
 * Validates: only 1 check-in per day
 */
async function quickCheckin(memberId) {
    try {
        showLoading();
        
        // Check if already checked in today
        const checkins = await apiFetch(`/api/Checkin/member/${memberId}`);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const todayCheckin = checkins.find(c => {
            const checkinDate = new Date(c.checkinTime);
            checkinDate.setHours(0, 0, 0, 0);
            return checkinDate.getTime() === today.getTime() && !c.checkoutTime;
        });
        
        if (todayCheckin) {
            hideLoading();
            showError('Bạn đã check-in hôm nay rồi! Mỗi ngày chỉ được check-in 1 lần.');
            return;
        }
        
        // Create manual check-in
        const result = await apiFetch('/api/Checkin/manual', {
            method: 'POST',
            body: JSON.stringify({
                memberId: memberId,
                checkinTime: new Date().toISOString()
            })
        });
        
        hideLoading();
        showToast('✅ Check-in thành công!', 'success');
        
        // Reload member checkins view
        const role = getRole();
        if (role === 'Member') {
            // Re-render member view
            const container = document.getElementById('main-content');
            if (container) {
                await renderMemberCheckins(container, memberId);
            }
        } else {
            // Clear cache and reload admin view
            fullCheckinsCache = null;
            checkinsCountsCache = null;
            loadCheckins();
        }
        
    } catch (error) {
        hideLoading();
        
        // Handle 403 Forbidden error
        if (error.message.includes('403') || error.message.includes('Forbidden')) {
            showError('Bạn không có quyền check-in. Vui lòng liên hệ Admin/Trainer.');
        } else {
            showError('Lỗi check-in: ' + error.message);
        }
    }
}

async function renderCheckins(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if ((role === 'Member' || role === 'Trainer') && memberId) {
        await renderMemberCheckins(container, memberId);
    } else {
        await renderAllCheckins(container);
    }
}

async function renderMemberCheckins(container, memberId) {
    ensureModalStyles();
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header" style="display: flex; justify-content: space-between; align-items: center; gap: 12px;">
                <h2 class="card-title">Lịch Sử Check-in</h2>
                <div style="display: flex; gap: 8px;">
                    <button class="btn btn-secondary" onclick="renderMemberCheckins(document.getElementById('main-content'), ${memberId})" title="Làm mới dữ liệu">🔄</button>
                    <button class="btn btn-success" onclick="quickCheckin(${memberId})">✅ Check In</button>
                </div>
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
    if (!container) return;
    
    if (!checkins || checkins.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><div class="empty-state-text">Chưa có check-in nào</div></div>';
        return;
    }
    
    // Calculate counts
    const countsMap = calculateCheckinCounts(checkins);
    
    let html = '<table><thead><tr><th>ID</th><th>Thời gian vào</th><th>Thời gian ra</th><th>Lần Checkin</th></tr></thead><tbody>';
    
    checkins.forEach(c => {
        const checkinCount = countsMap[c.checkinId] || '-';
        html += `
            <tr>
                <td>${c.checkinId}</td>
                <td>${formatDateTimeWithSeconds(c.checkinTime)}</td>
                <td>${c.checkoutTime ? formatDateTimeWithSeconds(c.checkoutTime) : 'Chưa ra'}</td>
                <td>Lần ${checkinCount}</td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

async function renderAllCheckins(container) {
    const role = getRole();
    const canManage = role === 'Admin';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Check-in</h2>
                <div style="display:flex;gap:8px;">
                    <button class="btn btn-secondary" onclick="reloadCheckinsData()" title="Làm mới dữ liệu">🔄 Làm mới</button>
                    ${canManage ? '<button class="btn btn-primary" onclick="showManualCheckinModal()">➕ Check-in thủ công</button>' : ''}
                </div>
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
        
        // Fetch ALL checkins once and cache for count calculation
        if (!fullCheckinsCache) {
            const allData = await apiFetch(`/api/Checkin?pageNumber=1&pageSize=10000`);
            fullCheckinsCache = allData.data || [];
            checkinsCountsCache = calculateCheckinCounts(fullCheckinsCache);
        }
        
        // For display, use the requested page
        const data = await apiFetch(`/api/Checkin?pageNumber=${checkinsCurrentPage}&pageSize=${checkinsPageSize}`);
        
        hideLoading();
        
        await renderCheckinsTable(data, checkinsCountsCache);
        renderCheckinsPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách check-in: ' + error.message);
    }
}

// Function to clear cache and reload (call after new checkin)
function reloadCheckinsData() {
    fullCheckinsCache = null;
    checkinsCountsCache = null;
    loadCheckins();
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
        
        // Ensure we have the full dataset cached for count calculation
        if (!fullCheckinsCache) {
            const allData = await apiFetch(`/api/Checkin?pageNumber=1&pageSize=10000`);
            fullCheckinsCache = allData.data || [];
            checkinsCountsCache = calculateCheckinCounts(fullCheckinsCache);
        }
        
        // Fetch filtered data
        const data = await apiFetch(`/api/Checkin/date/${date}`);
        hideLoading();
        
        await renderCheckinsTable({ data: data, pageNumber: 1, totalPages: 1 }, checkinsCountsCache);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải check-in: ' + error.message);
    }
}

async function renderCheckinsTable(data, countsMap = {}) {
    const container = document.getElementById('checkinsTableContainer');
    if (!container) return;
    
    if (!data || !data.data || data.data.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><div class="empty-state-text">Không có check-in nào</div></div>';
        return;
    }
    
    // Fetch all member names in parallel
    const checkins = data.data;
    const memberIds = [...new Set(checkins.map(c => c.memberId))];
    await Promise.all(memberIds.map(id => fetchCheckinMemberName(id)));
    
    // Note: Do NOT recalculate counts from filtered set - this breaks continuity
    // Always use the passed countsMap which represents full dataset counts
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Member ID</th>
                    <th>Tên Member</th>
                    <th>Thời gian vào</th>
                    <th>Thời gian ra</th>
                    <th>Lần Checkin</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    for (const c of checkins) {
        const memberName = await fetchCheckinMemberName(c.memberId);
        const checkinCount = countsMap[c.checkinId] || '-';
        
        html += `
            <tr>
                <td>${c.checkinId}</td>
                <td>${c.memberId}</td>
                <td>${escapeHtml(memberName)}</td>
                <td>${formatDateTimeWithSeconds(c.checkinTime)}</td>
                <td>${c.checkoutTime ? formatDateTimeWithSeconds(c.checkoutTime) : 'Chưa ra'}</td>
                <td>Lần ${checkinCount}</td>
            </tr>
        `;
    }
    
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

async function showManualCheckinModal() {
    try {
        showLoading();
        
        // Fetch members list
        const membersData = await apiFetch('/api/Member?pageNumber=1&pageSize=100');
        
        hideLoading();
        
        // Use defensive accessor for items
        const members = membersData?.data || membersData?.items || [];
        
        if (members.length === 0) {
            showError('Không tìm thấy member nào trong hệ thống');
            return;
        }
        
        ensureModalStyles();
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal">
                <div class="gym-modal-header" style="display: flex; justify-content: space-between; align-items: center;">
                    <h3>Check-in Thủ Công</h3>
                    <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()" style="background: none; border: none; font-size: 24px; cursor: pointer; color: #999;">&times;</button>
                </div>
                <div class="gym-modal-body">
                    <form id="manualCheckinForm">
                        <div class="form-group">
                            <label for="memberSelect">Chọn Member:</label>
                            <select id="memberSelect" name="memberId" required style="width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;">
                                <option value="">-- Chọn member --</option>
                                ${members.map(m => `
                                    <option value="${m.memberId}">
                                        ${escapeHtml(m.fullName || m.name || 'N/A')} (ID: ${m.memberId})
                                    </option>
                                `).join('')}
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label for="checkinTimeInput">Thời gian check-in:</label>
                            <input type="datetime-local" id="checkinTimeInput" name="checkinTime" required style="width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;">
                        </div>
                        
                        <div class="gym-modal-buttons">
                            <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                            <button type="submit" class="btn btn-primary">✅ Check-in</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // Set default time to now
        const now = new Date();
        const offset = now.getTimezoneOffset() * 60000;
        const localISOTime = (new Date(now - offset)).toISOString().slice(0, 16);
        document.getElementById('checkinTimeInput').value = localISOTime;
        
        // Handle form submission
        document.getElementById('manualCheckinForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            await submitManualCheckin();
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách member: ' + error.message);
    }
}

// Submit manual check-in form
async function submitManualCheckin() {
    const form = document.getElementById('manualCheckinForm');
    const memberId = parseInt(form.querySelector('#memberSelect').value);
    const checkinTime = form.querySelector('#checkinTimeInput').value;
    
    if (!memberId || !checkinTime) {
        showError('Vui lòng điền đầy đủ thông tin');
        return;
    }
    
    try {
        showLoading();
        
        await apiFetch('/api/Checkin/manual', {
            method: 'POST',
            body: JSON.stringify({
                memberId: memberId,
                checkinTime: new Date(checkinTime).toISOString()
            })
        });
        
        hideLoading();
        showToast('✅ Check-in thành công!', 'success');
        
        // Close modal
        document.querySelector('.gym-modal-overlay').remove();
        
        // Reload checkins
        reloadCheckinsData();
        
    } catch (error) {
        hideLoading();
        showError('Lỗi check-in: ' + error.message);
    }
}
