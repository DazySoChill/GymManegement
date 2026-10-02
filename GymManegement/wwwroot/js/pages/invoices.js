/* pages/invoices.js */
let invoicesCurrentPage = 1;
let invoicesPageSize = 10;
let invoicesTotalPages = 1;
let invoicesCurrentFilter = 'all';

async function loadInvoices(page = 1) {
  loading('invoices-tbody');
  invoicesCurrentPage = page;
  try {
    const params = { pageNumber: page, pageSize: invoicesPageSize };
    if (invoicesCurrentFilter !== 'all') params.status = invoicesCurrentFilter;
    const res = await api.getInvoices(params);
    const data = res.data ?? [];
    const total = res.total ?? 0;
    invoicesTotalPages = Math.ceil(total / invoicesPageSize);

    const tbody = document.getElementById('invoices-tbody');
    if (!data.length) { emptyRow('invoices-tbody', 7); }
    else {
      tbody.innerHTML = data.map(inv => `
        <tr>
          <td>${inv.invoiceId}</td>
          <td>${inv.memberName || '—'}</td>
          <td>${moneyFmt(inv.totalAmount || 0)}</td>
          <td>${dateFmt(inv.createdAt)}</td>
          <td>${dateFmt(inv.dueDate)}</td>
          <td>${statusBadge(inv.status)}</td>
          <td>
            <button class="btn btn-icon btn-sm" onclick="openPayments(${inv.invoiceId})" data-tip="Thanh toán"><span>💰</span></button>
            <button class="btn btn-icon btn-sm" onclick="confirmDeleteInvoice(${inv.invoiceId})" data-tip="Xóa"><span>🗑️</span></button>
          </td>
        </tr>
      `).join('');
    }
    renderPagination('invoices-pagination', invoicesCurrentPage, invoicesTotalPages, loadInvoices);
  } catch (e) { console.error(e); emptyRow('invoices-tbody', 7, 'Lỗi tải dữ liệu'); }
}

document.querySelectorAll('#invoice-tabs .tab-btn')?.forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('#invoice-tabs .tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    invoicesCurrentFilter = btn.dataset.filter;
    loadInvoices(1);
  });
});

function openAddInvoice() {
  document.getElementById('invoice-form').reset();
  document.getElementById('inv-due').value = new Date(Date.now() + 7*86400000).toISOString().split('T')[0];
  api.getMembers({ pageSize: 200 }).then(r => populateSelect('inv-member', r.data ?? [], 'memberId', 'fullName'));
  openModal('modal-invoice');
}

document.getElementById('invoice-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = { memberId: parseInt(document.getElementById('inv-member').value), totalAmount: parseFloat(document.getElementById('inv-amount').value), dueDate: document.getElementById('inv-due').value };
  if (!body.memberId || !body.totalAmount) return toast('Vui lòng nhập đầy đủ', 'warning');
  try { await api.createInvoice(body); toast('Tạo hóa đơn thành công', 'success'); closeModal('modal-invoice'); loadInvoices(invoicesCurrentPage); }
  catch (err) { toast(err.message || 'Lỗi lưu', 'error'); }
});

async function openPayments(invoiceId) {
  document.getElementById('pay-invoice-id').value = invoiceId;
  document.getElementById('payment-form').reset();
  try {
    const res = await api.getPaymentsByInvoice(invoiceId);
    const data = res.data ?? [];
    const list = document.getElementById('payment-list');
    if (!data.length) { list.innerHTML = '<p style="color:var(--text-muted);padding:16px 0">Chưa có thanh toán</p>'; }
    else {
      list.innerHTML = data.map(p => `
        <div style="display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid var(--divider)">
          <div><strong>${moneyFmt(p.amount)}</strong> <span class="badge badge-${p.method === 'Cash' ? 'green' : p.method === 'BankTransfer' ? 'blue' : 'purple'}">${p.method}</span></div>
          <div style="color:var(--text-muted);font-size:.8rem">${datetimeFmt(p.createdAt)}</div>
        </div>
      `).join('');
    }
    openModal('modal-payments');
  } catch (e) { toast('Không tải được lịch sử thanh toán', 'error'); }
}

document.getElementById('payment-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = { invoiceId: parseInt(document.getElementById('pay-invoice-id').value), amount: parseFloat(document.getElementById('pay-amount').value), method: document.getElementById('pay-method').value };
  if (!body.amount) return toast('Vui lòng nhập số tiền', 'warning');
  try { await api.createPayment(body); toast('Thanh toán thành công', 'success'); closeModal('modal-payments'); loadInvoices(invoicesCurrentPage); }
  catch (err) { toast(err.message || 'Lỗi thanh toán', 'error'); }
});

function confirmDeleteInvoice(id) {
  document.getElementById('confirm-msg').textContent = 'Bạn có chắc muốn xóa hóa đơn này?';
  document.getElementById('confirm-ok').onclick = async () => {
    try { await api.deleteInvoice(id); toast('Đã xóa', 'success'); loadInvoices(invoicesCurrentPage); }
    catch (err) { toast(err.message || 'Lỗi xóa', 'error'); }
    closeModal('modal-confirm');
  };
  openModal('modal-confirm');
}

function init_invoices() { loadInvoices(1); }
