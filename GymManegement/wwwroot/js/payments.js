/**
 * Payments Management Module
 */

let paymentsCurrentPage = 1;
let paymentsPageSize = 10;

// Inject modal styles once
function injectPaymentModalStyles() {
    if (document.getElementById('payment-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'payment-modal-styles';
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
        .form-group textarea.invalid,
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
                    <option value="QRCode">QR Code</option>
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
    const role = getRole();
    const canManage = role === 'Admin';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💳</div><div class="empty-state-text">Không có thanh toán nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Member ID</th>
                    <th>Invoice ID</th>
                    <th>Số tiền</th>
                    <th>Ngày TT</th>
                    <th>Phương thức</th>
                    <th>Trạng thái</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(payment => {
        const statusBadge = payment.status === 'Completed' ? 'badge-success' :
                          payment.status === 'Failed' ? 'badge-danger' : 'badge-warning';
        html += `
            <tr>
                <td>${payment.paymentId}</td>
                <td>${payment.memberId || '-'}</td>
                <td>${payment.invoiceId || '-'}</td>
                <td>${formatCurrency(payment.amount)}</td>
                <td>${formatDate(payment.paymentDate)}</td>
                <td><span class="badge badge-info">${escapeHtml(payment.paymentMethod)}</span></td>
                <td><span class="badge ${statusBadge}">${escapeHtml(payment.status)}</span></td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-info" onclick="showEditPaymentModal(${payment.paymentId})" title="Sửa">✏️</button>
                            <button class="btn btn-sm btn-danger" onclick="deletePayment(${payment.paymentId})" title="Xóa">🗑️</button>
                        </div>
                    </td>
                ` : ''}
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

async function showCreatePaymentModal() {
    injectPaymentModalStyles();
    
    try {
        showLoading();
        // Fetch members and pending invoices for dropdowns
        const [membersData, invoicesData] = await Promise.all([
            apiFetch('/api/Member?pageNumber=1&pageSize=1000'),
            apiFetch('/api/Invoice/status/Pending')
        ]);
        hideLoading();
        
        const members = membersData.items || [];
        const invoices = invoicesData || [];
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>➕ Ghi Nhận Thanh Toán</h3>
                <form id="createPaymentForm">
                    <div class="form-group">
                        <label>Thành viên <span class="required">*</span></label>
                        <select id="memberId" name="memberId" required>
                            <option value="">-- Chọn thành viên --</option>
                            ${members.map(m => `<option value="${m.memberId}">${escapeHtml(m.fullName)} (ID: ${m.memberId})</option>`).join('')}
                        </select>
                        <div class="error" id="memberIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Hóa đơn (tùy chọn)</label>
                        <select id="invoiceId" name="invoiceId">
                            <option value="">-- Không liên kết --</option>
                            ${invoices.map(inv => `<option value="${inv.invoiceId}">HĐ #${inv.invoiceId} - ${formatCurrency(inv.totalAmount)} - ${formatDate(inv.dueDate)}</option>`).join('')}
                        </select>
                        <div class="error" id="invoiceIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Số tiền (VNĐ) <span class="required">*</span></label>
                        <input type="number" id="amount" name="amount" required min="1" step="1000" placeholder="500000">
                        <div class="error" id="amountError"></div>
                    </div>
                    <div class="form-group">
                        <label>Phương thức thanh toán <span class="required">*</span></label>
                        <select id="paymentMethod" name="paymentMethod" required>
                            <option value="">-- Chọn phương thức --</option>
                            <option value="Cash">Cash</option>
                            <option value="Card">Card</option>
                            <option value="QRCode">QR Code</option>
                            <option value="BankTransfer">Bank Transfer</option>
                            <option value="MoMo">MoMo</option>
                            <option value="ZaloPay">ZaloPay</option>
                        </select>
                        <div class="error" id="paymentMethodError"></div>
                    </div>
                    <div class="form-group">
                        <label>Ngày thanh toán <span class="required">*</span></label>
                        <input type="date" id="paymentDate" name="paymentDate" required>
                        <div class="error" id="paymentDateError"></div>
                    </div>
                    <div class="form-group">
                        <label>Mã giao dịch</label>
                        <input type="text" id="transactionId" name="transactionId" placeholder="VD: TXN123456">
                        <div class="error" id="transactionIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Trạng thái <span class="required">*</span></label>
                        <select id="status" name="status" required>
                            <option value="Completed">Completed</option>
                            <option value="Pending">Pending</option>
                            <option value="Failed">Failed</option>
                        </select>
                        <div class="error" id="statusError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                        <button type="submit" class="btn btn-primary">Ghi Nhận</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Set default date to today
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('paymentDate').value = today;
        
        // Form submit handler
        const form = document.getElementById('createPaymentForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (!validatePaymentForm()) {
                return;
            }
            
            const invoiceIdValue = document.getElementById('invoiceId').value;
            
            const formData = {
                memberId: parseInt(document.getElementById('memberId').value),
                invoiceId: invoiceIdValue ? parseInt(invoiceIdValue) : null,
                amount: parseFloat(document.getElementById('amount').value),
                paymentMethod: document.getElementById('paymentMethod').value,
                paymentDate: new Date(document.getElementById('paymentDate').value).toISOString(),
                transactionId: document.getElementById('transactionId').value.trim() || null,
                status: document.getElementById('status').value
            };
            
            try {
                showLoading();
                await apiFetch('/api/Payment', {
                    method: 'POST',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Ghi nhận thanh toán thành công!');
                modal.remove();
                await loadPayments();
            } catch (error) {
                hideLoading();
                showError('Lỗi ghi nhận thanh toán: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

async function showEditPaymentModal(paymentId) {
    injectPaymentModalStyles();
    
    try {
        showLoading();
        const payment = await apiFetch(`/api/Payment/${paymentId}`);
        hideLoading();
        
        if (!payment) {
            showError('Không tìm thấy thanh toán');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>✏️ Xem Thông Tin Thanh Toán #${paymentId}</h3>
                <div style="background: #f8f9fa; padding: 16px; border-radius: 6px; margin-bottom: 16px;">
                    <p style="margin: 4px 0;"><strong>Member ID:</strong> ${payment.memberId || '-'}</p>
                    <p style="margin: 4px 0;"><strong>Invoice ID:</strong> ${payment.invoiceId || '-'}</p>
                    <p style="margin: 4px 0;"><strong>Số tiền:</strong> ${formatCurrency(payment.amount)}</p>
                    <p style="margin: 4px 0;"><strong>Phương thức:</strong> ${escapeHtml(payment.paymentMethod)}</p>
                    <p style="margin: 4px 0;"><strong>Ngày thanh toán:</strong> ${formatDate(payment.paymentDate)}</p>
                    ${payment.transactionId ? `<p style="margin: 4px 0;"><strong>Mã GD:</strong> ${escapeHtml(payment.transactionId)}</p>` : ''}
                    <p style="margin: 4px 0;"><strong>Trạng thái hiện tại:</strong> <span class="badge ${payment.status === 'Completed' ? 'badge-success' : payment.status === 'Failed' ? 'badge-danger' : 'badge-warning'}">${escapeHtml(payment.status)}</span></p>
                </div>
                <p style="color: #666; font-size: 14px; text-align: center;">
                    ℹ️ Thanh toán không thể chỉnh sửa sau khi tạo.<br>
                    Chỉ có thể xóa nếu cần điều chỉnh.
                </p>
                <div class="gym-modal-buttons">
                    <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Đóng</button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải thông tin thanh toán: ' + error.message);
    }
}

function validatePaymentForm(isEdit = false) {
    if (isEdit) return true; // Edit form is read-only based on UpdatePaymentRequest (no fields)
    
    const memberId = document.getElementById('memberId');
    const amount = document.getElementById('amount');
    const paymentMethod = document.getElementById('paymentMethod');
    const paymentDate = document.getElementById('paymentDate');
    const status = document.getElementById('status');
    
    let isValid = true;
    
    // Clear previous errors
    document.getElementById('memberIdError').textContent = '';
    document.getElementById('amountError').textContent = '';
    document.getElementById('paymentMethodError').textContent = '';
    document.getElementById('paymentDateError').textContent = '';
    document.getElementById('statusError').textContent = '';
    memberId.classList.remove('invalid');
    amount.classList.remove('invalid');
    paymentMethod.classList.remove('invalid');
    paymentDate.classList.remove('invalid');
    status.classList.remove('invalid');
    
    // Validate member
    if (!memberId.value) {
        document.getElementById('memberIdError').textContent = 'Vui lòng chọn thành viên';
        memberId.classList.add('invalid');
        isValid = false;
    }
    
    // Validate amount
    if (!amount.value || parseFloat(amount.value) <= 0) {
        document.getElementById('amountError').textContent = 'Vui lòng nhập số tiền hợp lệ';
        amount.classList.add('invalid');
        isValid = false;
    }
    
    // Validate payment method
    if (!paymentMethod.value) {
        document.getElementById('paymentMethodError').textContent = 'Vui lòng chọn phương thức thanh toán';
        paymentMethod.classList.add('invalid');
        isValid = false;
    }
    
    // Validate payment date
    if (!paymentDate.value) {
        document.getElementById('paymentDateError').textContent = 'Vui lòng chọn ngày thanh toán';
        paymentDate.classList.add('invalid');
        isValid = false;
    }
    
    // Validate status
    if (!status.value) {
        document.getElementById('statusError').textContent = 'Vui lòng chọn trạng thái';
        status.classList.add('invalid');
        isValid = false;
    }
    
    return isValid;
}

async function deletePayment(paymentId) {
    if (!confirm('Bạn có chắc chắn muốn xóa thanh toán này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Payment/${paymentId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa thanh toán thành công!');
        await loadPayments();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa thanh toán: ' + error.message);
    }
}
