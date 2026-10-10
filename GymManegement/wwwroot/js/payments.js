/**
 * Payments Management Module
 */

let paymentsCurrentPage = 1;
let paymentsPageSize = 10;

async function renderPayments(container) {
    const role = getRole();
    const canManage = role === 'Admin';
    
    if (!canManage) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔒</div><div class="empty-state-text">Bạn không có quyền truy cập trang này</div></div>';
        return;
    }
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Thanh Toán</h2>
                <button class="btn btn-primary" onclick="showCreatePaymentModal()">➕ Ghi nhận thanh toán</button>
            </div>
            
            <div class="filters">
                <select id="paymentMethodFilter" onchange="loadPayments()">
                    <option value="">Tất cả phương thức</option>
                    <option value="Cash">Cash</option>
                    <option value="BankTransfer">Bank Transfer</option>
                    <option value="Card">Card</option>
                    <option value="MoMo">MoMo</option>
                    <option value="ZaloPay">ZaloPay</option>
                </select>
                <button class="btn btn-info" onclick="loadPayments()">🔍 Tìm</button>
            </div>
            
            <div class="table-container" id="paymentsTableContainer"></div>
            <div id="paymentsPagination" class="pagination"></div>
        </div>
    `;
    
    await loadPayments();
}

async function loadPayments() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Payment?pageNumber=${paymentsCurrentPage}&pageSize=${paymentsPageSize}`);
        hideLoading();
        
        renderPaymentsTable(data);
        renderPaymentsPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách thanh toán: ' + error.message);
    }
}

function renderPaymentsTable(data) {
    const container = document.getElementById('paymentsTableContainer');
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💳</div><div class="empty-state-text">Không có thanh toán nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Invoice ID</th>
                    <th>Số tiền</th>
                    <th>Ngày TT</th>
                    <th>Phương thức</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(payment => {
        html += `
            <tr>
                <td>${payment.paymentId}</td>
                <td>${payment.invoiceId}</td>
                <td>${formatCurrency(payment.amount)}</td>
                <td>${formatDate(payment.paymentDate)}</td>
                <td><span class="badge badge-info">${payment.paymentMethod}</span></td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderPaymentsPagination(data) {
    const container = document.getElementById('paymentsPagination');
    if (!data) return;
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changePaymentsPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changePaymentsPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changePaymentsPage(page) {
    paymentsCurrentPage = page;
    loadPayments();
}

function showCreatePaymentModal() {
    showError('Chức năng ghi nhận thanh toán chưa được triển khai đầy đủ');
}
