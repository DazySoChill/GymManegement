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
        
        let html = '<table><thead><tr><th>ID</th><th>Số tiền</th><th>Ngày HĐ</th><th>Hạn thanh toán</th><th>Trạng thái</th></tr></thead><tbody>';
        
        invoices.forEach(inv => {
            const badge = inv.status === 'Paid' ? 'badge-success' :
                         inv.status === 'Overdue' ? 'badge-danger' : 'badge-warning';
            html += `
                <tr>
                    <td>${inv.invoiceId}</td>
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
                <select id="invoiceStatusFilter" onchange="loadInvoicesByStatus()">
                    <option value="">Tất cả</option>
                    <option value="Pending">Pending</option>
                    <option value="Paid">Paid</option>
                    <option value="Overdue">Overdue</option>
                </select>
                <button class="btn btn-info" onclick="loadInvoices()">🔍 Tất cả</button>
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
        const data = await apiFetch(`/api/Invoice?pageNumber=${invoicesCurrentPage}&pageSize=${invoicesPageSize}`);
        hideLoading();
        
        renderInvoicesTable(data);
        renderInvoicesPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lỗi tải danh sách hóa đơn: ' + error.message);
    }
}

async function loadInvoicesByStatus() {
    const status = document.getElementById('invoiceStatusFilter').value;
    
    if (!status) {
        loadInvoices();
        return;
    }
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Invoice/status/${status}`);
        hideLoading();
        
        renderInvoicesTable({ items: data, pageNumber: 1, totalPages: 1 });
    } catch (error) {
        hideLoading();
        showError('Lỗi tải hóa đơn: ' + error.message);
    }
}

function renderInvoicesTable(data) {
    const container = document.getElementById('invoicesTableContainer');
    const role = getRole();
    const canManage = role === 'Admin';
    
    if (!data || !data.items || data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🧾</div><div class="empty-state-text">Không có hóa đơn nào</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Membership ID</th>
                    <th>Số tiền</th>
                    <th>Ngày HĐ</th>
                    <th>Hạn TT</th>
                    <th>Trạng thái</th>
                    ${canManage ? '<th>Thao tác</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    data.items.forEach(inv => {
        const badge = inv.status === 'Paid' ? 'badge-success' :
                     inv.status === 'Overdue' ? 'badge-danger' : 'badge-warning';
        html += `
            <tr>
                <td>${inv.invoiceId}</td>
                <td>${inv.membershipId}</td>
                <td>${formatCurrency(inv.totalAmount)}</td>
                <td>${formatDate(inv.invoiceDate)}</td>
                <td>${formatDate(inv.dueDate)}</td>
                <td><span class="badge ${badge}">${inv.status}</span></td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-success" onclick="updateInvoiceStatus(${inv.invoiceId}, 'Paid')">✓ Đã TT</button>
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
    
    const { pageNumber, totalPages } = data;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeInvoicesPage(${pageNumber - 1})">‹ Trước</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeInvoicesPage(${pageNumber + 1})">Sau ›</button>
    `;
    
    container.innerHTML = html;
}

function changeInvoicesPage(page) {
    invoicesCurrentPage = page;
    loadInvoices();
}

async function updateInvoiceStatus(invoiceId, status) {
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

function showCreateInvoiceModal() {
    showError('Chức năng tạo hóa đơn chưa được triển khai đầy đủ');
}
