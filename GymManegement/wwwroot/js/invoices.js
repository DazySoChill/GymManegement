/**
 * Invoices Management Module
 */

let invoicesCurrentPage = 1;
let invoicesPageSize = 10;

async function renderInvoices(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if (role === 'Member' && memberId) {
        await renderMemberInvoices(container, memberId);
    } else {
        await renderAllInvoices(container);
    }
}

async function renderMemberInvoices(container, memberId) {
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Hóa Đơn Của Tôi</h2>
            </div>
            <div id="myInvoicesContainer"></div>
        </div>
    `;
    
    try {
        showLoading();
        const invoices = await apiFetch(`/api/Invoice/member/${memberId}`);
        hideLoading();
        
        const myContainer = document.getElementById('myInvoicesContainer');
        if (!invoices || invoices.length === 0) {
            myContainer.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🧾</div><div class="empty-state-text">Bạn chưa có hóa đơn nào</div></div>';
            return;
        }
        
        let html = '<table><thead><tr><th>ID</th><th>Gói tập</th><th>Số tiền</th><th>Ngày HĐ</th><th>Hạn thanh toán</th><th>Trạng thái</th></tr></thead><tbody>';
        
        invoices.forEach(inv => {
            const badge = inv.status === 'Paid' ? 'badge-success' :
                         inv.status === 'Overdue' ? 'badge-danger' : 'badge-warning';
            html += `
                <tr>
                    <td>${inv.invoiceId}</td>
                    <td>${inv.packageName || (inv.membershipId ? 'MS ' + inv.membershipId : '-')}</td>
                    <td>${formatCurrency(inv.totalAmount)}</td>
                    <td>${formatDate(inv.invoiceDate)}</td>
                    <td>${formatDate(inv.dueDate)}</td>
                    <td><span class="badge ${badge}">${inv.status}</span></td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        myContainer.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải hóa đơn: ' + error.message);
    }
}

async function renderAllInvoices(container) {
    const role = getRole();
    const canManage = role === 'Admin';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quản lý Hóa Đơn</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showCreateInvoiceModal()">➕ Tạo hóa đơn</button>' : ''}
            </div>
            
            <div class="filters">
                <input type="text" id="invoiceMemberIdFilter" placeholder="Tìm theo Member ID..." style="width: 200px;">
                <select id="invoiceStatusFilter" onchange="loadInvoicesByFilter()">
                    <option value="">Tất cả trạng thái</option>
                    <option value="Pending">Pending (Chưa thanh toán)</option>
                    <option value="Paid">Paid (Đã thanh toán)</option>
                    <option value="Overdue">Overdue (Quá hạn)</option>
                </select>
                <button class="btn btn-info" onclick="loadInvoicesByFilter()">🔍 Tìm</button>
                <button class="btn btn-secondary" onclick="clearInvoiceFilters()">↺ Reset</button>
            </div>
            
            <div class="table-container" id="invoicesTableContainer"></div>
            <div id="invoicesPagination" class="pagination"></div>
        </div>
    `;
    
    await loadInvoices();
}

async function loadInvoices() {
    try {
        showLoading();
        const data = await apiFetch(`/api/Invoice?pageNumber=${invoicesCurrentPage}&pageSize=${invoicesPageSize}&sortBy=InvoiceDate&sortDir=desc`);
        hideLoading();
        
        renderInvoicesTable(data);
        renderInvoicesPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách hóa đơn: ' + error.message);
    }
}

// Store filtered invoices for client-side pagination
let filteredInvoices = [];

async function loadInvoicesByFilter() {
    const memberIdInput = document.getElementById('invoiceMemberIdFilter').value.trim();
    const status = document.getElementById('invoiceStatusFilter').value;
    
    console.log('Loading invoices with filters:', { memberId: memberIdInput, status });
    
    // If no filters, load all
    if (!memberIdInput && !status) {
        filteredInvoices = [];
        invoicesCurrentPage = 1;
        loadInvoices();
        return;
    }
    
    try {
        showLoading();
        
        let allItems = [];
        
        // Filter by Member ID first (if provided)
        if (memberIdInput) {
            const memberId = parseInt(memberIdInput);
            if (isNaN(memberId)) {
                hideLoading();
                showError('Member ID phải là số');
                return;
            }
            
            allItems = await apiFetch(`/api/Invoice/member/${memberId}`);
            console.log('Invoices for member:', allItems);
        } else if (status) {
            // Filter by status only
            allItems = await apiFetch(`/api/Invoice/status/${status}`);
            console.log('Invoices by status:', allItems);
        }
        
        // Apply status filter if both filters are present
        if (memberIdInput && status && allItems) {
            allItems = allItems.filter(inv => inv.status === status);
            console.log('Filtered by status:', allItems);
        }
        
        hideLoading();
        
        // Reset to first page when filter changes
        invoicesCurrentPage = 1;
        
        // Store full filtered results for pagination
        filteredInvoices = allItems || [];
        
        // Implement client-side pagination
        const startIndex = (invoicesCurrentPage - 1) * invoicesPageSize;
        const endIndex = startIndex + invoicesPageSize;
        const pageItems = filteredInvoices.slice(startIndex, endIndex);
        const totalPages = Math.ceil(filteredInvoices.length / invoicesPageSize) || 1;
        
        const paginatedData = {
            items: pageItems,
            pageNumber: invoicesCurrentPage,
            totalPages: totalPages,
            totalCount: filteredInvoices.length
        };
        
        renderInvoicesTable(paginatedData);
        renderInvoicesPagination(paginatedData);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải hóa đơn: ' + error.message);
    }
}

function clearInvoiceFilters() {
    document.getElementById('invoiceMemberIdFilter').value = '';
    document.getElementById('invoiceStatusFilter').value = '';
    filteredInvoices = [];
    invoicesCurrentPage = 1;
    loadInvoices();
}

async function loadInvoicesByStatus() {
    // Redirect to the new filter function
    loadInvoicesByFilter();
}

function renderInvoicesTable(data) {
    const container = document.getElementById('invoicesTableContainer');
    const role = getRole();
    const canManage = role === 'Admin';
    
    const items = data?.Data || data?.data || data?.items || [];
    
    if (!data || items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🧾</div><div class="empty-state-text">Không có hóa đơn nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Thành viên</th>
                    <th>Gói tập</th>
                    <th>Số tiền</th>
                    <th>Ngày HĐ</th>
                    <th>Hạn TT</th>
                    <th>Trạng thái</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    items.forEach(inv => {
        const badge = inv.status === 'Paid' ? 'badge-success' :
                     inv.status === 'Overdue' ? 'badge-danger' : 
                     inv.status === 'Cancelled' ? 'badge-secondary' : 'badge-warning';
        html += `
            <tr>
                <td>${inv.invoiceId}</td>
                <td>${inv.memberName || '-'}</td>
                <td>${inv.packageName || (inv.membershipId ? 'MS ' + inv.membershipId : '-')}</td>
                <td>${formatCurrency(inv.totalAmount)}</td>
                <td>${formatDate(inv.invoiceDate)}</td>
                <td>${formatDate(inv.dueDate)}</td>
                <td><span class="badge ${badge}">${inv.status}</span></td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            ${inv.status !== 'Paid' ? `<button class="btn btn-sm btn-success" onclick="updateInvoiceStatus(${inv.invoiceId}, 'Paid')" title="Đánh dấu đã thanh toán">✓</button>` : ''}
                            <button class="btn btn-sm btn-info" onclick="showEditInvoiceModal(${inv.invoiceId})" title="Sửa">✏️</button>
                            <button class="btn btn-sm btn-danger" onclick="deleteInvoice(${inv.invoiceId})" title="Xóa">🗑️</button>
                        </div>
                    </td>
                ` : ''}
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderInvoicesPagination(data) {
    const container = document.getElementById('invoicesPagination');
    if (!data) return;
    
    const pageNumber = data?.pageNumber || data?.PageNumber || 1;
    const totalPages = data?.totalPages || data?.TotalPages || 1;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeInvoicesPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeInvoicesPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeInvoicesPage(page) {
    const status = document.getElementById('invoiceStatusFilter')?.value;
    
    if (status) {
        // Filter is active
        if (filteredInvoices.length === 0) {
            // Empty results: show empty table, do NOT fall through to unfiltered data
            invoicesCurrentPage = 1;
            renderInvoicesTable({ items: [], pageNumber: 1, totalPages: 1, totalCount: 0 });
            renderInvoicesPagination({ pageNumber: 1, totalPages: 1 });
            return;
        }
        
        // Has results: paginate
        invoicesCurrentPage = page;
        const startIdx = (page - 1) * invoicesPageSize;
        const endIdx = startIdx + invoicesPageSize;
        const pageItems = filteredInvoices.slice(startIdx, endIdx);
        
        renderInvoicesTable({
            items: pageItems,
            pageNumber: page,
            totalPages: Math.ceil(filteredInvoices.length / invoicesPageSize),
            totalCount: filteredInvoices.length
        });
        renderInvoicesPagination({
            pageNumber: page,
            totalPages: Math.ceil(filteredInvoices.length / invoicesPageSize)
        });
    } else {
        // No filter: load from server
        invoicesCurrentPage = page;
        loadInvoices();
    }
}

async function updateInvoiceStatus(invoiceId, status) {
    // Confirmation cho status Paid
    if (status === 'Paid') {
        if (!confirm('Bạn chắc chắn khoản này đã thanh toán?')) {
            return;
        }
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Invoice/${invoiceId}/status`, {
            method: 'PUT',
            body: JSON.stringify({ status })
        });
        hideLoading();
        showSuccess('Cập nhật trạng thái thành công');
        loadInvoices();
    } catch (error) {
        hideLoading();
        showError('Lỗi cập nhật: ' + error.message);
    }
}

// Inject modal styles once
function injectInvoiceModalStyles() {
    if (document.getElementById('invoice-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'invoice-modal-styles';
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

async function showCreateInvoiceModal() {
    injectInvoiceModalStyles();
    
    // Define available packages (same as memberships.js)
    const AVAILABLE_PACKAGES = [
        { id: 'basic', name: 'Gói Cơ Bản', price: 500000, durationDays: 30 },
        { id: 'advanced', name: 'Gói Nâng Cao', price: 1200000, durationDays: 90 },
        { id: 'vip', name: 'Gói VIP', price: 2000000, durationDays: 180 },
        { id: 'annual', name: 'Gói Năm', price: 3500000, durationDays: 365 }
    ];
    
    try {
        showLoading();
        const membersData = await apiFetch('/api/Member?pageNumber=1&pageSize=1000');
        hideLoading();
        
        const members = membersData?.Data || membersData?.data || membersData?.items || [];
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>➕ Tạo Hóa Đơn Mới</h3>
                <form id="createInvoiceForm">
                    <div class="form-group">
                        <label>Thành viên <span class="required">*</span></label>
                        <select id="memberId" name="memberId" required>
                            <option value="">-- Chọn thành viên --</option>
                            ${members.map(m => `<option value="${m.memberId}">${escapeHtml(m.fullName)} (ID: ${m.memberId})</option>`).join('')}
                        </select>
                        <div class="error" id="memberIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>Gói tập / Dịch vụ</label>
                        <select id="packageSelection" name="packageSelection">
                            <option value="">-- Chọn gói hoặc dịch vụ --</option>
                            <optgroup label="📦 Gói Tập Có Sẵn">
                                ${AVAILABLE_PACKAGES.map(pkg => `<option value="package:${pkg.id}" data-price="${pkg.price}">${escapeHtml(pkg.name)} - ${formatCurrency(pkg.price)} (${pkg.durationDays} ngày)</option>`).join('')}
                            </optgroup>
                            <optgroup label="🔧 Khác">
                                <option value="custom">✏️ Gói Tự Chọn (Admin nhập)</option>
                                <option value="other">Phí phát sinh khác</option>
                            </optgroup>
                        </select>
                        <input type="hidden" id="membershipId" name="membershipId">
                        <div class="error" id="packageSelectionError"></div>
                    </div>
                    <div class="form-group" id="customPackageGroup" style="display: none;">
                        <label>Tên gói tự chọn <span class="required">*</span></label>
                        <input type="text" id="customPackageName" placeholder="VD: Gói 6 tháng đặc biệt">
                        <div class="error" id="customPackageNameError"></div>
                    </div>
                    <div class="form-group" id="customPriceGroup" style="display: none;">
                        <label>Giá gói tự chọn (VNĐ) <span class="required">*</span></label>
                        <input type="number" id="customPackagePrice" min="1" step="1000" placeholder="VD: 1500000">
                        <div class="error" id="customPackagePriceError"></div>
                    </div>
                    <div class="form-group">
                        <label>Số tiền (VNĐ) <span class="required">*</span></label>
                        <input type="number" id="totalAmount" name="totalAmount" required min="1" step="1" placeholder="Tự động điền khi chọn gói">
                        <div class="error" id="totalAmountError"></div>
                    </div>
                    <div class="form-group">
                        <label>Ngày hóa đơn <span class="required">*</span></label>
                        <input type="date" id="invoiceDate" name="invoiceDate" required>
                        <div class="error" id="invoiceDateError"></div>
                    </div>
                    <div class="form-group">
                        <label>Hạn thanh toán <span class="required">*</span></label>
                        <input type="date" id="dueDate" name="dueDate" required>
                        <div class="error" id="dueDateError"></div>
                    </div>
                    <div class="form-group">
                        <label>Mô tả</label>
                        <textarea id="description" name="description" rows="3" placeholder="Mô tả về hóa đơn..."></textarea>
                        <div class="error" id="descriptionError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                        <button type="submit" class="btn btn-primary">Tạo Hóa Đơn</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Set default dates
        const today = new Date().toISOString().split('T')[0];
        const sevenDaysLater = new Date();
        sevenDaysLater.setDate(sevenDaysLater.getDate() + 7);
        const dueDate = sevenDaysLater.toISOString().split('T')[0];
        
        document.getElementById('invoiceDate').value = today;
        document.getElementById('dueDate').value = dueDate;
        
        // Package selection handler - auto-fill amount
        const packageSelect = document.getElementById('packageSelection');
        packageSelect.addEventListener('change', (e) => {
            const value = e.target.value;
            const amountInput = document.getElementById('totalAmount');
            const membershipIdInput = document.getElementById('membershipId');
            const customPackageGroup = document.getElementById('customPackageGroup');
            const customPriceGroup = document.getElementById('customPriceGroup');
            const customPackageNameInput = document.getElementById('customPackageName');
            const customPackagePriceInput = document.getElementById('customPackagePrice');
            
            console.log('Package selected:', value);
            
            // Clear membershipId by default
            membershipIdInput.value = '';
            
            // Hide custom package fields by default
            customPackageGroup.style.display = 'none';
            customPriceGroup.style.display = 'none';
            
            if (value.startsWith('package:')) {
                // Available package selected
                const packageId = value.split(':')[1];
                const pkg = AVAILABLE_PACKAGES.find(p => p.id === packageId);
                if (pkg) {
                    amountInput.value = pkg.price;
                    amountInput.readOnly = true; // Lock for predefined packages
                }
            } else if (value === 'custom') {
                // Custom package - show fields for admin to enter name and price
                customPackageGroup.style.display = 'block';
                customPriceGroup.style.display = 'block';
                amountInput.value = '';
                amountInput.readOnly = false; // Allow manual entry if needed
                customPackageNameInput.value = '';
                customPackagePriceInput.value = '';
                
                // Link custom price to totalAmount with one-time listener
                const updateAmount = () => {
                    amountInput.value = customPackagePriceInput.value;
                };
                
                // Remove old listener if exists and add new one
                customPackagePriceInput.removeEventListener('input', updateAmount);
                customPackagePriceInput.addEventListener('input', updateAmount);
            } else if (value === 'other') {
                // Other fee
                amountInput.value = '';
                amountInput.readOnly = false;
                amountInput.placeholder = 'Nhập số tiền phí phát sinh';
            } else {
                // Reset
                amountInput.value = '';
                amountInput.readOnly = false;
                amountInput.placeholder = 'Tự động điền khi chọn gói';
            }
        });
        
        // Form submit handler
        const form = document.getElementById('createInvoiceForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            console.log('=== INVOICE FORM VALIDATION ===');
            
            const memberIdValue = document.getElementById('memberId').value;
            const totalAmountValue = document.getElementById('totalAmount').value;
            
            console.log('Form values:', {
                memberId: memberIdValue,
                totalAmount: totalAmountValue,
                packageSelection: document.getElementById('packageSelection').value
            });
            
            // Validate member selection
            if (!memberIdValue) {
                showError('Vui lòng chọn thành viên');
                return;
            }
            
            // Validate custom package if selected
            const packageSelection = document.getElementById('packageSelection').value;
            if (packageSelection === 'custom') {
                const customPackageName = document.getElementById('customPackageName').value.trim();
                const customPackagePrice = document.getElementById('customPackagePrice').value;
                
                console.log('Custom package validation:', {
                    name: customPackageName,
                    price: customPackagePrice
                });
                
                if (!customPackageName) {
                    showError('Vui lòng nhập tên gói tự chọn');
                    return;
                }
                
                if (!customPackagePrice || parseFloat(customPackagePrice) <= 0) {
                    showError('Vui lòng nhập giá gói tự chọn hợp lệ');
                    return;
                }
            }
            
            // Validate total amount
            if (!totalAmountValue || parseFloat(totalAmountValue) <= 0) {
                showError('Vui lòng nhập số tiền hợp lệ');
                return;
            }
            
            console.log('✅ Custom validation passed, calling validateInvoiceForm()...');
            
            if (!validateInvoiceForm()) {
                console.log('❌ validateInvoiceForm() failed');
                return;
            }
            
            console.log('✅ All validation passed');
            
            const membershipIdValue = document.getElementById('membershipId').value;
            let description = document.getElementById('description').value.trim();
            
            // If custom package, prepend package name to description
            if (packageSelection === 'custom') {
                const customPackageName = document.getElementById('customPackageName').value.trim();
                description = `Gói tự chọn: ${customPackageName}${description ? ' - ' + description : ''}`;
            }
            
            const formData = {
                memberId: parseInt(document.getElementById('memberId').value),
                membershipId: membershipIdValue ? parseInt(membershipIdValue) : null,
                totalAmount: parseFloat(document.getElementById('totalAmount').value),
                invoiceDate: new Date(document.getElementById('invoiceDate').value).toISOString(),
                dueDate: new Date(document.getElementById('dueDate').value + 'T23:59:59').toISOString(),
                description: description || null
            };
            
            console.log('Invoice data:', formData);
            
            try {
                showLoading();
                await apiFetch('/api/Invoice', {
                    method: 'POST',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Tạo hóa đơn thành công!');
                modal.remove();
                await loadInvoices();
            } catch (error) {
                hideLoading();
                showError('Lỗi tạo hóa đơn: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải dữ liệu: ' + error.message);
    }
}

async function showEditInvoiceModal(invoiceId) {
    injectInvoiceModalStyles();
    
    try {
        showLoading();
        const invoice = await apiFetch(`/api/Invoice/${invoiceId}`);
        hideLoading();
        
        if (!invoice) {
            showError('Không tìm thấy hóa đơn');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>✏️ Sửa Hóa Đơn #${invoiceId}</h3>
                <form id="editInvoiceForm">
                    <div class="form-group">
                        <label>Trạng thái <span class="required">*</span></label>
                        <select id="editStatus" name="status" required>
                            <option value="Pending" ${invoice.status === 'Pending' ? 'selected' : ''}>Pending</option>
                            <option value="Paid" ${invoice.status === 'Paid' ? 'selected' : ''}>Paid</option>
                            <option value="Overdue" ${invoice.status === 'Overdue' ? 'selected' : ''}>Overdue</option>
                            <option value="Cancelled" ${invoice.status === 'Cancelled' ? 'selected' : ''}>Cancelled</option>
                        </select>
                        <div class="error" id="editStatusError"></div>
                    </div>
                    <div class="form-group">
                        <label>Thông tin hiện tại</label>
                        <div style="background: #f8f9fa; padding: 12px; border-radius: 6px; font-size: 13px;">
                            <p style="margin: 4px 0;"><strong>Số tiền:</strong> ${formatCurrency(invoice.totalAmount)}</p>
                            <p style="margin: 4px 0;"><strong>Ngày HĐ:</strong> ${formatDate(invoice.invoiceDate)}</p>
                            <p style="margin: 4px 0;"><strong>Hạn TT:</strong> ${formatDate(invoice.dueDate)}</p>
                            ${invoice.description ? `<p style="margin: 4px 0;"><strong>Mô tả:</strong> ${escapeHtml(invoice.description)}</p>` : ''}
                        </div>
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
        const form = document.getElementById('editInvoiceForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const formData = {
                status: document.getElementById('editStatus').value
            };
            
            try {
                showLoading();
                await apiFetch(`/api/Invoice/${invoiceId}`, {
                    method: 'PUT',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Cập nhật hóa đơn thành công!');
                modal.remove();
                await loadInvoices();
            } catch (error) {
                hideLoading();
                showError('Lỗi cập nhật hóa đơn: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải thông tin hóa đơn: ' + error.message);
    }
}

function validateInvoiceForm(isEdit = false) {
    if (isEdit) return true; // Edit form only has status dropdown
    
    const memberId = document.getElementById('memberId');
    const totalAmount = document.getElementById('totalAmount');
    const invoiceDate = document.getElementById('invoiceDate');
    const dueDate = document.getElementById('dueDate');
    
    let isValid = true;
    
    // Clear previous errors
    document.getElementById('memberIdError').textContent = '';
    document.getElementById('totalAmountError').textContent = '';
    document.getElementById('invoiceDateError').textContent = '';
    document.getElementById('dueDateError').textContent = '';
    memberId.classList.remove('invalid');
    totalAmount.classList.remove('invalid');
    invoiceDate.classList.remove('invalid');
    dueDate.classList.remove('invalid');
    
    // Validate member
    if (!memberId.value) {
        document.getElementById('memberIdError').textContent = 'Vui lòng chọn thành viên';
        memberId.classList.add('invalid');
        isValid = false;
    }
    
    // Validate amount
    if (!totalAmount.value || parseFloat(totalAmount.value) <= 0) {
        document.getElementById('totalAmountError').textContent = 'Vui lòng nhập số tiền hợp lệ';
        totalAmount.classList.add('invalid');
        isValid = false;
    }
    
    // Validate dates
    if (!invoiceDate.value) {
        document.getElementById('invoiceDateError').textContent = 'Vui lòng chọn ngày hóa đơn';
        invoiceDate.classList.add('invalid');
        isValid = false;
    }
    
    if (!dueDate.value) {
        document.getElementById('dueDateError').textContent = 'Vui lòng chọn hạn thanh toán';
        dueDate.classList.add('invalid');
        isValid = false;
    }
    
    // Validate due date is after invoice date
    if (invoiceDate.value && dueDate.value && new Date(dueDate.value) < new Date(invoiceDate.value)) {
        document.getElementById('dueDateError').textContent = 'Hạn thanh toán phải sau ngày hóa đơn';
        dueDate.classList.add('invalid');
        isValid = false;
    }
    
    return isValid;
}

async function deleteInvoice(invoiceId) {
    if (!confirm('Bạn có chắc chắn muốn xóa hóa đơn này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Invoice/${invoiceId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa hóa đơn thành công!');
        await loadInvoices();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa hóa đơn: ' + error.message);
    }
}
