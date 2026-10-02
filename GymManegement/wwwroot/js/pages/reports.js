/* pages/reports.js */
async function loadRevenueReport() {
  const month = parseInt(document.getElementById('rep-month').value);
  const year = parseInt(document.getElementById('rep-year').value);
  document.getElementById('btn-load-report').disabled = true;
  document.getElementById('btn-load-report').textContent = 'Đang tải...';

  try {
    const [rev, detail, active] = await Promise.all([
      api.getRevenue(month, year),
      api.getRevenueDetail(month, year),
      api.getActiveMembers({ month, year })
    ]);

    document.getElementById('rep-total').textContent = moneyFmt(rev.totalRevenue ?? 0);
    document.getElementById('rep-paid').textContent = moneyFmt(rev.paidRevenue ?? 0);
    document.getElementById('rep-pending').textContent = moneyFmt((rev.totalRevenue || 0) - (rev.paidRevenue || 0));
    document.getElementById('rep-invoices').textContent = rev.invoiceCount ?? 0;

    const detailTbody = document.getElementById('report-detail-tbody');
    const dData = detail.data ?? [];
    if (!dData.length) { detailTbody.innerHTML = '<tr><td colspan="6" class="table-empty" style="padding:24px">Không có dữ liệu chi tiết</td></tr>'; }
    else {
      detailTbody.innerHTML = dData.map(i => `
        <tr>
          <td>${i.invoiceId}</td>
          <td>${i.memberName || '—'}</td>
          <td>${moneyFmt(i.totalAmount || 0)}</td>
          <td>${dateFmt(i.createdAt)}</td>
          <td>${statusBadge(i.status)}</td>
          <td>${moneyFmt(i.paidAmount || 0)}</td>
        </tr>
      `).join('');
    }

    const activeTbody = document.getElementById('active-members-tbody');
    const aData = active.data ?? [];
    if (!aData.length) { activeTbody.innerHTML = '<tr><td colspan="5" class="table-empty" style="padding:24px">Không có hội viên hoạt động</td></tr>'; }
    else {
      activeTbody.innerHTML = aData.map(m => `
        <tr>
          <td>${m.fullName}</td>
          <td>${m.membershipType || '—'}</td>
          <td>${dateFmt(m.endDate)}</td>
          <td><span class="badge badge-${m.daysRemaining <= 7 ? 'yellow' : 'green'}">${m.daysRemaining} ngày</span></td>
          <td>${m.sessionCount || 0}</td>
        </tr>
      `).join('');
    }
  } catch (e) { console.error(e); toast('Không tải được báo cáo', 'error'); }
  finally { document.getElementById('btn-load-report').disabled = false; document.getElementById('btn-load-report').textContent = 'Xem báo cáo'; }
}

document.getElementById('btn-load-report')?.addEventListener('click', loadRevenueReport);

function init_reports() {
  document.getElementById('rep-month').value = new Date().getMonth() + 1;
  document.getElementById('rep-year').value = new Date().getFullYear();
  loadRevenueReport();
}
