/**
 * API Client for Gym Management System
 * Base URL: http://localhost:5250
 */

const API_BASE = 'http://localhost:5250';

/**
 * Generic API fetch wrapper with JWT authentication
 * @param {string} path - API endpoint path (e.g., '/api/Member')
 * @param {object} options - Fetch options (method, body, headers, etc.)
 * @returns {Promise<any>} - Response data or null
 */
async function apiFetch(path, options = {}) {
    const token = localStorage.getItem('gym_token');
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers
    };
    
    if (token) {
        headers['Authorization'] = 'Bearer ' + token;
    }
    
    try {
        const response = await fetch(API_BASE + path, {
            ...options,
            headers
        });
        
        // Handle 401 Unauthorized - redirect to login
        if (response.status === 401) {
            logout();
            return null;
        }
        
        // Handle 204 No Content
        if (response.status === 204) {
            return null;
        }
        
        // Handle errors
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({
                message: response.statusText || 'Có lỗi xảy ra'
            }));
            throw new Error(errorData.message || errorData.title || 'Request failed');
        }
        
        // Parse JSON response
        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

/**
 * Show toast notification
 * @param {string} message - Message to display
 * @param {string} type - Type: 'success', 'error', 'info'
 */
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    if (!toast) return;
    
    toast.textContent = message;
    toast.className = `toast ${type}`;
    toast.classList.add('show');
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

/**
 * Show error toast
 */
function showError(message) {
    showToast(message, 'error');
}

/**
 * Show success toast
 */
function showSuccess(message) {
    showToast(message, 'success');
}

/**
 * Format date to Vietnamese locale
 * @param {string|Date} date - Date to format
 * @returns {string} - Formatted date string
 */
function formatDate(date) {
    if (!date) return '-';
    const d = new Date(date);
    if (isNaN(d.getTime())) return '-';
    
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    
    return `${day}/${month}/${year}`;
}

/**
 * Format date and time
 */
function formatDateTime(date) {
    if (!date) return '-';
    const d = new Date(date);
    if (isNaN(d.getTime())) return '-';
    
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    
    return `${day}/${month}/${year} ${hours}:${minutes}`;
}

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

/**
 * Format currency (VND)
 * @param {number} amount - Amount to format
 * @returns {string} - Formatted currency string
 */
function formatCurrency(amount) {
    if (amount === null || amount === undefined) return '0 ₫';
    return new Intl.NumberFormat('vi-VN', {
        style: 'currency',
        currency: 'VND'
    }).format(amount);
}

/**
 * Show loading spinner
 */
function showLoading() {
    const spinner = document.getElementById('loadingSpinner');
    if (spinner) spinner.style.display = 'flex';
}

/**
 * Hide loading spinner
 */
function hideLoading() {
    const spinner = document.getElementById('loadingSpinner');
    if (spinner) spinner.style.display = 'none';
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
