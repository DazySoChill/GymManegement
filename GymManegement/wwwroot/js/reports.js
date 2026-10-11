/**
 * Reports Module (Admin only)
 */

async function renderReports(container) {
    const role = getRole();
    
    if (role !== 'Admin') {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔒</div><div class="empty-state-text">Bạn không có quyền truy cập trang này</div></div>';
        return;
    }
    
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();
    
    container.innerHTML = `
        <h1>Báo Cáo & Thống Kê</h1>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Tổng Members Hoạt Động</div>
                <div class="stat-value" id="reportActiveMembersCount">-</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Doanh Thu Tháng ${currentMonth}/${currentYear}</div>
                <div class="stat-value" id="reportMonthlyRevenue">-</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Doanh Thu Chi Tiết</h3>
            </div>
            <div class="filters">
                <select id="revenueMonth">
                    ${generateMonthOptions(currentMonth)}
                </select>
                <select id="revenueYear">
                    ${generateYearOptions(currentYear)}
                </select>
                <button class="btn btn-info" onclick="loadRevenueDetails()">🔍 Xem</button>
                <button class="btn btn-success" onclick="exportRevenue()">📥 Export Excel</button>
            </div>
            <div id="revenueDetailsContainer"></div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Gói Tập Sắp Hết Hạn</h3>
            </div>
            <div class="filters">
                <label>Số ngày trước: </label>
                <input type="number" id="daysAhead" value="7" min="1" max="30" style="width: 80px;">
                <button class="btn btn-info" onclick="loadExpiringMemberships()">🔍 Xem</button>
            </div>
            <div id="expiringMembershipsContainer"></div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Báo Cáo Members</h3>
            </div>
            <div id="membersReportContainer"></div>
        </div>
    `;
    
    await loadReportsData();
}

async function loadReportsData() {
    try {
        // Load active members
        const activeMembers = await apiFetch('/api/Report/active-members');
        console.log('Reports - Active Members:', activeMembers);
        document.getElementById('reportActiveMembersCount').textContent = activeMembers || 0;
        
        // Load monthly revenue
        const now = new Date();
        await loadRevenueDetails();
        
        // Load expiring memberships
        await loadExpiringMemberships();
        
        // Load members report
        await loadMembersReport();
        
    } catch (error) {
        console.error('Error loading reports data:', error);
        showError('Lỗi tải báo cáo: ' + error.message);
    }
}

async function loadRevenueDetails() {
    const month = document.getElementById('revenueMonth')?.value || new Date().getMonth() + 1;
    const year = document.getElementById('revenueYear')?.value || new Date().getFullYear();
    
    try {
        showLoading();
        
        // Load revenue summary
        const revenue = await apiFetch(`/api/Report/revenue?month=${month}&year=${year}`);
        console.log('Revenue Summary - API Response:', revenue);
        document.getElementById('reportMonthlyRevenue').textContent = formatCurrency(revenue || 0);
        
        // Load revenue details
        const response = await apiFetch(`/api/Report/revenue/detail?month=${month}&year=${year}`);
        console.log('Revenue Details - API Response:', response);
        
        // Backend returns { month, year, data: [...] } wrapper
        const details = response?.data || response?.Data || [];
        console.log('Revenue Details - Details array:', details);
        
        hideLoading();
        
        const container = document.getElementById('revenueDetailsContainer');
        if (details.length === 0) {
            container.innerHTML = '<p class="empty-state-text">Không có dữ liệu doanh thu</p>';
            return;
        }
        
        let html = '<table><thead><tr><th>Ngày</th><th>Số lượng</th><th>Tổng tiền</th></tr></thead><tbody>';
        details.forEach(item => {
            // Support both aggregated format (date, count, totalAmount) 
            // and detailed format (invoiceDate, totalAmount)
            const displayDate = item.date || item.invoiceDate || item.InvoiceDate;
            const displayCount = item.count || '-';
            const displayAmount = item.totalAmount || item.TotalAmount || 0;
            
            html += `
                <tr>
                    <td>${formatDate(displayDate)}</td>
                    <td>${displayCount}</td>
                    <td>${formatCurrency(displayAmount)}</td>
                </tr>
            `;
        });
        html += '</tbody></table>';
        container.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        console.error('Error loading revenue details:', error);
        const container = document.getElementById('revenueDetailsContainer');
        container.innerHTML = `<p class="empty-state-text">Lỗi tải doanh thu: ${escapeHtml(error.message)}</p>`;
    }
}

async function loadExpiringMemberships() {
    const daysAhead = document.getElementById('daysAhead')?.value || 7;
    
    try {
        showLoading();
        const response = await apiFetch(`/api/Report/expiring-soon?daysAhead=${daysAhead}`);
        console.log('Expiring Memberships - API Response:', response);
        
        // Backend returns { daysAhead, data: [...] } wrapper
        const data = response?.data || response?.Data || [];
        console.log('Expiring Memberships - Data array:', data);
        
        hideLoading();
        
        const container = document.getElementById('expiringMembershipsContainer');
        if (data.length === 0) {
            container.innerHTML = '<p class="empty-state-text">Không có gói tập nào sắp hết hạn</p>';
            return;
        }
        
        let html = '<table><thead><tr><th>Member</th><th>Gói</th><th>Ngày hết hạn</th><th>Còn lại</th></tr></thead><tbody>';
        data.forEach(item => {
            // Backend returns Membership entity with camelCase
            const memberName = item.member?.fullName || item.Member?.FullName || '-';
            const packageName = item.packageName || item.PackageName;
            const endDate = item.endDate || item.EndDate;
            
            // Calculate days remaining
            const today = new Date();
            const end = new Date(endDate);
            const daysRemaining = Math.ceil((end - today) / (1000 * 60 * 60 * 24));
            
            html += `
                <tr>
                    <td>${escapeHtml(memberName)}</td>
                    <td>${escapeHtml(packageName)}</td>
                    <td>${formatDate(endDate)}</td>
                    <td><span class="badge badge-warning">${daysRemaining} ngày</span></td>
                </tr>
            `;
        });
        html += '</tbody></table>';
        container.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        console.error('Error loading expiring memberships:', error);
        const container = document.getElementById('expiringMembershipsContainer');
        container.innerHTML = `<p class="empty-state-text">Lỗi tải gói tập sắp hết hạn: ${escapeHtml(error.message)}</p>`;
    }
}

async function loadMembersReport() {
    try {
        showLoading();
        const stats = await apiFetch('/api/Report/members');
        console.log('Members Report - API Response:', stats);
        hideLoading();
        
        const container = document.getElementById('membersReportContainer');
        if (!stats) {
            container.innerHTML = '<p class="empty-state-text">Không có dữ liệu members</p>';
            return;
        }
        
        // Backend returns stats object { totalMembers, activeMembers, inactiveMembers }
        // Display as stats cards instead of table
        const totalMembers = stats.totalMembers || stats.TotalMembers || 0;
        const activeMembers = stats.activeMembers || stats.ActiveMembers || 0;
        const inactiveMembers = stats.inactiveMembers || stats.InactiveMembers || 0;
        
        container.innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-label">Tổng Members</div>
                    <div class="stat-value">${totalMembers}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Members Hoạt Động</div>
                    <div class="stat-value">${activeMembers}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Members Đã Xóa</div>
                    <div class="stat-value">${inactiveMembers}</div>
                </div>
            </div>
        `;
        
    } catch (error) {
        hideLoading();
        console.error('Error loading members report:', error);
        const container = document.getElementById('membersReportContainer');
        container.innerHTML = `<p class="empty-state-text">Lỗi tải báo cáo members: ${escapeHtml(error.message)}</p>`;
    }
}

async function exportRevenue() {
    const month = document.getElementById('revenueMonth')?.value || new Date().getMonth() + 1;
    const year = document.getElementById('revenueYear')?.value || new Date().getFullYear();
    
    try {
        showLoading();
        const token = getToken();
        const url = `${API_BASE}/api/Report/revenue/export?month=${month}&year=${year}`;
        
        // Download file
        const response = await fetch(url, {
            headers: {
                'Authorization': 'Bearer ' + token
            }
        });
        
        if (!response.ok) {
            throw new Error('Export failed');
        }
        
        const blob = await response.blob();
        const downloadUrl = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = downloadUrl;
        a.download = `Revenue_${month}_${year}.xlsx`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(downloadUrl);
        
        hideLoading();
        showSuccess('Export thành công');
        
    } catch (error) {
        hideLoading();
        showError('Lỗi export: ' + error.message);
    }
}

function generateMonthOptions(currentMonth) {
    let options = '';
    for (let i = 1; i <= 12; i++) {
        const selected = i === currentMonth ? 'selected' : '';
        options += `<option value="${i}" ${selected}>Tháng ${i}</option>`;
    }
    return options;
}

function generateYearOptions(currentYear) {
    let options = '';
    for (let i = currentYear - 2; i <= currentYear + 1; i++) {
        const selected = i === currentYear ? 'selected' : '';
        options += `<option value="${i}" ${selected}>${i}</option>`;
    }
    return options;
}
