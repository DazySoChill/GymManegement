/**
 * Dashboard Module - Role-specific dashboard
 */

async function renderDashboard(container) {
    const role = getRole();
    
    if (isAdmin()) {
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
                <div class="stat-value" id="activeMembersCount">Đang tải...</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Doanh Thu Tháng Này</div>
                <div class="stat-value" id="monthlyRevenue">Đang tải...</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Check-in Hôm Nay</div>
                <div class="stat-value" id="todayCheckins">Đang tải...</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Cơ Sở Vật Chất Hoạt Động</div>
                <div class="stat-value" id="activeFacilitiesCount">Đang tải...</div>
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
        // Load all stats in parallel
        await Promise.all([
            loadActiveMembersCount(),
            loadMonthlyRevenue(),
            loadTodayCheckins(),
            loadActiveFacilities()
        ]);
        
        // Load recent checkins
        const recentCheckins = await apiFetch('/api/Checkin?pageNumber=1&pageSize=10');
        renderRecentCheckinsTable(recentCheckins);
        
    } catch (error) {
        showError('Lỗi tải dữ liệu dashboard: ' + error.message);
    }
}

/**
 * Load Active Members Count
 */
async function loadActiveMembersCount() {
    try {
        // Fetch first page to get Total count from PagedResult
        const result = await apiFetch('/api/Member?pageNumber=1&pageSize=1');
        // Backend returns PagedResult with PascalCase: { Data, Total, PageNumber, PageSize, TotalPages }
        const count = result?.Total || 0;
        document.getElementById('activeMembersCount').textContent = count;
    } catch (error) {
        console.error('Error loading active members:', error);
        const errorMsg = error.message?.includes('401') || error.message?.includes('403') 
            ? 'Lỗi xác thực' 
            : error.message?.includes('Network') || error.message?.includes('fetch')
            ? 'Lỗi kết nối'
            : 'Lỗi tải dữ liệu';
        document.getElementById('activeMembersCount').textContent = errorMsg;
    }
}

/**
 * Load Monthly Revenue
 * Fetches payments and filters client-side for current month (October 2026).
 */
async function loadMonthlyRevenue() {
    try {
        const now = new Date();
        const currentMonth = now.getMonth(); // 0-indexed (October = 9)
        const currentYear = now.getFullYear(); // 2026
        
        // Fetch payments (up to 1000 records - sufficient for most gyms)
        const result = await apiFetch('/api/Payment?pageNumber=1&pageSize=1000');
        // Backend returns PagedResult with PascalCase: { Data, Total, PageNumber, PageSize, TotalPages }
        const payments = result?.Data || [];
        
        // Filter by current month and sum Amount
        const monthlyTotal = payments
            .filter(p => {
                const paymentDate = new Date(p.PaymentDate);
                return paymentDate.getMonth() === currentMonth && 
                       paymentDate.getFullYear() === currentYear;
            })
            .reduce((sum, p) => sum + (p.Amount || 0), 0);
        
        document.getElementById('monthlyRevenue').textContent = formatCurrency(monthlyTotal);
    } catch (error) {
        console.error('Error loading monthly revenue:', error);
        const errorMsg = error.message?.includes('401') || error.message?.includes('403') 
            ? 'Lỗi xác thực' 
            : error.message?.includes('Network') || error.message?.includes('fetch')
            ? 'Lỗi kết nối'
            : 'Lỗi tải dữ liệu';
        document.getElementById('monthlyRevenue').textContent = errorMsg;
    }
}

/**
 * Load Today's Checkins Count
 * Fetches checkins and filters client-side for today (2026-10-09).
 */
async function loadTodayCheckins() {
    try {
        const today = new Date();
        const todayStr = today.toISOString().split('T')[0]; // Format: YYYY-MM-DD
        
        // Fetch checkins (up to 1000 records - sufficient for most gyms)
        const result = await apiFetch('/api/Checkin?pageNumber=1&pageSize=1000');
        // Backend returns PagedResult with PascalCase: { Data, Total, PageNumber, PageSize, TotalPages }
        const checkins = result?.Data || [];
        
        // Filter by today's date
        const todayCount = checkins.filter(c => {
            const checkinDate = new Date(c.CheckinTime).toISOString().split('T')[0];
            return checkinDate === todayStr;
        }).length;
        
        document.getElementById('todayCheckins').textContent = todayCount;
    } catch (error) {
        console.error('Error loading today checkins:', error);
        const errorMsg = error.message?.includes('401') || error.message?.includes('403') 
            ? 'Lỗi xác thực' 
            : error.message?.includes('Network') || error.message?.includes('fetch')
            ? 'Lỗi kết nối'
            : 'Lỗi tải dữ liệu';
        document.getElementById('todayCheckins').textContent = errorMsg;
    }
}

/**
 * Load Active Facilities Count
 */
async function loadActiveFacilities() {
    try {
        const result = await apiFetch('/api/Facility?pageNumber=1&pageSize=1');
        // Backend returns PagedResult with PascalCase: { Data, Total, PageNumber, PageSize, TotalPages }
        const count = result?.Total || 0;
        document.getElementById('activeFacilitiesCount').textContent = count;
    } catch (error) {
        console.error('Error loading active facilities:', error);
        const errorMsg = error.message?.includes('401') || error.message?.includes('403') 
            ? 'Lỗi xác thực' 
            : error.message?.includes('Network') || error.message?.includes('fetch')
            ? 'Lỗi kết nối'
            : 'Lỗi tải dữ liệu';
        document.getElementById('activeFacilitiesCount').textContent = errorMsg;
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
            <div class="stat-card">
                <div class="stat-label">Buổi Tập Sắp Tới</div>
                <div class="stat-value" id="nextWorkoutInfo">-</div>
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
        
        // Load next workout from schedule preferences
        await loadNextWorkout(memberId);
        
    } catch (error) {
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

function renderRecentCheckinsTable(data) {
    const container = document.getElementById('recentCheckins');
    if (!data || !data.Data || data.Data.length === 0) {
        container.innerHTML = '<p class="empty-state-text">Chưa có check-in nào</p>';
        return;
    }
    
    // Sort by CheckinTime descending (most recent first) - using PascalCase
    const sortedItems = [...data.Data].sort((a, b) => {
        return new Date(b.CheckinTime) - new Date(a.CheckinTime);
    });
    
    let html = '<table><thead><tr><th>Member</th><th>Thời gian vào</th><th>Thời gian ra</th><th>Trạng thái</th></tr></thead><tbody>';
    sortedItems.forEach(item => {
        // Backend returns PascalCase: MemberName, MemberId, CheckinTime, CheckoutTime
        const memberName = item.MemberName || `Member #${item.MemberId || '-'}`;
        
        // CheckoutTime is nullable (DateTime?) - null means still checked in
        // Also check for C# sentinel dates like "0001-01-01T00:00:00" or empty strings
        const hasCheckedOut = item.CheckoutTime && 
                             item.CheckoutTime !== '' && 
                             !item.CheckoutTime.startsWith('0001-01-01');
        const status = hasCheckedOut ? 'Đã ra' : 'Đang tập';
        const badgeClass = hasCheckedOut ? 'badge-secondary' : 'badge-success';
        
        html += `<tr>
            <td>${escapeHtml(memberName)}</td>
            <td>${formatDateTime(item.CheckinTime)}</td>
            <td>${hasCheckedOut ? formatDateTime(item.CheckoutTime) : 'Chưa ra'}</td>
            <td><span class="badge ${badgeClass}">${status}</span></td>
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

function parseTimeToMinutes(timeSpan) {
    const parts = timeSpan.split(':');
    return parseInt(parts[0]) * 60 + parseInt(parts[1]);
}

function formatTimeSpan(timeSpan) {
    if (typeof timeSpan === 'string') {
        const parts = timeSpan.split(':');
        return parts[0] + ':' + parts[1];
    }
    return String(timeSpan);
}

async function loadNextWorkout(memberId) {
    const el = document.getElementById('nextWorkoutInfo');
    if (!el) return;
    try {
        const schedules = await apiFetch('/api/MemberSchedulePreference/member/' + memberId);
        if (!schedules || schedules.length === 0) {
            el.innerHTML = '<small>Chưa có lịch</small>';
            return;
        }
        const now = new Date();
        const currentDay = now.getDay();
        const currentTime = now.getHours() * 60 + now.getMinutes();
        const activeSchedules = schedules.filter(s => s.isActive !== false);
        let nextSchedule = null;
        let minDiff = Infinity;
        activeSchedules.forEach(function(schedule) {
            const scheduleDay = schedule.dayOfWeek;
            const scheduleTime = parseTimeToMinutes(schedule.startTime);
            let daysUntil = scheduleDay - currentDay;
            if (daysUntil < 0) daysUntil += 7;
            if (daysUntil === 0 && scheduleTime < currentTime) daysUntil = 7;
            const totalMinutes = daysUntil * 24 * 60 + (scheduleTime - currentTime);
            if (totalMinutes < minDiff) {
                minDiff = totalMinutes;
                nextSchedule = schedule;
            }
        });
        if (nextSchedule) {
            const startTime = formatTimeSpan(nextSchedule.startTime);
            const endTime = formatTimeSpan(nextSchedule.endTime);
            const dayName = nextSchedule.dayOfWeekName || ('Thứ ' + (nextSchedule.dayOfWeek === 0 ? 'CN' : (nextSchedule.dayOfWeek + 1)));
            el.innerHTML = '<small>' + dayName + '<br>' + startTime + ' - ' + endTime + '</small>';
        } else {
            el.innerHTML = '<small>Chưa có lịch</small>';
        }
    } catch (error) {
        console.error('Error loading next workout:', error);
        el.innerHTML = '<small>Lỗi tải</small>';
    }
}

