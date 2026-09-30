/* pages/reports.js */
async function init_reports() {
  const now = new Date();
  document.getElementById('rep-month').value = now.getMonth() + 1;
  document.getElementById('rep-year').value  = now.getFullYear();
  loadReport();
}

async function loadReport() {
  const month = +document.getElementById('rep-month').value;
  const year  = +document.getElementById('rep-year').value;
  try {
    const [rev, detail, active] = await Promise.all([
      api.getRevenue(month, year),
      api.getRevenueDetail(month, year),
      api.getActiveMembers()
    ]);

    document.getElementById('rep-total').textContent    = moneyFmt(rev.totalRevenue ?? 0);
    document.getElementById('rep-paid').textContent     = moneyFmt(rev.paidRevenue ?? 0);
    document.getElementById('rep-pending').textContent  = moneyFmt(rev.pendingRevenue ?? 0);
    document.getElementById('rep-invoices').textContent = rev.totalInvoices ?? 0;

    const detailData = detail.data ?? [];
    document.getElementById('report-detail-tbody').innerHTML = !detailData.length
      ? '<tr><td colspan="6" style="text-align:center;padding:30px;color:var(--muted)">Không có dữ liệu</td></tr>'
      : detailData.map(r => `
          <tr>
            <td>${r.invoiceId}</td><td>${r.memberName}</td>
            <td>${moneyFmt(r.totalAmount)}</td><td>${dateFmt(r.invoiceDate)}</td>
            <td>${statusBadge(r.status)}</td>
            <td>${r.paidAmount ? moneyFmt(r.paidAmount) : '—'}</td>
          </tr>`).join('');

    const aData = active.data ?? [];
    document.getElementById('active-members-tbody').innerHTML = !aData.length
      ? '<tr><td colspan="5" style="text-align:center;padding:30px;color:var(--muted)">Không có dữ liệu</td></tr>'
      : aData.map(m => `
          <tr>
            <td>${m.fullName}</td><td>${m.membershipType}</td><td>${dateFmt(m.endDate)}</td>
            <td><span class="badge ${m.daysRemaining <= 7 ? 'badge-red' : m.daysRemaining <= 30 ? 'badge-yellow' : 'badge-green'}">${m.daysRemaining} ngày</span></td>
            <td>${m.totalCheckins}</td>
          </tr>`).join('');
  } catch (e) { toast(e.message, 'error'); }
}

document.getElementById('btn-load-report')?.addEventListener('click', loadReport);
