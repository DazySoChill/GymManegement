/**
 * Schedules Management Module
 */

let schedulesCurrentPage = 1;
let schedulesPageSize = 10;

// Helper function to get day of week name
function getDayOfWeekName(dayOfWeek) {
    const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    return days[dayOfWeek] || '';
}

// Format time from HH:MM:SS to HH:MM
function formatTime(timeString) {
    if (!timeString) return '-';
    const parts = timeString.split(':');
    return `${parts[0]}:${parts[1]}`;
}

// Load and render member schedule preferences
async function renderMySchedulePreferences(container, memberId) {
    try {
        showLoading();
        const preferences = await apiFetch(`/api/MemberSchedulePreference/member/${memberId}`);
        hideLoading();
        
        if (!preferences || preferences.length === 0) {
            container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-text">Chưa có lịch tập nào được đăng ký</div></div>';
            return;
        }
        
        // Group by day of week
        const grouped = {};
        preferences.forEach(pref => {
            if (!grouped[pref.dayOfWeek]) {
                grouped[pref.dayOfWeek] = [];
            }
            grouped[pref.dayOfWeek].push(pref);
        });
        
        // Sort days (Monday=1 first, Sunday=0 last)
        const sortedDays = Object.keys(grouped).map(Number).sort((a, b) => {
            if (a === 0) return 1; // Sunday to end
            if (b === 0) return -1;
            return a - b;
        });
        
        let html = '<div class="schedule-preferences">';
        
        sortedDays.forEach(day => {
            html += `<div class="preference-day-group">
                <h4>${getDayOfWeekName(day)}</h4>
                <div class="preference-list">`;
            
            grouped[day].forEach(pref => {
                html += `
                    <div class="preference-item">
                        <span class="preference-time">⏰ ${formatTime(pref.startTime)} - ${formatTime(pref.endTime)}</span>
                        <button class="btn btn-sm btn-danger" onclick="deleteSchedulePreference(${pref.preferenceId})">🗑️ Xóa</button>
                    </div>
                `;
            });
            
            html += '</div></div>';
        });
        
        html += '</div>';
        container.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch tập của tôi: ' + error.message);
    }
}

// Delete a schedule preference
async function deleteSchedulePreference(preferenceId) {
    if (!confirm('Bạn có chắc muốn xóa lịch tập này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/MemberSchedulePreference/${preferenceId}`, {
            method: 'DELETE'
        });
        hideLoading();
        
        showToast('✅ Đã xóa lịch tập!', 'success');
        
        // Reload preferences
        const memberId = getMemberId();
        const container = document.getElementById('mySchedulePreferencesContainer');
        if (container && memberId) {
            await renderMySchedulePreferences(container, memberId);
        }
        
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa lịch tập: ' + error.message);
    }
}

// Show modal to create new schedule preference
function showCreateSchedulePreferenceModal() {
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <div class="gym-modal-header">
                <h3>Đặt Lịch Tập Mới</h3>
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">✕</button>
            </div>
            <div class="gym-modal-body">
                <form id="createSchedulePreferenceForm">
                    <div class="form-group">
                        <label>Chọn ngày trong tuần:</label>
                        <div class="day-checkboxes">
                            <label><input type="checkbox" name="day" value="1"> Thứ Hai</label>
                            <label><input type="checkbox" name="day" value="2"> Thứ Ba</label>
                            <label><input type="checkbox" name="day" value="3"> Thứ Tư</label>
                            <label><input type="checkbox" name="day" value="4"> Thứ Năm</label>
                            <label><input type="checkbox" name="day" value="5"> Thứ Sáu</label>
                            <label><input type="checkbox" name="day" value="6"> Thứ Bảy</label>
                            <label><input type="checkbox" name="day" value="0"> Chủ Nhật</label>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="startTime">Giờ bắt đầu:</label>
                        <input type="time" id="startTime" name="startTime" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="endTime">Giờ kết thúc:</label>
                        <input type="time" id="endTime" name="endTime" required>
                    </div>
                    
                    <div class="gym-modal-actions">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                        <button type="submit" class="btn btn-primary">💾 Lưu</button>
                    </div>
                </form>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Handle form submission
    document.getElementById('createSchedulePreferenceForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        await submitSchedulePreferences();
    });
}

// Submit new schedule preferences
async function submitSchedulePreferences() {
    const form = document.getElementById('createSchedulePreferenceForm');
    const checkedDays = Array.from(form.querySelectorAll('input[name="day"]:checked')).map(cb => parseInt(cb.value));
    const startTime = form.querySelector('#startTime').value;
    const endTime = form.querySelector('#endTime').value;
    
    if (checkedDays.length === 0) {
        showError('Vui lòng chọn ít nhất một ngày');
        return;
    }
    
    if (!startTime || !endTime) {
        showError('Vui lòng nhập giờ bắt đầu và kết thúc');
        return;
    }
    
    if (startTime >= endTime) {
        showError('Giờ kết thúc phải sau giờ bắt đầu');
        return;
    }
    
    const memberId = getMemberId();
    if (!memberId) {
        showError('Không tìm thấy thông tin member');
        return;
    }
    
    try {
        showLoading();
        
        // Create preference for each selected day
        for (const dayOfWeek of checkedDays) {
            await apiFetch('/api/MemberSchedulePreference', {
                method: 'POST',
                body: JSON.stringify({
                    memberId: memberId,
                    dayOfWeek: dayOfWeek,
                    startTime: startTime + ':00',
                    endTime: endTime + ':00'
                })
            });
        }
        
        hideLoading();
        showToast('✅ Đã đặt lịch tập thành công!', 'success');
        
        // Close modal
        document.querySelector('.gym-modal-overlay').remove();
        
        // Reload preferences
        const container = document.getElementById('mySchedulePreferencesContainer');
        if (container) {
            await renderMySchedulePreferences(container, memberId);
        }
        
    } catch (error) {
        hideLoading();
        showError('Lỗi đặt lịch tập: ' + error.message);
    }
}

async function renderSchedules(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if (role === 'Member' || role === 'Trainer') {
        // Member/Trainer view - Show both personal schedule preferences and registered classes
        container.innerHTML = `
            <div class="card">
                <div class="card-header">
                    <h2 class="card-title">Lịch Tập</h2>
                </div>
                
                <!-- Personal Schedule Preferences -->
                <div style="padding: 20px; border-bottom: 2px solid #e0e0e0;">
                    <h3 style="margin: 0 0 16px 0; color: #2c3e50;">📅 Lịch Tập Cá Nhân</h3>
                    <div id="personalSchedulesContainer">
                        <div style="text-align: center; padding: 20px;">
                            <div class="spinner"></div>
                        </div>
                    </div>
                </div>
                
                <!-- Registered Classes -->
                <div style="padding: 20px;">
                    <h3 style="margin: 0 0 16px 0; color: #2c3e50;">🏋️ Lớp Đã Đăng Ký</h3>
                    <div id="registeredClassesContainer">
                        <div style="text-align: center; padding: 20px;">
                            <div class="spinner"></div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        await Promise.all([
            loadPersonalSchedules(memberId),
            loadRegisteredClasses(memberId)
        ]);
        
    } else {
        // Admin view
        const canManage = role === 'Admin';
        container.innerHTML = `
            <div class="card">
                <div class="card-header">
                    <h2 class="card-title">Lịch Tập</h2>
                    ${canManage ? '<button class="btn btn-primary" onclick="showCreateScheduleModal()">➕ Thêm lịch</button>' : ''}
                </div>
                
                <div class="filters">
                    <input type="date" id="scheduleDate" onchange="loadSchedulesByDate()">
                    <button class="btn btn-info" onclick="loadSchedules()">🔍 Tất cả</button>
                </div>
                
                <div class="table-container" id="schedulesTableContainer"></div>
                <div id="schedulesPagination" class="pagination"></div>
            </div>
        `;
        
        await loadSchedules();
    }
}

// Load personal schedule preferences (recurring by day of week)
async function loadPersonalSchedules(memberId) {
    const container = document.getElementById('personalSchedulesContainer');
    if (!container) return;
    
    try {
        const preferences = await apiFetch(`/api/MemberSchedulePreference/member/${memberId}`);
        
        if (!preferences || preferences.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📅</div>
                    <div class="empty-state-text">Chưa có lịch tập cá nhân. Vào trang "Lịch tập của tôi" để tạo.</div>
                </div>`;
            return;
        }
        
        // Group by day of week
        const grouped = {};
        preferences.forEach(pref => {
            if (!grouped[pref.dayOfWeek]) {
                grouped[pref.dayOfWeek] = [];
            }
            grouped[pref.dayOfWeek].push(pref);
        });
        
        // Sort days (Monday=1 first, Sunday=0 last)
        const sortedDays = Object.keys(grouped).map(Number).sort((a, b) => {
            if (a === 0) return 1; // Sunday to end
            if (b === 0) return -1;
            return a - b;
        });
        
        let html = '<div class="personal-schedules" style="display: grid; gap: 12px;">';
        
        sortedDays.forEach(day => {
            const dayName = getDayOfWeekName(day);
            html += `<div class="day-group" style="background: #f8f9fa; padding: 12px; border-radius: 6px; border-left: 4px solid #3498db;">`;
            html += `<strong style="color: #2c3e50;">${dayName}</strong><div style="margin-top: 8px; display: flex; flex-wrap: wrap; gap: 8px;">`;
            
            grouped[day].forEach(pref => {
                const startTime = formatTime(pref.startTime);
                const endTime = formatTime(pref.endTime);
                html += `
                    <span style="background: white; padding: 6px 12px; border-radius: 4px; border: 1px solid #ddd; font-size: 0.9em;">
                        ⏰ ${startTime} - ${endTime}
                    </span>
                `;
            });
            
            html += '</div></div>';
        });
        
        html += '</div>';
        container.innerHTML = html;
        
    } catch (error) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">⚠️</div>
                <div class="empty-state-text">Lỗi tải lịch cá nhân: ${error.message}</div>
            </div>`;
    }
}

// Load registered classes (specific sessions)
async function loadRegisteredClasses(memberId) {
    const container = document.getElementById('registeredClassesContainer');
    if (!container) return;
    
    try {
        // Get all sessions for this member
        const sessions = await apiFetch(`/api/Session/member/${memberId}`);
        
        // Filter: Only show Registered or Attended (not Cancelled)
        const activeSessions = sessions.filter(s => 
            s.status === 'Registered' || s.status === 'Attended'
        );
        
        if (!activeSessions || activeSessions.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">🏋️</div>
                    <div class="empty-state-text">Chưa đăng ký lớp nào. Vào trang "Đăng ký class" để đăng ký.</div>
                </div>`;
            return;
        }
        
        // Load schedule details for each session
        const scheduleIds = [...new Set(activeSessions.map(s => s.scheduleId))];
        const scheduleMap = {};
        
        await Promise.all(scheduleIds.map(async (scheduleId) => {
            try {
                const schedule = await apiFetch(`/api/Schedule/${scheduleId}`);
                scheduleMap[scheduleId] = schedule;
            } catch (error) {
                console.error(`Error loading schedule ${scheduleId}:`, error);
            }
        }));
        
        // Sort by schedule start time (nearest first)
        activeSessions.sort((a, b) => {
            const scheduleA = scheduleMap[a.scheduleId];
            const scheduleB = scheduleMap[b.scheduleId];
            if (!scheduleA || !scheduleB) return 0;
            return new Date(scheduleA.startTime) - new Date(scheduleB.startTime);
        });
        
        // Render as cards
        let html = '<div class="registered-classes" style="display: grid; gap: 12px;">';
        
        activeSessions.forEach(session => {
            const schedule = scheduleMap[session.scheduleId];
            if (!schedule) return;
            
            const now = new Date();
            const startTime = new Date(schedule.startTime);
            const isPast = startTime < now;
            
            const statusBadge = session.status === 'Attended' ? 'badge-success' :
                               session.status === 'Registered' ? 'badge-info' : 'badge-warning';
            
            const statusText = session.status === 'Attended' ? 'Đã tham gia' :
                              session.status === 'Registered' ? 'Đã đăng ký' : session.status;
            
            html += `
                <div class="class-card" style="background: white; border: 1px solid #e0e0e0; border-radius: 6px; padding: 16px; ${isPast ? 'opacity: 0.6;' : ''}">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 10px;">
                        <h4 style="margin: 0; color: #2c3e50;">${escapeHtml(schedule.className)}</h4>
                        <span class="badge ${statusBadge}" style="font-size: 0.85em;">${statusText}</span>
                    </div>
                    
                    <div style="color: #666; font-size: 0.9em; line-height: 1.6;">
                        <div><strong>🏋️ HLV:</strong> ${escapeHtml(schedule.trainerName || '-')}</div>
                        <div><strong>📍 Phòng:</strong> ${escapeHtml(schedule.facilityName || '-')}</div>
                        <div><strong>🕐 Thời gian:</strong> ${formatDateTime(schedule.startTime)}</div>
                    </div>
                    
                    ${session.status === 'Registered' && !isPast ? `
                        <div style="margin-top: 12px; padding-top: 12px; border-top: 1px solid #e0e0e0;">
                            <button class="btn btn-sm btn-danger" onclick="cancelRegisteredClass(${session.sessionId})" style="width: 100%;">
                                ❌ Hủy đăng ký
                            </button>
                        </div>
                    ` : ''}
                    
                    ${isPast ? '<div style="margin-top: 8px; color: #999; font-size: 0.85em;">⏱️ Đã qua</div>' : ''}
                </div>
            `;
        });
        
        html += '</div>';
        container.innerHTML = html;
        
    } catch (error) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">⚠️</div>
                <div class="empty-state-text">Lỗi tải lớp đã đăng ký: ${error.message}</div>
            </div>`;
    }
}

// Member cancels their registered class
async function cancelRegisteredClass(sessionId) {
    if (!confirm('Bạn có chắc muốn hủy lớp này?')) {
        return;
    }
    
    try {
        showLoading();
        
        await apiFetch(`/api/Session/${sessionId}`, {
            method: 'PUT',
            body: JSON.stringify({
                status: 'Cancelled'
            })
        });
        
        hideLoading();
        showToast('✅ Đã hủy lớp!', 'success');
        
        // Reload
        const memberId = getMemberId();
        if (memberId) {
            await loadRegisteredClasses(memberId);
        }
        
    } catch (error) {
        hideLoading();
        showError('Lỗi hủy lớp: ' + error.message);
    }
}

async function loadSchedules() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Schedule?pageNumber=${schedulesCurrentPage}&pageSize=${schedulesPageSize}`);
        hideLoading();
        
        renderSchedulesTable(data);
        renderSchedulesPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch tập: ' + error.message);
    }
}

async function loadSchedulesByDate() {
    const dateInput = document.getElementById('scheduleDate');
    const date = dateInput.value;
    
    if (!date) {
        loadSchedules();
        return;
    }
    
    try {
        showLoading();
        const items = await apiFetch(`/api/Schedule/date/${date}`);
        hideLoading();
        
        renderSchedulesTable({ items, pageNumber: 1, totalPages: 1 });
    } catch (error) {
        hideLoading();
        showError('Lỗi tải lịch tập: ' + error.message);
    }
}

async function renderSchedulesTable(data) {
    const container = document.getElementById('schedulesTableContainer');
    const role = getRole();
    const canManage = role === 'Admin';
    
    const items = data?.Data || data?.data || data?.items || [];
    
    if (!data || items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-text">Không có lịch tập nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Lớp</th>
                    <th>HLV</th>
                    <th>Phòng</th>
                    <th>Bắt đầu</th>
                    <th>Kết thúc</th>
                    <th>Sức chứa</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    items.forEach(schedule => {
        html += `
            <tr>
                <td>${schedule.scheduleId}</td>
                <td>${escapeHtml(schedule.className)}</td>
                <td>${escapeHtml(schedule.trainerName || '-')}</td>
                <td>${escapeHtml(schedule.facilityName || '-')}</td>
                <td>${formatDateTime(schedule.startTime)}</td>
                <td>${formatDateTime(schedule.endTime)}</td>
                <td>${schedule.maxCapacity}</td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-info" onclick="showEditScheduleModal(${schedule.scheduleId})">✏️</button>
                            <button class="btn btn-sm btn-danger" onclick="deleteSchedule(${schedule.scheduleId})">🗑️</button>
                        </div>
                    </td>
                ` : ''}
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderSchedulesPagination(data) {
    const container = document.getElementById('schedulesPagination');
    if (!data) return;
    
    const pageNumber = data?.pageNumber || data?.PageNumber || 1;
    const totalPages = data?.totalPages || data?.TotalPages || 1;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeSchedulesPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeSchedulesPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeSchedulesPage(page) {
    schedulesCurrentPage = page;
    loadSchedules();
}

// Inject modal styles once
function injectScheduleModalStyles() {
    if (document.getElementById('schedule-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'schedule-modal-styles';
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
            max-width: 500px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
        }
        .gym-modal h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: #2c3e50;
        }
        .gym-modal-close {
            position: absolute;
            top: 16px;
            right: 16px;
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #999;
        }
        .gym-modal-close:hover {
            color: #333;
        }
        .form-group {
            margin-bottom: 16px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #3498db;
        }
        .form-group .error {
            color: #e74c3c;
            font-size: 12px;
            margin-top: 4px;
        }
        .form-group input.invalid,
        .form-group select.invalid {
            border-color: #e74c3c;
        }
        .gym-modal-buttons {
            display: flex;
            gap: 12px;
            margin-top: 24px;
            justify-content: flex-end;
        }
        .required {
            color: #e74c3c;
        }
    `;
    document.head.appendChild(style);
}

async function showCreateScheduleModal() {
    injectScheduleModalStyles();
    
    try {
        showLoading();
        // Fetch trainers and facilities for dropdowns
        const [trainersData, facilitiesData] = await Promise.all([
            apiFetch('/api/Trainer?pageNumber=1&pageSize=1000'),
            apiFetch('/api/Facility?pageNumber=1&pageSize=1000')
        ]);
        
        const role = getRole();
        let currentTrainerId = null;
        if (role === 'Trainer') {
            currentTrainerId = await getTrainerId();
            if (!currentTrainerId) {
                hideLoading();
                showError('Không tìm thấy thông tin trainer');
                return;
            }
        }
        
        hideLoading();
        
        const trainers = trainersData?.data || trainersData?.items || [];
        const allFacilities = facilitiesData?.data || facilitiesData?.items || [];
        
        // Filter only Available and Active facilities for scheduling
        const facilities = allFacilities.filter(f => f.status === 'Available' || f.status === 'Active');
        
        console.log('Trainers for scheduling:', trainers);
        console.log('Facilities for scheduling:', facilities);
        console.log('Sample facility:', facilities[0]);
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">&times;</button>
                <h3>➕ Tạo Lịch Tập Mới</h3>
                <form id="createScheduleForm">
                    <div class="form-group">
                        <label>Tên lớp <span class="required">*</span></label>
                        <input type="text" id="className" name="className" required placeholder="VD: Yoga buổi sáng, Cardio tối">
                        <div class="error" id="classNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>Huấn luyện viên <span class="required">*</span></label>
                        <select id="trainerId" name="trainerId" ${role === 'Trainer' ? 'disabled style="background:#f5f5f5;cursor:not-allowed;"' : ''} required>
                            <option value="">-- Chọn HLV --</option>
                            ${trainers.map(t => `<option value="${t.trainerId}" ${role === 'Trainer' && t.trainerId === currentTrainerId ? 'selected' : ''}>${escapeHtml(t.fullName)}</option>`).join('')}
                        </select>
                        ${role === 'Trainer' ? `<input type="hidden" id="trainerIdHidden" value="${currentTrainerId}">` : ''}
                        <div class="error" id="trainerIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Phòng tập <span class="required">*</span></label>
                        <select id="facilityId" name="facilityId" required>
                            <option value="">-- Chọn phòng --</option>
                            ${facilities.map(f => `<option value="${f.facilityId}">${escapeHtml(f.facilityName || f.name || 'Facility ' + f.facilityId)}</option>`).join('')}
                        </select>
                        <div class="error" id="facilityIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Ngày & giờ bắt đầu <span class="required">*</span></label>
                        <input type="datetime-local" id="startTime" name="startTime" required>
                        <div class="error" id="startTimeError"></div>
                    </div>
                    <div class="form-group">
                        <label>Ngày & giờ kết thúc <span class="required">*</span></label>
                        <input type="datetime-local" id="endTime" name="endTime" required>
                        <div class="error" id="endTimeError"></div>
                    </div>
                    <div class="form-group">
                        <label>Sức chứa tối đa <span class="required">*</span></label>
                        <input type="number" id="maxCapacity" name="maxCapacity" value="20" required min="1" max="100">
                        <div class="error" id="maxCapacityError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                        <button type="submit" class="btn btn-primary">Tạo Lịch</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Form submit handler
        const form = document.getElementById('createScheduleForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (!validateScheduleForm()) {
                return;
            }
            
            const trainerId = getRole() === 'Trainer'
                ? parseInt(document.getElementById('trainerIdHidden').value)
                : parseInt(document.getElementById('trainerId').value);
            
            const formData = {
                className: document.getElementById('className').value.trim(),
                trainerId: trainerId,
                facilityId: parseInt(document.getElementById('facilityId').value),
                startTime: new Date(document.getElementById('startTime').value).toISOString(),
                endTime: new Date(document.getElementById('endTime').value).toISOString(),
                maxCapacity: parseInt(document.getElementById('maxCapacity').value)
            };
            
            try {
                showLoading();
                await apiFetch('/api/Schedule', {
                    method: 'POST',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Tạo lịch tập thành công!');
                modal.remove();
                await loadSchedules();
            } catch (error) {
                hideLoading();
                showError('Lỗi tạo lịch tập: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

async function showEditScheduleModal(scheduleId) {
    injectScheduleModalStyles();
    
    try {
        showLoading();
        const [schedule, trainersData, facilitiesData] = await Promise.all([
            apiFetch(`/api/Schedule/${scheduleId}`),
            apiFetch('/api/Trainer?pageNumber=1&pageSize=1000'),
            apiFetch('/api/Facility?pageNumber=1&pageSize=1000')
        ]);
        
        const role = getRole();
        let currentTrainerId = null;
        if (role === 'Trainer') {
            currentTrainerId = await getTrainerId();
        }
        
        hideLoading();
        
        if (!schedule) {
            showError('Không tìm thấy lịch tập');
            return;
        }
        
        const trainers = trainersData?.data || trainersData?.items || [];
        const allFacilities = facilitiesData?.data || facilitiesData?.items || [];
        
        // Filter only Available and Active facilities
        const facilities = allFacilities.filter(f => f.status === 'Available' || f.status === 'Active');
        
        // Convert UTC to local datetime-local format
        const startTimeLocal = new Date(schedule.startTime).toISOString().slice(0, 16);
        const endTimeLocal = new Date(schedule.endTime).toISOString().slice(0, 16);
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">&times;</button>
                <h3>✏️ Sửa Lịch Tập</h3>
                <form id="editScheduleForm">
                    <div class="form-group">
                        <label>Tên lớp <span class="required">*</span></label>
                        <input type="text" id="editClassName" name="className" value="${escapeHtml(schedule.className)}" required>
                        <div class="error" id="editClassNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>Huấn luyện viên <span class="required">*</span></label>
                        <select id="editTrainerId" name="trainerId" ${role === 'Trainer' ? 'disabled style="background:#f5f5f5;cursor:not-allowed;"' : ''} required>
                            <option value="">-- Chọn HLV --</option>
                            ${trainers.map(t => `<option value="${t.trainerId}" ${t.trainerId === schedule.trainerId ? 'selected' : ''}>${escapeHtml(t.fullName)}</option>`).join('')}
                        </select>
                        ${role === 'Trainer' ? `<input type="hidden" id="editTrainerIdHidden" value="${schedule.trainerId}">` : ''}
                        <div class="error" id="editTrainerIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Phòng tập <span class="required">*</span></label>
                        <select id="editFacilityId" name="facilityId" required>
                            <option value="">-- Chọn phòng --</option>
                            ${facilities.map(f => `<option value="${f.facilityId}" ${f.facilityId === schedule.facilityId ? 'selected' : ''}>${escapeHtml(f.facilityName || f.name || 'Facility ' + f.facilityId)}</option>`).join('')}
                        </select>
                        <div class="error" id="editFacilityIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Ngày & giờ bắt đầu <span class="required">*</span></label>
                        <input type="datetime-local" id="editStartTime" name="startTime" value="${startTimeLocal}" required>
                        <div class="error" id="editStartTimeError"></div>
                    </div>
                    <div class="form-group">
                        <label>Ngày & giờ kết thúc <span class="required">*</span></label>
                        <input type="datetime-local" id="editEndTime" name="endTime" value="${endTimeLocal}" required>
                        <div class="error" id="editEndTimeError"></div>
                    </div>
                    <div class="form-group">
                        <label>Sức chứa tối đa <span class="required">*</span></label>
                        <input type="number" id="editMaxCapacity" name="maxCapacity" value="${schedule.maxCapacity}" required min="1" max="100">
                        <div class="error" id="editMaxCapacityError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                        <button type="submit" class="btn btn-primary">Cập Nhật</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Form submit handler
        const form = document.getElementById('editScheduleForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (!validateScheduleForm(true)) {
                return;
            }
            
            const trainerId = getRole() === 'Trainer'
                ? parseInt(document.getElementById('editTrainerIdHidden').value)
                : parseInt(document.getElementById('editTrainerId').value);
            
            const formData = {
                className: document.getElementById('editClassName').value.trim(),
                trainerId: trainerId,
                facilityId: parseInt(document.getElementById('editFacilityId').value),
                startTime: new Date(document.getElementById('editStartTime').value).toISOString(),
                endTime: new Date(document.getElementById('editEndTime').value).toISOString(),
                maxCapacity: parseInt(document.getElementById('editMaxCapacity').value)
            };
            
            try {
                showLoading();
                await apiFetch(`/api/Schedule/${scheduleId}`, {
                    method: 'PUT',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Cập nhật lịch tập thành công!');
                modal.remove();
                await loadSchedules();
            } catch (error) {
                hideLoading();
                showError('Lỗi cập nhật lịch tập: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải thông tin lịch tập: ' + error.message);
    }
}

function validateScheduleForm(isEdit = false) {
    const prefix = isEdit ? 'edit' : '';
    const className = document.getElementById(prefix + 'className');
    const trainerId = document.getElementById(prefix + 'trainerId');
    const facilityId = document.getElementById(prefix + 'facilityId');
    const startTime = document.getElementById(prefix + 'startTime');
    const endTime = document.getElementById(prefix + 'endTime');
    const maxCapacity = document.getElementById(prefix + 'maxCapacity');
    
    let isValid = true;
    
    // Clear previous errors
    document.getElementById(prefix + 'classNameError').textContent = '';
    document.getElementById(prefix + 'trainerIdError').textContent = '';
    document.getElementById(prefix + 'facilityIdError').textContent = '';
    document.getElementById(prefix + 'startTimeError').textContent = '';
    document.getElementById(prefix + 'endTimeError').textContent = '';
    document.getElementById(prefix + 'maxCapacityError').textContent = '';
    className.classList.remove('invalid');
    trainerId.classList.remove('invalid');
    facilityId.classList.remove('invalid');
    startTime.classList.remove('invalid');
    endTime.classList.remove('invalid');
    maxCapacity.classList.remove('invalid');
    
    // Validate class name
    if (!className.value.trim()) {
        document.getElementById(prefix + 'classNameError').textContent = 'Vui lòng nhập tên lớp';
        className.classList.add('invalid');
        isValid = false;
    }
    
    // Validate trainer (skip for Trainer role - trainerId is auto-filled via hidden input)
    if (getRole() !== 'Trainer') {
        if (!trainerId.value) {
            document.getElementById(prefix + 'trainerIdError').textContent = 'Vui lòng chọn HLV';
            trainerId.classList.add('invalid');
            isValid = false;
        }
    }
    
    // Validate facility
    if (!facilityId.value) {
        document.getElementById(prefix + 'facilityIdError').textContent = 'Vui lòng chọn phòng';
        facilityId.classList.add('invalid');
        isValid = false;
    }
    
    // Validate times
    if (!startTime.value) {
        document.getElementById(prefix + 'startTimeError').textContent = 'Vui lòng chọn giờ bắt đầu';
        startTime.classList.add('invalid');
        isValid = false;
    }
    
    if (!endTime.value) {
        document.getElementById(prefix + 'endTimeError').textContent = 'Vui lòng chọn giờ kết thúc';
        endTime.classList.add('invalid');
        isValid = false;
    }
    
    // Validate end time after start time
    if (startTime.value && endTime.value && new Date(endTime.value) <= new Date(startTime.value)) {
        document.getElementById(prefix + 'endTimeError').textContent = 'Giờ kết thúc phải sau giờ bắt đầu';
        endTime.classList.add('invalid');
        isValid = false;
    }
    
    // Validate max capacity
    const capacityValue = parseInt(maxCapacity.value);
    if (!maxCapacity.value || capacityValue < 1 || capacityValue > 100) {
        document.getElementById(prefix + 'maxCapacityError').textContent = 'Sức chứa phải từ 1 đến 100';
        maxCapacity.classList.add('invalid');
        isValid = false;
    }
    
    return isValid;
}

async function deleteSchedule(scheduleId) {
    try {
        if (!confirm('Bạn có chắc chắn muốn xóa lịch tập này?')) {
            return;
        }
        
        showLoading();
        await apiFetch(`/api/Schedule/${scheduleId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa lịch tập thành công!');
        await loadSchedules();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa lịch tập: ' + error.message);
    }
}

