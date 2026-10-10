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

// Cached trainerId to avoid repeated lookups
let _cachedTrainerId = null;

/**
 * Gets the trainer's TrainerId (from Trainers table).
 * Strategy: Fetch all trainers and match by email from JWT token.
 * The JWT token includes user email but not trainerId.
 */
async function getTrainerId() {
    if (_cachedTrainerId !== null) {
        return _cachedTrainerId;
    }
    
    try {
        const user = getUser();
        if (!user || !user.email) {
            console.error('No user email found in JWT');
            return null;
        }
        
        // Fetch all trainers and find by email
        const result = await apiFetch('/api/Trainer?pageNumber=1&pageSize=1000');
        const trainers = result?.Data || [];
        
        const trainer = trainers.find(t => 
            t.Email && t.Email.toLowerCase() === user.email.toLowerCase()
        );
        
        if (trainer) {
            _cachedTrainerId = trainer.TrainerId;
            return trainer.TrainerId;
        }
        
        console.error('No trainer found with email:', user.email);
        return null;
    } catch (error) {
        console.error('Error fetching trainerId:', error);
        return null;
    }
}

async function renderTrainerDashboard(container) {
    const trainerId = await getTrainerId();
    
    if (!trainerId) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Không tìm thấy thông tin trainer</div></div>';
        return;
    }
    
    container.innerHTML = `
        <h1>Dashboard - Huấn Luyện Viên</h1>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Class Hôm Nay</div>
                <div class="stat-value" id="trainerTodayClasses">Đang tải...</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Học Viên Đã Attend (Tháng Này)</div>
                <div class="stat-value" id="trainerMonthlyAttended">Đang tải...</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Check-in Hôm Nay</div>
                <div class="stat-value" id="trainerTodayCheckins">Đang tải...</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Lịch Dạy Hôm Nay</h3>
            </div>
            <div id="todaySchedulesList">Đang tải...</div>
        </div>
    `;
    
    try {
        await Promise.all([
            loadTrainerTodayClasses(trainerId),
            loadTrainerMonthlyAttended(trainerId),
            loadTrainerTodayCheckins()
        ]);
        await loadTodaySchedulesList(trainerId);
    } catch (error) {
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

async function loadTrainerTodayClasses(trainerId) {
    try {
        const result = await apiFetch('/api/Schedule?pageNumber=1&pageSize=1000');
        const schedules = result?.Data || [];
        
        const today = new Date().toISOString().split('T')[0];
        
        const todayClasses = schedules.filter(s => {
            const scheduleDate = new Date(s.StartTime).toISOString().split('T')[0];
            return s.TrainerId === trainerId && scheduleDate === today;
        });
        
        document.getElementById('trainerTodayClasses').textContent = todayClasses.length;
    } catch (error) {
        console.error('Error loading trainer today classes:', error);
        document.getElementById('trainerTodayClasses').textContent = 'Lỗi';
    }
}

async function loadTrainerMonthlyAttended(trainerId) {
    try {
        // Get all schedules for this trainer
        const result = await apiFetch('/api/Schedule?pageNumber=1&pageSize=1000');
        const schedules = result?.Data || [];
        
        const trainerSchedules = schedules.filter(s => s.TrainerId === trainerId);
        const scheduleIds = trainerSchedules.map(s => s.ScheduleId);
        
        // Limit to 50 schedules to avoid overload
        const limitedScheduleIds = scheduleIds.slice(0, 50);
        
        // Get current month/year
        const now = new Date();
        const currentMonth = now.getMonth();
        const currentYear = now.getFullYear();
        
        let attendedCount = 0;
        
        // Fetch sessions for each schedule
        for (const scheduleId of limitedScheduleIds) {
            try {
                const sessions = await apiFetch(`/api/Session/schedule/${scheduleId}`);
                
                // Handle different response shapes
                const sessionArray = Array.isArray(sessions) ? sessions : 
                                   sessions?.Data ? sessions.Data :
                                   sessions?.data ? sessions.data : [];
                
                // Count attended sessions in current month
                const attended = sessionArray.filter(session => {
                    if (session.Status !== 'Attended') return false;
                    
                    const regDate = new Date(session.RegistrationDate);
                    return regDate.getMonth() === currentMonth && 
                           regDate.getFullYear() === currentYear;
                });
                
                attendedCount += attended.length;
            } catch (error) {
                console.error(`Error fetching sessions for schedule ${scheduleId}:`, error);
            }
        }
        
        document.getElementById('trainerMonthlyAttended').textContent = attendedCount;
    } catch (error) {
        console.error('Error loading trainer monthly attended:', error);
        document.getElementById('trainerMonthlyAttended').textContent = 'Lỗi';
    }
}

async function loadTrainerTodayCheckins() {
    try {
        const result = await apiFetch('/api/Checkin?pageNumber=1&pageSize=1000');
        const checkins = result?.Data || [];
        
        const today = new Date().toISOString().split('T')[0];
        
        const todayCheckins = checkins.filter(c => {
            const checkinDate = new Date(c.CheckinTime).toISOString().split('T')[0];
            return checkinDate === today;
        });
        
        document.getElementById('trainerTodayCheckins').textContent = todayCheckins.length;
    } catch (error) {
        console.error('Error loading trainer today checkins:', error);
        document.getElementById('trainerTodayCheckins').textContent = 'Lỗi';
    }
}

async function loadTodaySchedulesList(trainerId) {
    const container = document.getElementById('todaySchedulesList');
    
    try {
        const result = await apiFetch('/api/Schedule?pageNumber=1&pageSize=1000');
        const schedules = result?.Data || [];
        
        const today = new Date().toISOString().split('T')[0];
        
        const todaySchedules = schedules.filter(s => {
            const scheduleDate = new Date(s.StartTime).toISOString().split('T')[0];
            return s.TrainerId === trainerId && scheduleDate === today;
        });
        
        if (todaySchedules.length === 0) {
            container.innerHTML = '<p class="empty-state-text">Không có class nào hôm nay</p>';
            return;
        }
        
        let html = '<table><thead><tr><th>Tên Class</th><th>Thời Gian</th><th>Phòng</th></tr></thead><tbody>';
        
        todaySchedules.forEach(schedule => {
            html += `
                <tr>
                    <td>${escapeHtml(schedule.ClassName)}</td>
                    <td>${formatTime(schedule.StartTime)} - ${formatTime(schedule.EndTime)}</td>
                    <td>${escapeHtml(schedule.FacilityName || '-')}</td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        container.innerHTML = html;
    } catch (error) {
        console.error('Error loading today schedules list:', error);
        container.innerHTML = '<p class="empty-state-text">Lỗi tải danh sách</p>';
    }
}

function formatTime(datetime) {
    if (!datetime) return '-';
    const d = new Date(datetime);
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
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
                <div class="stat-label">Buổi tập sắp tới</div>
                <div class="stat-value" id="nextWorkoutInfo">Đang tải...</div>
            </div>
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
                <h3 class="card-title">5 Lần Check-in Gần Nhất</h3>
            </div>
            <div id="recentMemberCheckins">Đang tải...</div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Gói Tập Của Tôi</h3>
            </div>
            <div id="myMembership"></div>
        </div>
    `;
    
    if (!memberId) {
        showError('Không tìm thấy thông tin member');
        return;
    }
    
    try {
        // Load all data in parallel
        await Promise.all([
            loadActiveMembership(memberId),
            loadNextWorkout(memberId),
            loadRecentMemberCheckins(memberId)
        ]);
        
    } catch (error) {
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

async function loadActiveMembership(memberId) {
    try {
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
    } catch (error) {
        console.error('Error loading membership:', error);
        document.getElementById('membershipStatus').textContent = 'Lỗi tải';
        document.getElementById('daysRemaining').textContent = '-';
    }
}

async function loadRecentMemberCheckins(memberId) {
    const container = document.getElementById('recentMemberCheckins');
    if (!container) return;
    
    try {
        const checkins = await apiFetch(`/api/Checkin/member/${memberId}`);
        
        if (!checkins || checkins.length === 0) {
            container.innerHTML = '<p class="empty-state-text">Chưa có check-in nào</p>';
            return;
        }
        
        // Sort by CheckinTime descending and take first 5
        const recent5 = checkins
            .sort((a, b) => new Date(b.checkinTime) - new Date(a.checkinTime))
            .slice(0, 5);
        
        let html = '<table><thead><tr><th>STT</th><th>Thời gian vào</th><th>Thời gian ra</th><th>Trạng thái</th></tr></thead><tbody>';
        
        recent5.forEach((item, index) => {
            const hasCheckedOut = item.checkoutTime && 
                                 item.checkoutTime !== '' && 
                                 !item.checkoutTime.startsWith('0001-01-01');
            const status = hasCheckedOut ? 'Đã ra' : 'Đang tập';
            const badgeClass = hasCheckedOut ? 'badge-secondary' : 'badge-success';
            
            html += `<tr>
                <td>${index + 1}</td>
                <td>${formatDateTimeWithSeconds(item.checkinTime)}</td>
                <td>${hasCheckedOut ? formatDateTimeWithSeconds(item.checkoutTime) : 'Chưa ra'}</td>
                <td><span class="badge ${badgeClass}">${status}</span></td>
            </tr>`;
        });
        
        html += '</tbody></table>';
        container.innerHTML = html;
        
    } catch (error) {
        console.error('Error loading recent checkins:', error);
        container.innerHTML = '<p class="empty-state-text">Lỗi tải check-in</p>';
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
            el.innerHTML = '<small>Không có buổi tập nào sắp tới</small>';
            return;
        }
        const now = new Date();
        const currentDay = now.getDay();
        const currentTime = now.getHours() * 60 + now.getMinutes();
        const activeSchedules = schedules.filter(s => s.isActive !== false);
        
        if (activeSchedules.length === 0) {
            el.innerHTML = '<small>Không có buổi tập nào sắp tới</small>';
            return;
        }
        
        let nextSchedule = null;
        let minDiff = Infinity;
        activeSchedules.forEach(function(schedule) {
            const scheduleDay = schedule.dayOfWeek;
            const scheduleTime = parseTimeToMinutes(schedule.startTime);
            let daysUntil = scheduleDay - currentDay;
            if (daysUntil < 0) daysUntil += 7;
            if (daysUntil === 0 && scheduleTime < currentTime) daysUntil = 7;
            const totalMinutes = daysUntil * 24 * 60 + (scheduleTime - currentTime);
            if (totalMinutes >= 0 && totalMinutes < minDiff) {
                minDiff = totalMinutes;
                nextSchedule = schedule;
            }
        });
        if (nextSchedule) {
            const startTime = formatTimeSpan(nextSchedule.startTime);
            const endTime = formatTimeSpan(nextSchedule.endTime);
            el.innerHTML = '<small>' + nextSchedule.dayOfWeekName + '<br>' + startTime + ' - ' + endTime + '</small>';
        } else {
            el.innerHTML = '<small>Không có buổi tập nào sắp tới</small>';
        }
    } catch (error) {
        console.error('Error loading next workout:', error);
        el.innerHTML = '<small>Lỗi tải</small>';
    }
}

