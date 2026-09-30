/* pages/dashboard.js */
async function init_dashboard() {
  try {
    const [members, overdueList, expiring, revenue] = await Promise.all([
      api.getActiveMembers(),
      api.getOverdueInvoices(),
      api.getExpiringSoon(7),
      api.getRevenue(new Date().getMonth() + 1, new Date().getFullYear())
    ]);

    document.getElementById('stat-active').textContent   = members.total ?? members.data?.length ?? 0;
    document.getElementById('stat-overdue').textContent  = Array.isArray(overdueList) ? overdueList.length : 0;
    document.getElementById('stat-expiring').textContent = expiring.data?.length ?? 0;
    document.getElementById('stat-revenue').textContent  = moneyFmt(revenue.paidRevenue ?? 0);

    // Expiring soon
    const eData = expiring.data ?? [];
    document.getElementById('expiring-list').innerHTML = !eData.length
      ? '<p style="color:var(--muted);padding:16px 0">Không có hội viên sắp hết hạn</p>'
      : eData.slice(0, 8).map(x => `
          <div style="display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid var(--border)">
            <div><strong>${x.fullName}</strong><br><small style="color:var(--muted)">${x.email ?? ''}</small></div>
            <div style="text-align:right"><span class="badge badge-yellow">${x.daysRemaining} ngày</span><br><small style="color:var(--muted)">${dateFmt(x.endDate)}</small></div>
          </div>`).join('');

    // Overdue invoices
    const oData = Array.isArray(overdueList) ? overdueList : [];
    document.getElementById('overdue-list').innerHTML = !oData.length
      ? '<p style="color:var(--muted);padding:16px 0">Không có hóa đơn quá hạn</p>'
      : oData.slice(0, 8).map(i => `
          <div style="display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid var(--border)">
            <div><strong>${i.memberName}</strong></div>
            <div>${moneyFmt(i.totalAmount)} <span class="badge badge-red">Quá hạn</span></div>
          </div>`).join('');
  } catch (e) { console.error('Dashboard error:', e); }
}
