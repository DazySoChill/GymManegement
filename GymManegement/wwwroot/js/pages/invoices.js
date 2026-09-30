/* pages/invoices.js */
let invoicesList = [];

async function init_invoices() { loadInvoices(); }

async function loadInvoices() {
  loading('invoices-tbody');
  try { invoicesList = await api.getInvoices(); renderInvoices(); } catch (e) { toast(e.message, 'error'); }
}

function renderInvoices(filter = 'all') {
  const tbody = document.getElementById('invoices-tbody');
  let data = filter === 'all' ? invoicesList : invoicesList.filter(i => i.status === filter);
  if (!data.length) { emptyRow('invoices-tbody', 7); return; }
  tbody.innerHTML = data.map(i => `
    <tr>
      <td>${i.invoiceId}</td><td>${i.memberName || i.memberId}</td>
      <td>${moneyFmt(i.totalAmount)}</td><td>${dateFmt(i.invoiceDate)}</td><td>${dateFmt(i.dueDate)}</td>
      <td>${statusBadge(i.status)}</td>
      <td>
        ${i.status === 'Pending' ? `<button class="btn btn-success btn-sm" onclick="markPaid(${i.invoiceId})">✅ Thanh toán</button>` : ''}
        <button class="btn btn-ghost btn-sm" onclick="viewPayments(${i.invoiceId})">💰 Xem TT</button>
      </td>
    </tr>`).join('');
}

document.querySelectorAll('.inv-filter-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.inv-filter-btn').forEach(b => b.classList.remove('btn-primary'));
    btn.classList.add('btn-primary');
    renderInvoices(btn.dataset.filter || 'all');
  });
});

async function openAddInvoice() {
  try {
    const members = await api.getMembers();
    document.getElementById('inv-member').innerHTML = members.map(m => `<option value="${m.memberId}">${m.fullName}</option>`).join('');
    document.getElementById('invoice-form').reset();
    openModal('modal-invoice');
  } catch (e) { toast(e.message, 'error'); }
}

document.getElementById('invoice-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    memberId:    +document.getElementById('inv-member').value,
    totalAmount: +document.getElementById('inv-amount').value,
    invoiceDate: new Date().toISOString(),
    dueDate:     document.getElementById('inv-due').value
  };
  try { await api.createInvoice(body); toast('Tạo hóa đơn thành công', 'success'); closeModal('modal-invoice'); loadInvoices(); }
  catch (err) { toast(err.message, 'error'); }
});

async function markPaid(id) {
  try { await api.updateInvoiceStatus(id, { status: 'Paid' }); toast('Đã thanh toán', 'success'); loadInvoices(); }
  catch (e) { toast(e.message, 'error'); }
}

async function viewPayments(invoiceId) {
  try {
    const payments = await api.getPaymentsByInvoice(invoiceId);
    document.getElementById('payment-list').innerHTML = !payments.length
      ? '<p style="color:var(--muted)">Chưa có thanh toán nào</p>'
      : payments.map(p => `<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid var(--border)"><span><strong>${moneyFmt(p.amount)}</strong> – ${p.paymentMethod}</span><span>${datetimeFmt(p.paymentDate)} ${statusBadge(p.status)}</span></div>`).join('');
    document.getElementById('pay-invoice-id').value = invoiceId;
    openModal('modal-payments');
  } catch (e) { toast(e.message, 'error'); }
}

document.getElementById('payment-form')?.addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    invoiceId:     +document.getElementById('pay-invoice-id').value,
    amount:        +document.getElementById('pay-amount').value,
    paymentDate:   new Date().toISOString(),
    paymentMethod: document.getElementById('pay-method').value
  };
  try { await api.createPayment(body); toast('Thanh toán thành công', 'success'); closeModal('modal-payments'); loadInvoices(); }
  catch (err) { toast(err.message, 'error'); }
});
