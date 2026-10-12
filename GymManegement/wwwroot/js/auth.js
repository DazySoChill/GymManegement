/**
 * Authentication Module
 * Handles login, logout, and user session management
 */

/**
 * Login with username and password
 * @param {string} username 
 * @param {string} password 
 * @returns {Promise<object>} - Login response with token and user info
 */
async function login(username, password) {
    try {
        const response = await apiFetch('/api/Auth/login', {
            method: 'POST',
            body: JSON.stringify({ username, password })
        });
        
        if (response && response.token) {
            // Store token
            localStorage.setItem('gym_token', response.token);
            
            // Store user info
            const userInfo = {
                userId: response.userId || null,
                username: response.username,
                fullName: response.fullName,
                email: response.email || '',
                role: response.role,
                memberId: response.memberId || null
            };
            localStorage.setItem('gym_user', JSON.stringify(userInfo));
            
            return response;
        }
        
        throw new Error('Invalid login response');
    } catch (error) {
        console.error('Login error:', error);
        throw error;
    }
}

/**
 * Logout and redirect to login page
 */
function logout() {
    localStorage.removeItem('gym_token');
    localStorage.removeItem('gym_user');
    
    // Clear cached trainer ID to prevent stale data on re-login
    if (typeof clearTrainerIdCache === 'function') {
        clearTrainerIdCache();
    }
    
    window.location.href = 'login.html';
}

/**
 * Check if user is logged in
 * @returns {boolean}
 */
function isLoggedIn() {
    const token = localStorage.getItem('gym_token');
    return token !== null && token !== '';
}

/**
 * Get current user info
 * @returns {object|null}
 */
function getUser() {
    const userStr = localStorage.getItem('gym_user');
    if (!userStr) return null;
    
    try {
        return JSON.parse(userStr);
    } catch (e) {
        return null;
    }
}

/**
 * Get current user role
 * @returns {string|null} - 'Admin', 'Trainer', or 'Member'
 */
function getRole() {
    const user = getUser();
    return user ? user.role : null;
}

/**
 * Get current member ID (for Member role only)
 * @returns {number|null}
 */
function getMemberId() {
    const user = getUser();
    return user ? user.memberId : null;
}

/**
 * Get auth token
 * @returns {string|null}
 */
function getToken() {
    return localStorage.getItem('gym_token');
}

/**
 * Check if current user is Admin
 * @returns {boolean} - True if current user is Admin
 */
function isAdmin() {
    return getRole() === 'Admin';
}
