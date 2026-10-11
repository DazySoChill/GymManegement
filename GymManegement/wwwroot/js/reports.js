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
                <div class="stat-label" id="revenueLabel">Doanh Thu Tháng ${currentMonth}/${currentYear}</div>
                <div class="stat-value" id="reportMonthlyRevenue">-</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Doanh Thu Chi Tiết</h3>
            </div>
            <div class="filters">
                <label>Xem theo: </label>
                <select id="revenueType" onchange="updateRevenueFilters()">
                    <option value="month">Tháng</option>
                    <option value="quarter">Quý</option>
                    <option value="year">Năm</option>
                </select>
                
                <span id="monthFilter">
                    <select id="revenueMonth">
                        ${generateMonthOptions(currentMonth)}
                    </select>
                </span>
                
                <span id="quarterFilter" style="display:none;">
                    <select id="revenueQuarter">
                        <option value="1">Quý 1 (T1-T3)</option>
                        <option value="2">Quý 2 (T4-T6)</option>
                        <option value="3">Quý 3 (T7-T9)</option>
                        <option value="4">Quý 4 (T10-T12)</option>
                    </select>
                </span>
                
                <select id="revenueYear">
                    ${generateYearOptions(currentYear)}
                </select>
                <button class="btn btn-info" onclick="loadRevenueDetails()">🔍 Xem</button>
                <button class="btn btn-success" onclick="exportRevenue()">📥 Xuất Excel</button>
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
        const activeMembersResponse = await apiFetch('/api/Report/active-members');
        console.log('Reports - Active Members Response:', activeMembersResponse);
        
        // Handle different response formats
        let activeMembers = 0;
        if (typeof activeMembersResponse === 'number') {
            activeMembers = activeMembersResponse;
        } else if (typeof activeMembersResponse === 'object') {
            // If it's an object, try to extract count
            activeMembers = activeMembersResponse.count || 
                          activeMembersResponse.Count || 
                          activeMembersResponse.value ||
                          activeMembersResponse.Value ||
                          activeMembersResponse.total ||
                          activeMembersResponse.Total || 0;
        }
        
        console.log('Reports - Active Members Count:', activeMembers);
        document.getElementById('reportActiveMembersCount').textContent = activeMembers;
        
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
    const type = document.getElementById('revenueType')?.value || 'month';
    const year = document.getElementById('revenueYear')?.value || new Date().getFullYear();
    
    try {
        showLoading();
        
        let details = [];
        let totalRevenue = 0;
        let label = '';
        
        if (type === 'month') {
            // Load monthly revenue
            const month = document.getElementById('revenueMonth')?.value || new Date().getMonth() + 1;
            
            const revenue = await apiFetch(`/api/Report/revenue?month=${month}&year=${year}`);
            console.log('Revenue Summary - API Response:', revenue);
            
            // Extract total revenue from response
            totalRevenue = revenue?.totalRevenue || revenue?.TotalRevenue || 0;
            
            const response = await apiFetch(`/api/Report/revenue/detail?month=${month}&year=${year}`);
            console.log('Revenue Details - API Response:', response);
            details = response?.data || response?.Data || [];
            
            label = `Doanh Thu Tháng ${month}/${year}`;
            
        } else if (type === 'quarter') {
            // Load quarterly revenue
            const quarter = parseInt(document.getElementById('revenueQuarter')?.value || '1');
            const startMonth = (quarter - 1) * 3 + 1;
            const endMonth = startMonth + 2;
            
            // Load all 3 months in the quarter
            for (let month = startMonth; month <= endMonth; month++) {
                const response = await apiFetch(`/api/Report/revenue/detail?month=${month}&year=${year}`);
                const monthData = response?.data || response?.Data || [];
                details = details.concat(monthData);
                
                const revenue = await apiFetch(`/api/Report/revenue?month=${month}&year=${year}`);
                const monthRevenue = revenue?.totalRevenue || revenue?.TotalRevenue || 0;
                totalRevenue += monthRevenue;
            }
            
            label = `Doanh Thu Quý ${quarter}/${year}`;
            
        } else if (type === 'year') {
            // Load yearly revenue
            for (let month = 1; month <= 12; month++) {
                const response = await apiFetch(`/api/Report/revenue/detail?month=${month}&year=${year}`);
                const monthData = response?.data || response?.Data || [];
                details = details.concat(monthData);
                
                const revenue = await apiFetch(`/api/Report/revenue?month=${month}&year=${year}`);
                const monthRevenue = revenue?.totalRevenue || revenue?.TotalRevenue || 0;
                totalRevenue += monthRevenue;
            }
            
            label = `Doanh Thu Năm ${year}`;
        }
        
        // Update label and value
        document.getElementById('revenueLabel').textContent = label;
        document.getElementById('reportMonthlyRevenue').textContent = formatCurrency(totalRevenue);
        
        console.log('Revenue Details - Details array:', details);
        console.log('Revenue Details - Total:', totalRevenue);
        
        hideLoading();
        
        const container = document.getElementById('revenueDetailsContainer');
        if (details.length === 0) {
            container.innerHTML = '<p class="empty-state-text">Không có dữ liệu doanh thu</p>';
            return;
        }
        
        let html = '<table><thead><tr><th>Ngày</th><th>Số lượng</th><th>Tổng tiền</th></tr></thead><tbody>';
        details.forEach(item => {
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
        html += `<tr class="total-row"><td colspan="2"><strong>TỔNG CỘNG</strong></td><td><strong>${formatCurrency(totalRevenue)}</strong></td></tr>`;
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
    const type = document.getElementById('revenueType')?.value || 'month';
    const year = document.getElementById('revenueYear')?.value || new Date().getFullYear();
    
    try {
        showLoading();
        const token = getToken();
        
        // Build URL based on type
        let url = `${API_BASE}/api/Report/revenue/export?type=${type}&year=${year}`;
        
        if (type === 'month') {
            const month = document.getElementById('revenueMonth')?.value || new Date().getMonth() + 1;
            url += `&month=${month}`;
        } else if (type === 'quarter') {
            const quarter = document.getElementById('revenueQuarter')?.value || '1';
            url += `&quarter=${quarter}`;
        }
        
        console.log('Exporting revenue:', { type, year, url });
        
        // Fetch the file from backend
        const response = await fetch(url, {
            headers: {
                'Authorization': 'Bearer ' + token
            }
        });
        
        console.log('Export response status:', response.status);
        console.log('Export response content-type:', response.headers.get('content-type'));
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('Export error response:', errorText);
            throw new Error(`Export failed: ${response.status} ${response.statusText}`);
        }
        
        const blob = await response.blob();
        console.log('Export blob size:', blob.size, 'type:', blob.type);
        
        // Check if blob has data
        if (blob.size === 0) {
            throw new Error('File xuất ra rỗng. Có thể không có dữ liệu trong khoảng thời gian này.');
        }
        
        // Get filename from Content-Disposition header or generate it
        const contentDisposition = response.headers.get('content-disposition');
        let fileName = `DoanhThu_${year}.xlsx`;
        
        if (contentDisposition) {
            const matches = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/.exec(contentDisposition);
            if (matches && matches[1]) {
                fileName = matches[1].replace(/['"]/g, '');
            }
        } else {
            // Generate filename based on type
            if (type === 'month') {
                const month = document.getElementById('revenueMonth')?.value || new Date().getMonth() + 1;
                fileName = `DoanhThu_Thang${String(month).padStart(2, '0')}_${year}.xlsx`;
            } else if (type === 'quarter') {
                const quarter = document.getElementById('revenueQuarter')?.value || '1';
                fileName = `DoanhThu_Quy${quarter}_${year}.xlsx`;
            } else if (type === 'year') {
                fileName = `DoanhThu_Nam${year}.xlsx`;
            }
        }
        
        // Create download link
        const downloadUrl = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = downloadUrl;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        
        // Cleanup
        setTimeout(() => {
            document.body.removeChild(a);
            window.URL.revokeObjectURL(downloadUrl);
        }, 100);
        
        hideLoading();
        showSuccess('Xuất Excel thành công');
        
    } catch (error) {
        hideLoading();
        console.error('Export error:', error);
        showError('Lỗi xuất Excel: ' + error.message);
    }
}

function exportToCSV(data, fileName) {
    // Remove this function - no longer needed
}

function exportToExcel(data, fileName) {
    // Remove this function - no longer needed
}

function updateRevenueFilters() {
    const type = document.getElementById('revenueType').value;
    const monthFilter = document.getElementById('monthFilter');
    const quarterFilter = document.getElementById('quarterFilter');
    
    if (type === 'month') {
        monthFilter.style.display = 'inline';
        quarterFilter.style.display = 'none';
    } else if (type === 'quarter') {
        monthFilter.style.display = 'none';
        quarterFilter.style.display = 'inline';
        // Set current quarter
        const currentMonth = new Date().getMonth() + 1;
        const currentQuarter = Math.ceil(currentMonth / 3);
        document.getElementById('revenueQuarter').value = currentQuarter;
    } else if (type === 'year') {
        monthFilter.style.display = 'none';
        quarterFilter.style.display = 'none';
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
