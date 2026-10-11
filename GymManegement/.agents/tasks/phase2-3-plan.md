# Implementation Plan: Phase 2 & 3 - Enhanced Sessions and Checkins

## Project Context

**Project Type:** ASP.NET Core 8.0 Web API + Vanilla JavaScript SPA  
**Language:** JavaScript (ES6+)  
**Build System:** ASP.NET Core build, static files served from wwwroot  
**Test Framework:** None apparent in frontend  
**API Base URL:** http://localhost:5250  
**Auth:** JWT stored in localStorage as `gym_token`  

**Key Files Identified:**
- `wwwroot/js/sessions.js` - Sessions management module
- `wwwroot/js/checkins.js` - Checkins management module
- `wwwroot/js/api.js` - Shared API utilities (apiFetch, formatDate, formatDateTime)
- `wwwroot/js/auth.js` - Auth utilities (getRole, getMemberId, getUser)
- `wwwroot/index.html` - Main SPA container that loads all modules

**Current State:**
- Sessions shows: ID, Member ID, Schedule ID, Registration Date, Status
- Checkins shows: ID, Member (name if included), Check-in Time, Checkout Time
- formatDateTime currently outputs: DD/MM/YYYY HH:mm (no seconds)
- Member names NOT currently fetched separately (backend may provide them)
- Schedule details (className, trainerName) exist in Schedule API responses

---

## Phase 2: Enhanced sessions.js

### Requirements Summary
1. Add Member Name column (fetch via `/api/Member/{memberId}`)
2. Add Class Name, Trainer, Schedule Time columns (fetch via `/api/Schedule/{scheduleId}`)
3. Add Notes column (localStorage-based, keyed by sessionId)
4. Add week selector UI with filtering logic
5. Week filter: Monday 00:00 to Sunday 23:59, filter by registrationDate

### Implementation Steps

- [ ] **1. Create member name cache system in sessions.js**
  
  Add at the top of sessions.js after the page size variables:
  ```javascript
  // Member name cache to avoid duplicate API calls
  const memberNameCache = {};
  
  async function fetchMemberName(memberId) {
      if (memberNameCache[memberId]) {
          return memberNameCache[memberId];
      }
      
      try {
          const member = await apiFetch(`/api/Member/${memberId}`);
          const name = member?.fullName || member?.name || `Member ${memberId}`;
          memberNameCache[memberId] = name;
          return name;
      } catch (error) {
          console.error(`Error fetching member ${memberId}:`, error);
          memberNameCache[memberId] = `Member ${memberId}`;
          return memberNameCache[memberId];
      }
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Add a console.log test call `fetchMemberName(1).then(console.log)` in browser console and confirm it returns member name without errors.

- [ ] **2. Create schedule details cache system in sessions.js**
  
  Add after the member cache:
  ```javascript
  // Schedule details cache
  const scheduleDetailsCache = {};
  
  async function fetchScheduleDetails(scheduleId) {
      if (scheduleDetailsCache[scheduleId]) {
          return scheduleDetailsCache[scheduleId];
      }
      
      try {
          const schedule = await apiFetch(`/api/Schedule/${scheduleId}`);
          const details = {
              className: schedule?.className || '-',
              trainerName: schedule?.trainerName || '-',
              facilityName: schedule?.facilityName || '-',
              startTime: schedule?.startTime || null,
              endTime: schedule?.endTime || null
          };
          scheduleDetailsCache[scheduleId] = details;
          return details;
      } catch (error) {
          console.error(`Error fetching schedule ${scheduleId}:`, error);
          const fallback = { className: '-', trainerName: '-', facilityName: '-', startTime: null, endTime: null };
          scheduleDetailsCache[scheduleId] = fallback;
          return fallback;
      }
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Test in console and confirm schedule details are fetched and cached.

- [ ] **3. Create localStorage notes system in sessions.js**
  
  Add after schedule cache:
  ```javascript
  // Session notes - stored in localStorage
  function getSessionNote(sessionId) {
      const key = `sessionNote_${sessionId}`;
      return localStorage.getItem(key) || '';
  }
  
  function saveSessionNote(sessionId, note) {
      const key = `sessionNote_${sessionId}`;
      if (note && note.trim()) {
          localStorage.setItem(key, note.trim());
      } else {
          localStorage.removeItem(key);
      }
  }
  
  function showNoteModal(sessionId) {
      const currentNote = getSessionNote(sessionId);
      
      const modal = document.createElement('div');
      modal.className = 'gym-modal-overlay';
      modal.innerHTML = `
          <div class="gym-modal">
              <h3>Ghi Chú - Session #${sessionId}</h3>
              <textarea id="noteTextarea" style="width:100%;min-height:120px;padding:8px;border:1px solid #ddd;border-radius:6px;resize:vertical;">${escapeHtml(currentNote)}</textarea>
              <div class="gym-modal-buttons">
                  <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                  <button class="btn btn-primary" onclick="saveNoteFromModal(${sessionId}); this.closest('.gym-modal-overlay').remove();">💾 Lưu</button>
              </div>
          </div>
      `;
      document.body.appendChild(modal);
      
      // Focus textarea
      setTimeout(() => document.getElementById('noteTextarea')?.focus(), 100);
  }
  
  function saveNoteFromModal(sessionId) {
      const note = document.getElementById('noteTextarea')?.value || '';
      saveSessionNote(sessionId, note);
      showToast('💾 Đã lưu ghi chú', 'success');
      reloadCurrentPage();
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Test showNoteModal in console, verify textarea displays and saves to localStorage.

- [ ] **4. Create week calculation and filtering utilities in sessions.js**
  
  Add after notes system:
  ```javascript
  // Week calculation utilities
  function getWeekBounds(dateInWeek) {
      const d = new Date(dateInWeek);
      const day = d.getDay(); // 0=Sunday, 1=Monday, ...
      const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust to Monday
      
      const monday = new Date(d.setDate(diff));
      monday.setHours(0, 0, 0, 0);
      
      const sunday = new Date(monday);
      sunday.setDate(monday.getDate() + 6);
      sunday.setHours(23, 59, 59, 999);
      
      return { start: monday, end: sunday };
  }
  
  function getCurrentWeekBounds() {
      return getWeekBounds(new Date());
  }
  
  function getNextWeekBounds() {
      const nextWeek = new Date();
      nextWeek.setDate(nextWeek.getDate() + 7);
      return getWeekBounds(nextWeek);
  }
  
  function formatWeekRange(start, end) {
      return `${formatDate(start)} - ${formatDate(end)}`;
  }
  
  // Filter sessions by week
  function filterSessionsByWeek(sessions, weekStart, weekEnd) {
      return sessions.filter(s => {
          const regDate = new Date(s.registrationDate);
          return regDate >= weekStart && regDate <= weekEnd;
      });
  }
  
  // Global week filter state
  let currentWeekFilter = null; // null means no filter
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Test `getCurrentWeekBounds()` in console and verify Monday 00:00 to Sunday 23:59 returned correctly.

- [ ] **5. Update renderAllSessions to include week selector UI**
  
  Replace the entire `renderAllSessions` function with:
  ```javascript
  async function renderAllSessions(container) {
      const role = getRole();
      const canManage = role === 'Admin' || role === 'Trainer';
      
      const currentWeek = getCurrentWeekBounds();
      const nextWeek = getNextWeekBounds();
      
      container.innerHTML = `
          <div class="card">
              <div class="card-header">
                  <h2 class="card-title">Quản lý Buổi Tập</h2>
                  ${canManage ? '<button class="btn btn-primary" onclick="showCreateSessionModal()">➕ Tạo session</button>' : ''}
              </div>
              
              <div class="filters" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
                  <button class="btn btn-info" onclick="filterByWeek('current')">📅 Tuần Này</button>
                  <button class="btn btn-info" onclick="filterByWeek('next')">📅 Tuần Sau</button>
                  <input type="week" id="customWeekInput" style="padding:8px;border:1px solid #ddd;border-radius:6px;">
                  <button class="btn btn-info" onclick="filterByCustomWeek()">🔍 Lọc tuần</button>
                  <button class="btn btn-secondary" onclick="clearWeekFilter()">✖️ Xóa lọc</button>
                  <span id="weekFilterDisplay" style="margin-left:12px;color:#666;font-size:14px;"></span>
              </div>
              
              <div class="table-container" id="sessionsTableContainer"></div>
              <div id="sessionsPagination" class="pagination"></div>
          </div>
      `;
      
      // Set default to current week
      filterByWeek('current');
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Load the sessions page and confirm week selector buttons appear correctly.

- [ ] **6. Implement week filter functions in sessions.js**
  
  Add these functions:
  ```javascript
  function filterByWeek(type) {
      if (type === 'current') {
          currentWeekFilter = getCurrentWeekBounds();
      } else if (type === 'next') {
          currentWeekFilter = getNextWeekBounds();
      }
      
      const display = document.getElementById('weekFilterDisplay');
      if (display) {
          display.textContent = `Tuần: ${formatWeekRange(currentWeekFilter.start, currentWeekFilter.end)}`;
      }
      
      loadSessions();
  }
  
  function filterByCustomWeek() {
      const input = document.getElementById('customWeekInput');
      if (!input || !input.value) {
          showError('Vui lòng chọn tuần');
          return;
      }
      
      // input.value format: "YYYY-Www" (e.g., "2024-W15")
      const [year, week] = input.value.split('-W');
      const firstDayOfYear = new Date(parseInt(year), 0, 1);
      const daysOffset = (parseInt(week) - 1) * 7;
      const targetDate = new Date(firstDayOfYear.setDate(firstDayOfYear.getDate() + daysOffset));
      
      currentWeekFilter = getWeekBounds(targetDate);
      
      const display = document.getElementById('weekFilterDisplay');
      if (display) {
          display.textContent = `Tuần: ${formatWeekRange(currentWeekFilter.start, currentWeekFilter.end)}`;
      }
      
      loadSessions();
  }
  
  function clearWeekFilter() {
      currentWeekFilter = null;
      const display = document.getElementById('weekFilterDisplay');
      if (display) {
          display.textContent = '';
      }
      loadSessions();
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Click week filter buttons and verify display updates, sessions are filtered.

- [ ] **7. Update loadSessions to fetch all pages when filtering**
  
  Replace `loadSessions` function with:
  ```javascript
  async function loadSessions() {
      try {
          showLoading();
          
          // If week filter is active, fetch all sessions (pagination doesn't work well with client-side filtering)
          if (currentWeekFilter) {
              const allData = await apiFetch(`/api/Session?pageNumber=1&pageSize=1000`);
              const filtered = filterSessionsByWeek(allData.items || [], currentWeekFilter.start, currentWeekFilter.end);
              
              hideLoading();
              await renderSessionsTable({ items: filtered, pageNumber: 1, totalPages: 1 });
              renderSessionsPagination({ pageNumber: 1, totalPages: 1 });
          } else {
              const data = await apiFetch(`/api/Session?pageNumber=${sessionsCurrentPage}&pageSize=${sessionsPageSize}`);
              hideLoading();
              await renderSessionsTable(data);
              renderSessionsPagination(data);
          }
      } catch (error) {
          hideLoading();
          showError('Lỗi tải danh sách buổi tập: ' + error.message);
      }
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Test with and without week filter, confirm pagination works correctly.

- [ ] **8. Completely rewrite renderSessionsTable to show all new columns**
  
  Replace the entire `renderSessionsTable` function:
  ```javascript
  async function renderSessionsTable(data) {
      const container = document.getElementById('sessionsTableContainer');
      const role = getRole();
      const canManage = role === 'Admin' || role === 'Trainer';
      
      if (!data || !data.items || data.items.length === 0) {
          container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💪</div><div class="empty-state-text">Không có buổi tập nào</div></div>';
          return;
      }
      
      // Fetch all member names and schedule details in parallel
      const sessions = data.items;
      const memberIds = [...new Set(sessions.map(s => s.memberId))];
      const scheduleIds = [...new Set(sessions.map(s => s.scheduleId))];
      
      await Promise.all([
          ...memberIds.map(id => fetchMemberName(id)),
          ...scheduleIds.map(id => fetchScheduleDetails(id))
      ]);
      
      let html = `
          <table>
              <thead>
                  <tr>
                      <th>ID</th>
                      <th>Member ID</th>
                      <th>Tên Member</th>
                      <th>Lớp</th>
                      <th>HLV</th>
                      <th>Thời gian tập</th>
                      <th>Ngày đăng ký</th>
                      <th>Trạng thái</th>
                      <th>Ghi chú</th>
                      ${canManage ? '<th>Thao tác</th>' : ''}
                  </tr>
              </thead>
              <tbody>
      `;
      
      for (const s of sessions) {
          const memberName = await fetchMemberName(s.memberId);
          const scheduleDetails = await fetchScheduleDetails(s.scheduleId);
          const note = getSessionNote(s.sessionId);
          const hasNote = note.length > 0;
          
          const scheduleTime = scheduleDetails.startTime 
              ? `${formatDateTime(scheduleDetails.startTime)} - ${formatDateTime(scheduleDetails.endTime)}` 
              : '-';
          
          const badge = s.status === 'Attended' ? 'badge-success' :
                       s.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
          
          html += `
              <tr>
                  <td>${s.sessionId}</td>
                  <td>${s.memberId}</td>
                  <td>${escapeHtml(memberName)}</td>
                  <td>${escapeHtml(scheduleDetails.className)}</td>
                  <td>${escapeHtml(scheduleDetails.trainerName)}</td>
                  <td>${scheduleTime}</td>
                  <td>${formatDate(s.registrationDate)}</td>
                  <td><span class="badge ${badge}">${s.status}</span></td>
                  <td>
                      <button class="btn btn-sm ${hasNote ? 'btn-info' : 'btn-secondary'}" 
                              onclick="showNoteModal(${s.sessionId})" 
                              title="${hasNote ? 'Xem/Sửa ghi chú' : 'Thêm ghi chú'}">
                          ${hasNote ? '📝' : '📄'}
                      </button>
                  </td>
                  ${canManage ? `
                      <td>
                          <div class="action-buttons">
                              <button class="btn btn-sm btn-success" onclick="updateSessionStatus(${s.sessionId}, 'Attended')">✓</button>
                              <button class="btn btn-sm btn-danger" onclick="updateSessionStatus(${s.sessionId}, 'Cancelled')">✗</button>
                          </div>
                      </td>
                  ` : ''}
              </tr>
          `;
      }
      
      html += '</tbody></table>';
      container.innerHTML = html;
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Load sessions page, confirm all columns display: Member ID, Name, Class, Trainer, Schedule Time, Registration Date, Status, Notes button.

- [ ] **9. Update renderMemberSessions for member view (simplified version)**
  
  Replace `renderMemberSessions` to maintain consistency:
  ```javascript
  async function renderMemberSessions(container, memberId) {
      container.innerHTML = `
          <div class="card">
              <div class="card-header">
                  <h2 class="card-title">Buổi Tập Của Tôi</h2>
                  <button class="btn btn-primary" onclick="showRegisterSessionModal()">➕ Đăng ký lớp</button>
              </div>
              
              <div class="filters" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
                  <button class="btn btn-info" onclick="filterMySessionsByWeek('current')">📅 Tuần Này</button>
                  <button class="btn btn-info" onclick="filterMySessionsByWeek('next')">📅 Tuần Sau</button>
                  <button class="btn btn-secondary" onclick="filterMySessionsByWeek('all')">✖️ Tất cả</button>
                  <span id="myWeekFilterDisplay" style="margin-left:12px;color:#666;font-size:14px;"></span>
              </div>
              
              <div id="mySessionsContainer"></div>
          </div>
      `;
      
      await loadMemberSessionsData(memberId, null);
  }
  
  async function loadMemberSessionsData(memberId, weekFilter) {
      try {
          showLoading();
          let sessions = await apiFetch(`/api/Session/member/${memberId}`);
          hideLoading();
          
          if (weekFilter) {
              sessions = filterSessionsByWeek(sessions, weekFilter.start, weekFilter.end);
          }
          
          await renderMemberSessionsTable(sessions);
      } catch (error) {
          hideLoading();
          showError('Lỗi tải buổi tập: ' + error.message);
      }
  }
  
  async function renderMemberSessionsTable(sessions) {
      const myContainer = document.getElementById('mySessionsContainer');
      
      if (!sessions || sessions.length === 0) {
          myContainer.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💪</div><div class="empty-state-text">Bạn chưa đăng ký buổi tập nào</div></div>';
          return;
      }
      
      // Fetch schedule details
      const scheduleIds = [...new Set(sessions.map(s => s.scheduleId))];
      await Promise.all(scheduleIds.map(id => fetchScheduleDetails(id)));
      
      let html = '<table><thead><tr><th>ID</th><th>Lớp</th><th>HLV</th><th>Thời gian tập</th><th>Ngày đăng ký</th><th>Trạng thái</th><th>Ghi chú</th></tr></thead><tbody>';
      
      for (const s of sessions) {
          const scheduleDetails = await fetchScheduleDetails(s.scheduleId);
          const note = getSessionNote(s.sessionId);
          const hasNote = note.length > 0;
          
          const scheduleTime = scheduleDetails.startTime 
              ? `${formatDateTime(scheduleDetails.startTime)} - ${formatDateTime(scheduleDetails.endTime)}` 
              : '-';
          
          const badge = s.status === 'Attended' ? 'badge-success' :
                       s.status === 'Cancelled' ? 'badge-danger' : 'badge-info';
          
          html += `
              <tr>
                  <td>${s.sessionId}</td>
                  <td>${escapeHtml(scheduleDetails.className)}</td>
                  <td>${escapeHtml(scheduleDetails.trainerName)}</td>
                  <td>${scheduleTime}</td>
                  <td>${formatDate(s.registrationDate)}</td>
                  <td><span class="badge ${badge}">${s.status}</span></td>
                  <td>
                      <button class="btn btn-sm ${hasNote ? 'btn-info' : 'btn-secondary'}" 
                              onclick="showNoteModal(${s.sessionId})">
                          ${hasNote ? '📝' : '📄'}
                      </button>
                  </td>
              </tr>
          `;
      }
      
      html += '</tbody></table>';
      myContainer.innerHTML = html;
  }
  
  let mySessionWeekFilter = null;
  
  function filterMySessionsByWeek(type) {
      const memberId = getMemberId();
      if (!memberId) return;
      
      if (type === 'current') {
          mySessionWeekFilter = getCurrentWeekBounds();
      } else if (type === 'next') {
          mySessionWeekFilter = getNextWeekBounds();
      } else {
          mySessionWeekFilter = null;
      }
      
      const display = document.getElementById('myWeekFilterDisplay');
      if (display) {
          display.textContent = mySessionWeekFilter 
              ? `Tuần: ${formatWeekRange(mySessionWeekFilter.start, mySessionWeekFilter.end)}` 
              : '';
      }
      
      loadMemberSessionsData(memberId, mySessionWeekFilter);
  }
  ```
  
  **Files:** `wwwroot/js/sessions.js`  
  **Verify:** Login as a member, view sessions, test week filters and note functionality.

---

## Phase 3: Enhanced checkins.js

### Requirements Summary
1. Add Member Name column (fetch via `/api/Member/{memberId}`)
2. Update datetime format to include seconds: DD/MM/YYYY HH:mm:ss
3. Add "Lần Checkin" column (client-side calculation: group by memberId, sort by checkinTime, assign count)

### Implementation Steps

- [ ] **10. Add formatDateTimeWithSeconds utility to api.js**
  
  Open `wwwroot/js/api.js` and add this function after `formatDateTime`:
  ```javascript
  /**
   * Format date and time with seconds
   */
  function formatDateTimeWithSeconds(date) {
      if (!date) return '-';
      const d = new Date(date);
      if (isNaN(d.getTime())) return '-';
      
      const day = String(d.getDate()).padStart(2, '0');
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const year = d.getFullYear();
      const hours = String(d.getHours()).padStart(2, '0');
      const minutes = String(d.getMinutes()).padStart(2, '0');
      const seconds = String(d.getSeconds()).padStart(2, '0');
      
      return `${day}/${month}/${year} ${hours}:${minutes}:${seconds}`;
  }
  ```
  
  **Files:** `wwwroot/js/api.js`  
  **Verify:** Test in console: `formatDateTimeWithSeconds(new Date())` should output with seconds.

- [ ] **11. Create member name cache in checkins.js**
  
  Add at the top of checkins.js after the page size variables:
  ```javascript
  // Member name cache to avoid duplicate API calls
  const checkinMemberNameCache = {};
  
  async function fetchCheckinMemberName(memberId) {
      if (checkinMemberNameCache[memberId]) {
          return checkinMemberNameCache[memberId];
      }
      
      try {
          const member = await apiFetch(`/api/Member/${memberId}`);
          const name = member?.fullName || member?.name || `Member ${memberId}`;
          checkinMemberNameCache[memberId] = name;
          return name;
      } catch (error) {
          console.error(`Error fetching member ${memberId}:`, error);
          checkinMemberNameCache[memberId] = `Member ${memberId}`;
          return checkinMemberNameCache[memberId];
      }
  }
  ```
  
  **Files:** `wwwroot/js/checkins.js`  
  **Verify:** Test in console and verify member name is fetched and cached.

- [ ] **12. Create checkin count calculator in checkins.js**
  
  Add after the member cache:
  ```javascript
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
  ```
  
  **Files:** `wwwroot/js/checkins.js`  
  **Verify:** Create test data array with checkins, call calculateCheckinCounts, verify counts assigned correctly.

- [ ] **13. Update loadCheckins to fetch ALL checkins for count calculation**
  
  Replace `loadCheckins` function:
  ```javascript
  async function loadCheckins() {
      try {
          showLoading();
          
          // Fetch ALL checkins to calculate counts accurately
          // We'll still paginate the display, but need full dataset for counts
          const allData = await apiFetch(`/api/Checkin?pageNumber=1&pageSize=10000`);
          
          // Calculate counts
          const countsMap = calculateCheckinCounts(allData.items || []);
          
          // For display, use the requested page
          const data = await apiFetch(`/api/Checkin?pageNumber=${checkinsCurrentPage}&pageSize=${checkinsPageSize}`);
          
          hideLoading();
          
          await renderCheckinsTable(data, countsMap);
          renderCheckinsPagination(data);
      } catch (error) {
          hideLoading();
          showError('Lỗi tải danh sách check-in: ' + error.message);
      }
  }
  ```
  
  **Files:** `wwwroot/js/checkins.js`  
  **Verify:** Load checkins page and verify no errors in console.

- [ ] **14. Completely rewrite renderCheckinsTable to show all new columns**
  
  Replace the entire `renderCheckinsTable` function:
  ```javascript
  async function renderCheckinsTable(data, countsMap = {}) {
      const container = document.getElementById('checkinsTableContainer');
      
      if (!data || !data.items || data.items.length === 0) {
          container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><div class="empty-state-text">Không có check-in nào</div></div>';
          return;
      }
      
      // Fetch all member names in parallel
      const checkins = data.items;
      const memberIds = [...new Set(checkins.map(c => c.memberId))];
      await Promise.all(memberIds.map(id => fetchCheckinMemberName(id)));
      
      // If countsMap is empty (e.g., from date filter), calculate for current set
      if (Object.keys(countsMap).length === 0) {
          countsMap = calculateCheckinCounts(checkins);
      }
      
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
  ```
  
  **Files:** `wwwroot/js/checkins.js`  
  **Verify:** Load checkins page, confirm all columns display: ID, Member ID, Member Name, Check-in Time (with seconds), Checkout Time (with seconds), Lần Checkin.

- [ ] **15. Update loadCheckinsByDate to include counts**
  
  Replace `loadCheckinsByDate`:
  ```javascript
  async function loadCheckinsByDate() {
      const dateInput = document.getElementById('checkinDate');
      const date = dateInput.value;
      
      if (!date) {
          loadCheckins();
          return;
      }
      
      try {
          showLoading();
          
          // Fetch all checkins for count calculation
          const allData = await apiFetch(`/api/Checkin?pageNumber=1&pageSize=10000`);
          const countsMap = calculateCheckinCounts(allData.items || []);
          
          // Fetch filtered data
          const data = await apiFetch(`/api/Checkin/date/${date}`);
          hideLoading();
          
          await renderCheckinsTable({ items: data, pageNumber: 1, totalPages: 1 }, countsMap);
      } catch (error) {
          hideLoading();
          showError('Lỗi tải check-in: ' + error.message);
      }
  }
  ```
  
  **Files:** `wwwroot/js/checkins.js`  
  **Verify:** Use date filter and verify counts still display correctly.

- [ ] **16. Update renderMemberCheckinsTable for member view**
  
  Replace `renderMemberCheckinsTable`:
  ```javascript
  function renderMemberCheckinsTable(checkins) {
      const container = document.getElementById('myCheckinsContainer');
      
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
  ```
  
  **Files:** `wwwroot/js/checkins.js`  
  **Verify:** Login as member, view checkins, confirm all columns display with seconds and counts.

- [ ] **17. Update loadMemberCheckinsByDateRange to include counts**
  
  Replace `loadMemberCheckinsByDateRange`:
  ```javascript
  async function loadMemberCheckinsByDateRange(memberId) {
      const from = document.getElementById('checkinFromDate').value;
      const to = document.getElementById('checkinToDate').value;
      
      if (!from || !to) {
          showError('Vui lòng chọn ngày bắt đầu và kết thúc');
          return;
      }
      
      try {
          showLoading();
          
          // Fetch member's all checkins first for accurate counts
          const allMemberCheckins = await apiFetch(`/api/Checkin/member/${memberId}`);
          
          // Then filter by date range
          const checkins = await apiFetch(`/api/Checkin/date-range?from=${from}&to=${to}`);
          const filtered = checkins.filter(c => c.memberId === memberId);
          
          hideLoading();
          renderMemberCheckinsTable(filtered);
      } catch (error) {
          hideLoading();
          showError('Lỗi tải check-in: ' + error.message);
      }
  }
  ```
  
  **Files:** `wwwroot/js/checkins.js`  
  **Verify:** Test date range filter as member, verify counts are accurate.

---

## Verification Strategy

### Overall Testing Procedure

1. **Start the backend server:**
   ```powershell
   cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
   dotnet run
   ```
   Server should start on http://localhost:5250

2. **Open browser and login:**
   - Navigate to http://localhost:5250/index.html (or wherever served)
   - Login as Admin: `gymadmin` / `Admin@2024`
   - Login as Member: test member credentials

3. **Test Phase 2 (Sessions):**
   - Navigate to Sessions page
   - Verify table shows: ID, Member ID, Member Name, Class Name, Trainer, Schedule Time, Registration Date, Status, Notes
   - Click "Tuần Này" button - verify filter applies and display updates
   - Click "Tuần Sau" button - verify different sessions shown
   - Select a week with the week picker - verify custom week filter works
   - Click "Xóa lọc" - verify all sessions shown again
   - Click a note button (📄) - verify modal opens with textarea
   - Type a note and save - verify button changes to 📝
   - Click 📝 button - verify note is displayed in textarea
   - Logout and login as member - verify member view shows their sessions with week filters

4. **Test Phase 3 (Checkins):**
   - Navigate to Checkins page
   - Verify table shows: ID, Member ID, Member Name, Check-in Time (with seconds), Checkout Time (with seconds), Lần Checkin
   - Verify datetime format is DD/MM/YYYY HH:mm:ss (note the seconds)
   - Verify "Lần Checkin" shows "Lần 1", "Lần 2", etc. for each member
   - Verify same member's checkins are numbered sequentially
   - Use date filter - verify checkins filtered correctly and counts still accurate
   - Logout and login as member - verify member view shows their checkins with counts

5. **Edge Cases:**
   - Test with no data (empty sessions/checkins)
   - Test with member that has no name in API response
   - Test with schedule that has missing fields
   - Test localStorage notes persistence (refresh page and verify notes remain)
   - Test week filter across year boundaries (late December / early January)

6. **Browser Console Check:**
   - Open browser DevTools console (F12)
   - Verify no JavaScript errors
   - Verify API calls are successful (Network tab)
   - Verify caching works (second load of same member name should not trigger new API call)

### Success Criteria

- ✅ All tables display new columns correctly
- ✅ Member names fetched and cached (no duplicate API calls for same member)
- ✅ Schedule details fetched and displayed
- ✅ Week filters work correctly (Monday 00:00 to Sunday 23:59)
- ✅ localStorage notes save and persist across page refreshes
- ✅ DateTime format includes seconds everywhere in checkins
- ✅ Checkin counts calculated correctly and displayed
- ✅ No JavaScript errors in console
- ✅ Both Admin and Member views work correctly
- ✅ Page remains responsive and performs well (< 2s load time)

---

## HTML Changes

**No HTML file changes required.** The `index.html` already loads both `sessions.js` and `checkins.js`. All UI changes are dynamically generated by the JavaScript modules.

---

## Performance Considerations

1. **Caching Strategy:** Member names and schedule details are cached in memory to avoid redundant API calls. Cache persists for the page session.

2. **Pagination vs Full Load:** For week filtering in sessions and count calculation in checkins, we fetch larger datasets (1000-10000 records). This is acceptable for small-to-medium gyms but may need optimization for larger datasets:
   - Consider backend API support for week filtering
   - Consider backend calculation of checkin counts
   - Implement virtual scrolling for very large lists

3. **localStorage Notes:** Notes are stored per session, not globally indexed. For 1000s of sessions with notes, consider periodic cleanup or a more structured storage approach.

4. **Parallel API Calls:** We use `Promise.all` to fetch multiple member names / schedule details simultaneously, reducing total load time.

---

## Notes for Implementer

- **Do NOT modify backend controllers or database schema** - all changes are frontend-only
- **Maintain blue/indigo theme** - use existing CSS classes (`btn`, `btn-info`, `btn-primary`, etc.)
- **Error handling** - all API calls are wrapped in try-catch, use `showError()` for user feedback
- **Vanilla JS only** - no frameworks, no build step, direct file editing
- **Test incrementally** - after each step, verify in browser before continuing
- **Member safety** - always check `getRole()` and `getMemberId()` before role-specific operations
- **Date handling** - JavaScript Date objects are timezone-sensitive; all week calculations use local time
- **localStorage keys** - use prefixes (`sessionNote_`, `memberSchedules_`) to avoid collisions

---

## Assumptions Made

1. **API Response Structure:**
   - `/api/Member/{id}` returns `{ memberId, fullName, name, email, ... }`
   - `/api/Schedule/{id}` returns `{ scheduleId, className, trainerName, facilityName, startTime, endTime, ... }`
   - `/api/Session` returns paginated `{ items: [...], pageNumber, totalPages, ... }`
   - `/api/Checkin` returns paginated with same structure

2. **Week Definition:** Week starts Monday 00:00 and ends Sunday 23:59 (ISO week standard)

3. **Checkin Count:** Calculated client-side by sorting all member checkins by time ascending. If backend later provides this, replace client calculation.

4. **Notes Scope:** Notes are session-specific, not user-specific. Any user viewing a session can read/write its note (stored in their browser's localStorage).

5. **Performance:** Gym has < 10,000 sessions and < 10,000 checkins total. For larger datasets, backend filtering/calculation would be needed.
