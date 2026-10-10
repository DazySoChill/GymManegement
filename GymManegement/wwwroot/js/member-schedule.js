/**
 * Member Schedule Preferences Module
 */

async function renderMemberSchedule(container) {
    const user = getUser();
    const memberId = getMemberId();

    if (!memberId) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">⚠️</div>
                <div class="empty-state-text">Không tìm thấy thông tin hội viên</div>
            </div>`;
        return;
    }

    container.innerHTML = `
        <div class="page-header">
            <h1 class="page-title">📅 Lịch Tập Của Tôi</h1>
        </div>

        <div class="card">
            <div class="card-header">
                <h3>Đặt Lịch Tập Mới</h3>
            </div>
            <div class="card-body">
                <form id="scheduleForm">
                    <div class="form-group">
                        <label>Chọn ngày tập trong tuần:</label>
                        <div id="dayCheckboxes" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; margin-top: 8px;">
                            <label style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" name="day" value="1"> Thứ Hai
                            </label>
                            <label style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" name="day" value="2"> Thứ Ba
                            </label>
                            <label style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" name="day" value="3"> Thứ Tư
                            </label>
                            <label style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" name="day" value="4"> Thứ Năm
                            </label>
                            <label style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" name="day" value="5"> Thứ Sáu
                            </label>
                            <label style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" name="day" value="6"> Thứ Bảy
                            </label>
                            <label style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" name="day" value="0"> Chủ Nhật
                            </label>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="startTime">Giờ bắt đầu:</label>
                            <input type="time" id="startTime" required>
                        </div>
                        <div class="form-group">
                            <label for="endTime">Giờ kết thúc:</label>
                            <input type="time" id="endTime" required>
                        </div>
                    </div>

                    <button type="submit" class="btn btn-primary">💾 Lưu Lịch</button>
                </form>
            </div>
        </div>

        <div class="card" style="margin-top: 20px;">
            <div class="card-header">
                <h3>Lịch Tập Hiện Tại</h3>
            </div>
            <div class="card-body">
                <div id="scheduleList">
                    <div style="text-align: center; padding: 20px;">
                        <div class="spinner"></div>
                    </div>
                </div>
            </div>
        </div>
    `;

    // Load existing schedules
    await loadSchedules(memberId);

    // Form submit handler
    document.getElementById('scheduleForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleSaveSchedule(memberId);
    });
}

async function loadSchedules(memberId) {
    const listContainer = document.getElementById('scheduleList');
    if (!listContainer) return; // Null guard
    
    try {
        const schedules = await apiFetch(`/api/MemberSchedulePreference/member/${memberId}`);
        
        if (!schedules || schedules.length === 0) {
            listContainer.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📅</div>
                    <div class="empty-state-text">Bạn chưa có lịch tập nào</div>
                </div>`;
            return;
        }

        // Group by day of week
        const grouped = {};
        schedules.forEach(s => {
            if (!grouped[s.dayOfWeek]) {
                grouped[s.dayOfWeek] = [];
            }
            grouped[s.dayOfWeek].push(s);
        });

        let html = '<div class="schedule-list">';
        
        // Sort by day order (Monday first)
        const dayOrder = [1, 2, 3, 4, 5, 6, 0];
        dayOrder.forEach(day => {
            if (grouped[day]) {
                html += `<div class="schedule-day-group" style="margin-bottom: 20px;">
                    <h4 style="color: var(--primary-color); margin-bottom: 10px;">${grouped[day][0].dayOfWeekName}</h4>`;
                
                grouped[day].forEach(schedule => {
                    const startTime = formatTimeSpan(schedule.startTime);
                    const endTime = formatTimeSpan(schedule.endTime);
                    const status = schedule.isActive ? 
                        '<span style="color: green;">✓ Đang hoạt động</span>' : 
                        '<span style="color: gray;">✗ Đã tắt</span>';
                    
                    html += `
                        <div class="schedule-item" style="background: #f8f9fa; padding: 12px; border-radius: 6px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
                            <div>
                                <strong>⏰ ${startTime} - ${endTime}</strong>
                                <div style="font-size: 0.9em; color: #666; margin-top: 4px;">${status}</div>
                            </div>
                            <button class="btn btn-sm btn-danger" onclick="deleteSchedule(${schedule.preferenceId}, ${memberId})">
                                🗑️ Xóa
                            </button>
                        </div>`;
                });
                
                html += '</div>';
            }
        });
        
        html += '</div>';
        listContainer.innerHTML = html;
        
    } catch (error) {
        listContainer.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">⚠️</div>
                <div class="empty-state-text">Lỗi tải danh sách: ${error.message}</div>
            </div>`;
    }
}

async function handleSaveSchedule(memberId) {
    const checkboxes = document.querySelectorAll('input[name="day"]:checked');
    const startTime = document.getElementById('startTime').value;
    const endTime = document.getElementById('endTime').value;

    if (checkboxes.length === 0) {
        showToast('Vui lòng chọn ít nhất một ngày', 'error');
        return;
    }

    if (!startTime || !endTime) {
        showToast('Vui lòng nhập giờ bắt đầu và kết thúc', 'error');
        return;
    }

    if (startTime >= endTime) {
        showToast('Giờ kết thúc phải sau giờ bắt đầu', 'error');
        return;
    }

    try {
        showLoading();

        // Create schedule for each selected day
        const promises = Array.from(checkboxes).map(checkbox => {
            const dayOfWeek = parseInt(checkbox.value);
            return apiFetch('/api/MemberSchedulePreference', {
                method: 'POST',
                body: JSON.stringify({
                    memberId: memberId,
                    dayOfWeek: dayOfWeek,
                    startTime: startTime + ':00', // Add seconds for TimeSpan format
                    endTime: endTime + ':00'
                })
            });
        });

        await Promise.all(promises);
        
        hideLoading();
        showToast('Lưu lịch tập thành công!', 'success');
        
        // Reset form
        document.getElementById('scheduleForm').reset();
        
        // Reload schedules
        await loadSchedules(memberId);
        
    } catch (error) {
        hideLoading();
        showToast('Lỗi lưu lịch: ' + error.message, 'error');
    }
}

async function deleteSchedule(preferenceId, memberId) {
    if (!confirm('Bạn có chắc muốn xóa lịch tập này?')) {
        return;
    }

    try {
        showLoading();
        await apiFetch(`/api/MemberSchedulePreference/${preferenceId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showToast('Xóa lịch tập thành công', 'success');
        await loadSchedules(memberId);
    } catch (error) {
        hideLoading();
        showToast('Lỗi xóa lịch: ' + error.message, 'error');
    }
}

function formatTimeSpan(timeSpan) {
    // timeSpan format: "HH:MM:SS"
    if (typeof timeSpan === 'string') {
        const parts = timeSpan.split(':');
        return `${parts[0]}:${parts[1]}`;
    }
    return timeSpan;
}
