/**
 * Main App Module - SPA Routing and RBAC
 */

// Role-based page access control
const allowedPagesByRole = {
    'Admin': ['dashboard', 'members', 'memberships', 'trainers', 'facilities', 'schedules', 'sessions', 'checkins', 'invoices', 'payments', 'reports', 'users', 'profile'],
    'Trainer': ['dashboard', 'schedules', 'sessions', 'checkins', 'profile'],
    'Member': ['dashboard', 'memberships', 'schedules', 'sessions', 'checkins', 'member-schedule', 'profile']
};

// Page metadata
const pageMetadata = {
    'dashboard': { title: 'Dashboard', icon: '📊' },
    'members': { title: 'Quản lý Members', icon: '👥' },
    'memberships': { title: 'Gói tập', icon: '🎫' },
    'trainers': { title: 'Huấn luyện viên', icon: '🏋️' },
    'facilities': { title: 'Cơ sở vật chất', icon: '🏢' },
    'schedules': { title: 'Lịch Class', icon: '📅' },
    'sessions': { title: 'Đăng ký Class', icon: '💪' },
    'checkins': { title: 'Check-in', icon: '✅' },
    'invoices': { title: 'Hóa đơn', icon: '🧾' },
    'payments': { title: 'Thanh toán', icon: '💳' },
    'reports': { title: 'Báo cáo', icon: '📈' },
    'users': { title: 'Quản lý Users', icon: '👤' },
    'member-schedule': { title: 'Lịch Tập Của Tôi', icon: '📅' },
    'profile': { title: 'Cá nhân', icon: '⚙️' }
};

let currentPage = null;

/**
 * Initialize the application
 */
function initApp() {
    const user = getUser();
    const role = getRole();
    
    if (!user || !role) {
        logout();
        return;
    }
    
    // Update user info in header
    const userInfo = document.getElementById('userInfo');
    if (userInfo) {
        userInfo.textContent = `${user.fullName} (${role})`;
    }
    
    // Build navigation based on role
    initNavigation(role);
    
    // Handle hash-based routing
    window.addEventListener('hashchange', handleRouting);
    
    // Load initial page
    handleRouting();
}

/**
 * Build sidebar navigation based on user role
 */
function initNavigation(role) {
    const navContainer = document.getElementById('sidebarNav');
    if (!navContainer) return;
    
    const allowedPages = allowedPagesByRole[role] || [];
    navContainer.innerHTML = '';
    
    allowedPages.forEach(pageId => {
        const meta = pageMetadata[pageId];
        if (!meta) return;
        
        const navItem = document.createElement('a');
        navItem.href = `#${pageId}`;
        navItem.className = 'nav-item';
        navItem.setAttribute('data-page', pageId);
        navItem.innerHTML = `${meta.icon} ${meta.title}`;
        
        navContainer.appendChild(navItem);
    });
}

/**
 * Handle routing based on hash
 */
function handleRouting() {
    const hash = window.location.hash.slice(1) || 'dashboard';
    navigateTo(hash);
}

/**
 * Navigate to a specific page
 */
function navigateTo(pageId) {
    const role = getRole();
    const allowedPages = allowedPagesByRole[role] || [];
    
    // Check if user has access to this page
    if (!allowedPages.includes(pageId)) {
        showError('Bạn không có quyền truy cập trang này');
        pageId = 'dashboard';
        window.location.hash = 'dashboard';
    }
    
    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.getAttribute('data-page') === pageId) {
            item.classList.add('active');
        }
    });
    
    // Load page content
    currentPage = pageId;
    loadPage(pageId);
}

/**
 * Load page content
 */
async function loadPage(pageId) {
    const container = document.getElementById('main-content');
    if (!container) return;
    
    // Show loading
    container.innerHTML = '<div style="text-align: center; padding: 40px;"><div class="spinner"></div></div>';
    
    try {
        // Call the appropriate render function
        switch (pageId) {
            case 'dashboard':
                await renderDashboard(container);
                break;
            case 'members':
                await renderMembers(container);
                break;
            case 'memberships':
                await renderMemberships(container);
                break;
            case 'trainers':
                await renderTrainers(container);
                break;
            case 'facilities':
                await renderFacilities(container);
                break;
            case 'schedules':
                await renderSchedules(container);
                break;
            case 'sessions':
                await renderSessions(container);
                break;
            case 'checkins':
                await renderCheckins(container);
                break;
            case 'invoices':
                await renderInvoices(container);
                break;
            case 'payments':
                await renderPayments(container);
                break;
            case 'reports':
                await renderReports(container);
                break;
            case 'users':
                await renderUsers(container);
                break;
            case 'member-schedule':
                await renderMemberSchedule(container);
                break;
            case 'profile':
                await renderProfile(container);
                break;
            default:
                container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">❌</div><div class="empty-state-text">Trang không tồn tại</div></div>';
        }
    } catch (error) {
        console.error('Error loading page:', error);
        container.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Lỗi tải trang: ${error.message}</div></div>`;
    }
}

/**
 * Reload current page
 */
function reloadCurrentPage() {
    if (currentPage) {
        loadPage(currentPage);
    }
}
