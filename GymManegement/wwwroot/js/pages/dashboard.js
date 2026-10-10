/* pages/dashboard.js */
async function init_dashboard() {
  const user = getCurrentUser();
  const role = user?.role;

  if (isAdmin()) {
    // Admin view: show all stats
    try {
      const [members, overdueList, revenue] = await Promise.all([
        api.getActiveMembers().catch(err => { 
          // Let 401 propagate to trigger auto-logout
          if (err.message === 'Phiên đăng nhập hết hạn') throw err;
          return { total: 0, data: [] };
        }),
        api.getOverdueInvoices().catch(err => { 
          if (err.message === 'Phiên đăng nhập hết hạn') throw err;
          return [];
        }),
        api.getRevenue(new Date().getMonth() + 1, new Date().getFullYear()).catch(err => { 
          if (err.message === 'Phiên đăng nhập hết hạn') throw err;
          return { paidRevenue: 0 };
        })
      ]);

      document.getElementById('stat-active').textContent = members.total ?? members.data?.length ?? 0;
      document.getElementById('stat-overdue').textContent = Array.isArray(overdueList) ? overdueList.length : 0;
      document.getElementById('stat-expiring').textContent = '—'; // Skip expiring (404 endpoint)
      document.getElementById('stat-revenue').textContent = moneyFmt(revenue.paidRevenue ?? 0);

      // Skip expiring soon list (404 endpoint)
      const expiringEl = document.getElementById('expiring-list');
      expiringEl.innerHTML = '<div class="table-empty" style="padding:24px"><span class="icon">🎫</span>Chức năng tạm thời không khả dụng</div>';

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
    } catch (e) {
      // Don't swallow 401 errors - they trigger auto-logout in apiFetch
      if (e.message === 'Phiên đăng nhập hết hạn') throw e;
      console.error('Dashboard error:', e);
      toast('Không tải được một số dữ liệu dashboard', 'warning');
    }
  } else if (isMember()) {
    // Member view: show own membership and checkin stats
    try {
      const memberId = user.memberId;
      
      // Load own membership
      const membershipRes = await api.getMemberships(memberId).catch(err => { 
        if (err.message === 'Phiên đăng nhập hết hạn') throw err;
        return { data: [] };
      });
      const memberships = membershipRes.data ?? [];
      
      // Load recent checkins
      const checkinRes = await api.getCheckins({ memberId: memberId, pageSize: 5 }).catch(err => { 
        if (err.message === 'Phiên đăng nhập hết hạn') throw err;
        return { data: [] };
      });
      const checkins = checkinRes.data ?? [];

      // Update stats for member
      document.getElementById('stat-active').textContent = memberships.length > 0 ? '✓ Active' : '✗ None';
      document.getElementById('stat-overdue').textContent = checkins.length;
      document.getElementById('stat-expiring').textContent = '—';
      document.getElementById('stat-revenue').textContent = '—';

      // Show membership status
      const expiringEl = document.getElementById('expiring-list');
      if (memberships.length === 0) {
        expiringEl.innerHTML = '<div class="table-empty" style="padding:24px"><span class="icon">🎫</span>Bạn chưa có gói tập nào</div>';
      } else {
        expiringEl.innerHTML = memberships.slice(0, 3).map(m => `
          <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--divider)">
            <div><strong>${m.membershipType}</strong><br><small style="color:var(--text-muted)">${dateFmt(m.startDate)} - ${dateFmt(m.endDate)}</small></div>
            <div style="text-align:right">${statusBadge(m.status)}<br><small style="color:var(--text-muted)">${moneyFmt(m.price)}</small></div>
          </div>
        `).join('');
      }

      // Show recent checkins
      const overdueEl = document.getElementById('overdue-list');
      if (checkins.length === 0) {
        overdueEl.innerHTML = '<div class="table-empty" style="padding:24px"><span class="icon">✅</span>Chưa có check-in nào</div>';
      } else {
        overdueEl.innerHTML = checkins.map(c => `
          <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--divider)">
            <div><strong>Check-in</strong><br><small style="color:var(--text-muted)">${c.method ?? 'Manual'}</small></div>
            <div style="text-align:right"><small>${datetimeFmt(c.checkinTime)}</small></div>
          </div>
        `).join('');
      }

      // Update card headers for member view
      document.querySelector('#expiring-list').closest('.card').querySelector('h2').textContent = '🎫 Gói tập của bạn';
      document.querySelector('#overdue-list').closest('.card').querySelector('h2').textContent = '✅ Check-in gần đây';

    } catch (e) {
      // Don't swallow 401 errors - they trigger auto-logout in apiFetch
      if (e.message === 'Phiên đăng nhập hết hạn') throw e;
      console.error('Dashboard error:', e);
      toast('Không tải được dữ liệu dashboard', 'warning');
    }
  }
}
