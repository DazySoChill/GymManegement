/**
 * Dashboard Module - Role-specific dashboard
 */

async function renderDashboard(container) {
    const role = getRole();
    
    if (role === 'Admin') {
        await renderAdminDashboard(container);
    } else if (role === 'Trainer') {
        await renderTrainerDashboard(container);
    } else if (role === 'Member') {
        await renderMemberDashboard(container);
    }
}

/**
 * Admin Dashboard
 */
async function renderAdminDashboard(container) {
    container.innerHTML = `
        <h1>Dashboard - Admin</h1>
        <div id="statsGrid" class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Tổng Members Hoạt Động</div>
                <div class="stat-value" id="activeMembersCount">-</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Doanh Thu Tháng Này</div>
                <div class="stat-value" id="monthlyRevenue">-</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Gói Tập Sắp Hết Hạn</div>
                <div class="stat-value" id="expiringCount">-</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Check-in Hôm Nay</div>
                <div class="stat-value" id="todayCheckins">-</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Check-in Gần Đây</h3>
            </div>
            <div id="recentCheckins"></div>
        </div>
    `;
    
    try {
        // Load active members count
        const activeMembers = await apiFetch('/api/Report/active-members');
        document.getElementById('activeMembersCount').textContent = activeMembers || 0;
        
        // Load monthly revenue
        const now = new Date();
        const revenue = await apiFetch(`/api/Report/revenue?month=${now.getMonth() + 1}&year=${now.getFullYear()}`);
        document.getElementById('monthlyRevenue').textContent = formatCurrency(revenue || 0);
        
        // Load expiring memberships
        const expiring = await apiFetch('/api/Report/expiring-soon?daysAhead=7');
        document.getElementById('expiringCount').textContent = expiring ? expiring.length : 0;
        
        // Load today's checkins
        const today = new Date().toISOString().split('T')[0];
        const checkins = await apiFetch(`/api/Checkin/date/${today}`);
        document.getElementById('todayCheckins').textContent = checkins ? checkins.length : 0;
        
        // Load recent checkins
        const recentCheckins = await apiFetch('/api/Checkin?pageNumber=1&pageSize=5');
        renderRecentCheckinsTable(recentCheckins);
        
    } catch (error) {
        showError('Lỗi tải dữ liệu dashboard: ' + error.message);
    }
}

/**
 * Trainer Dashboard
 */
async function renderTrainerDashboard(container) {
    container.innerHTML = `
        <h1>Dashboard - Huấn Luyện Viên</h1>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Lịch Tập Hôm Nay</div>
                <div class="stat-value" id="todaySchedules">-</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Buổi Tập Gần Đây</div>
                <div class="stat-value" id="recentSessions">-</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Lịch Tập Hôm Nay</h3>
            </div>
            <div id="todaySchedulesList"></div>
        </div>
    `;
    
    try {
        const today = new Date().toISOString().split('T')[0];
        const schedules = await apiFetch(`/api/Schedule/date/${today}`);
        document.getElementById('todaySchedules').textContent = schedules ? schedules.length : 0;
        
        const sessions = await apiFetch('/api/Session?pageNumber=1&pageSize=10');
        document.getElementById('recentSessions').textContent = sessions && sessions.items ? sessions.items.length : 0;
        
        renderSchedulesList(schedules);
    } catch (error) {
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

/**
 * Member Dashboard
 */
async function renderMemberDashboard(container) {
    const memberId = getMemberId();
    
    container.innerHTML = `
        <h1>Dashboard - Member</h1>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Trạng Thái Gói Tập</div>
                <div class="stat-value" id="membershipStatus">-</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Số Ngày Còn Lại</div>
                <div class="stat-value" id="daysRemaining">-</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Gói Tập Của Tôi</h3>
            </div>
            <div id="myMembership"></div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Buổi Tập Sắp Tới</h3>
            </div>
            <div id="upcomingSessions"></div>
        </div>
    `;
    
    if (!memberId) {
        showError('Không tìm thấy thông tin member');
        return;
    }
    
    try {
        // Load active membership
        const membership = await apiFetch(`/api/Membership/member/${memberId}/active`).catch(() => null);
        if (membership) {
            document.getElementById('membershipStatus').textContent = 'Đang hoạt động';
            document.getElementById('daysRemaining').textContent = membership.daysRemaining || 0;
            renderMembershipDetails(membership);
        } else {
            document.getElementById('membershipStatus').textContent = 'Chưa có gói';
            document.getElementById('daysRemaining').textContent = '0';
            document.getElementById('myMembership').innerHTML = '<p>Bạn chưa có gói tập nào.</p>';
        }
        
        // Load upcoming sessions
        const sessions = await apiFetch(`/api/Session/member/${memberId}`);
        renderUpcomingSessions(sessions);
        
    } catch (error) {
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

function renderRecentCheckinsTable(data) {
    const container = document.getElementById('recentCheckins');
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<p class="empty-state-text">Chưa có check-in nào</p>';
        return;
    }
    
    let html = '<table><thead><tr><th>Member</th><th>Thời gian vào</th><th>Thời gian ra</th></tr></thead><tbody>';
    data.items.forEach(item => {
        html += `<tr>
            <td>${escapeHtml(item.memberName || '-')}</td>
            <td>${formatDateTime(item.checkinTime)}</td>
            <td>${item.checkoutTime ? formatDateTime(item.checkoutTime) : 'Chưa ra'}</td>
        </tr>`;
    });
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderSchedulesList(schedules) {
    const container = document.getElementById('todaySchedulesList');
    if (!schedules || schedules.length === 0) {
        container.innerHTML = '<p class="empty-state-text">Không có lịch tập hôm nay</p>';
        return;
    }
    
    let html = '<table><thead><tr><th>Lớp</th><th>Thời gian</th><th>Phòng</th></tr></thead><tbody>';
    schedules.forEach(item => {
        html += `<tr>
            <td>${escapeHtml(item.className)}</td>
            <td>${formatDateTime(item.startTime)} - ${formatDateTime(item.endTime)}</td>
            <td>${escapeHtml(item.facilityName || '-')}</td>
        </tr>`;
    });
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderMembershipDetails(membership) {
    const container = document.getElementById('myMembership');
    container.innerHTML = `
        <p><strong>Gói:</strong> ${escapeHtml(membership.packageName)}</p>
        <p><strong>Ngày bắt đầu:</strong> ${formatDate(membership.startDate)}</p>
        <p><strong>Ngày kết thúc:</strong> ${formatDate(membership.endDate)}</p>
        <p><strong>Số ngày còn lại:</strong> ${membership.daysRemaining} ngày</p>
        <p><strong>Giá:</strong> ${formatCurrency(membership.price)}</p>
    `;
}

function renderUpcomingSessions(sessions) {
    const container = document.getElementById('upcomingSessions');
    if (!sessions || sessions.length === 0) {
        container.innerHTML = '<p class="empty-state-text">Chưa đăng ký buổi tập nào</p>';
        return;
    }
    
    let html = '<table><thead><tr><th>Lịch</th><th>Ngày đăng ký</th><th>Trạng thái</th></tr></thead><tbody>';
    sessions.forEach(item => {
        const badge = item.status === 'Attended' ? 'badge-success' : 
                     item.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
        html += `<tr>
            <td>Schedule #${item.scheduleId}</td>
            <td>${formatDate(item.registrationDate)}</td>
            <td><span class="badge ${badge}">${item.status}</span></td>
        </tr>`;
    });
    html += '</tbody></table>';
    container.innerHTML = html;
}
