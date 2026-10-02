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
    const expiringEl = document.getElementById('expiring-list');
    if (!eData.length) {
      expiringEl.innerHTML = '<div class="table-empty" style="padding:24px"><span class="icon">🎫</span>Không có hội viên sắp hết hạn</div>';
    } else {
      expiringEl.innerHTML = eData.slice(0, 8).map(x => `
        <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--divider)">
          <div><strong>${x.fullName}</strong><br><small style="color:var(--text-muted)">${x.email ?? ''}</small></div>
          <div style="text-align:right"><span class="badge badge-yellow">${x.daysRemaining} ngày</span><br><small style="color:var(--text-muted)">${dateFmt(x.endDate)}</small></div>
        </div>
      `).join('');
    }

    // Overdue invoices
    const oData = Array.isArray(overdueList) ? overdueList : [];
    const overdueEl = document.getElementById('overdue-list');
    if (!oData.length) {
      overdueEl.innerHTML = '<div class="table-empty" style="padding:24px"><span class="icon">🧾</span>Không có hóa đơn quá hạn</div>';
    } else {
      overdueEl.innerHTML = oData.slice(0, 8).map(i => `
        <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--divider)">
          <div><strong>${i.memberName}</strong></div>
          <div>${moneyFmt(i.totalAmount)} <span class="badge badge-red">Quá hạn</span></div>
        </div>
      `).join('');
    }
  } catch (e) { console.error('Dashboard error:', e); toast('Không tải được dữ liệu dashboard', 'error'); }
}
