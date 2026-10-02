/* ============================================================
   pagination.js – Component phân trang, sắp xếp, lọc tái sử dụng
   ============================================================ */

class Pagination {
  constructor(options = {}) {
    this.containerId = options.containerId;
    this.onPageChange = options.onPageChange || (() => {});
    this.onSortChange = options.onSortChange || (() => {});
    this.onFilterChange = options.onFilterChange || (() => {});
    this.page = 1;
    this.pageSize = options.pageSize || 20;
    this.totalItems = 0;
    this.totalPages = 0;
    this.sortField = options.defaultSortField || '';
    this.sortDirection = options.defaultSortDirection || 'asc';
    this.filters = options.initialFilters || {};
    this.sortableColumns = options.sortableColumns || [];
    this.filterFields = options.filterFields || [];
  }

  render() {
    const container = document.getElementById(this.containerId);
    if (!container) return;

    const totalPages = Math.max(1, Math.ceil(this.totalItems / this.pageSize));
    this.totalPages = totalPages;
    if (this.page > totalPages) this.page = totalPages;

    let html = `
      <div class="pagination-wrapper">
        <div class="pagination-info">
          Hiển thị <strong>${(this.page - 1) * this.pageSize + 1}</strong>–<strong>${Math.min(this.page * this.pageSize, this.totalItems)}</strong> / <strong>${this.totalItems}</strong> bản ghi
        </div>
        <div class="pagination-controls">
          <select class="page-size-select" data-page-size>
            <option value="10" ${this.pageSize === 10 ? 'selected' : ''}>10 / trang</option>
            <option value="20" ${this.pageSize === 20 ? 'selected' : ''}>20 / trang</option>
            <option value="50" ${this.pageSize === 50 ? 'selected' : ''}>50 / trang</option>
            <option value="100" ${this.pageSize === 100 ? 'selected' : ''}>100 / trang</option>
          </select>
          <button class="btn btn-ghost btn-sm" data-page="first" ${this.page === 1 ? 'disabled' : ''} title="Trang đầu">⏮</button>
          <button class="btn btn-ghost btn-sm" data-page="prev" ${this.page === 1 ? 'disabled' : ''} title="Trước">‹</button>
          <span class="page-indicator">Trang <strong>${this.page}</strong> / ${totalPages}</span>
          <button class="btn btn-ghost btn-sm" data-page="next" ${this.page === totalPages ? 'disabled' : ''} title="Sau">›</button>
          <button class="btn btn-ghost btn-sm" data-page="last" ${this.page === totalPages ? 'disabled' : ''} title="Trang cuối">⏭</button>
        </div>
      </div>
    `;

    container.innerHTML = html;

    // Event listeners
    container.querySelector('[data-page-size]').addEventListener('change', (e) => {
      this.pageSize = parseInt(e.target.value);
      this.page = 1;
      this.onPageChange(this.page, this.pageSize, this.sortField, this.sortDirection, this.filters);
    });

    container.querySelector('[data-page="first"]').addEventListener('click', () => this.goToPage(1));
    container.querySelector('[data-page="prev"]').addEventListener('click', () => this.goToPage(this.page - 1));
    container.querySelector('[data-page="next"]').addEventListener('click', () => this.goToPage(this.page + 1));
    container.querySelector('[data-page="last"]').addEventListener('click', () => this.goToPage(totalPages));
  }

  goToPage(page) {
    if (page < 1 || page > this.totalPages) return;
    this.page = page;
    this.onPageChange(this.page, this.pageSize, this.sortField, this.sortDirection, this.filters);
  }

  updateTotal(totalItems) {
    this.totalItems = totalItems;
    this.render();
  }

  setSort(field, direction) {
    this.sortField = field;
    this.sortDirection = direction;
    this.page = 1;
    this.onPageChange(this.page, this.pageSize, field, direction, this.filters);
  }

  setFilters(filters) {
    this.filters = { ...this.filters, ...filters };
    this.page = 1;
    this.onPageChange(this.page, this.pageSize, this.sortField, this.sortDirection, this.filters);
  }

  // Render header row with sort icons
  renderTableHeader(columns, containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    let html = '<tr>';
    columns.forEach(col => {
      const isSortable = this.sortableColumns.includes(col.key);
      let sortIcon = '';
      if (isSortable) {
        if (this.sortField === col.key) {
          sortIcon = this.sortDirection === 'asc' ? ' ▲' : ' ▼';
        } else {
          sortIcon = ' ⇅';
        }
      }
      html += `<th${isSortable ? ' class="sortable" style="cursor:pointer;user-select:none"' : ''} data-sort="${col.key}">${col.label}${sortIcon}</th>`;
    });
    html += '<th>Thao tác</th></tr>';
    container.innerHTML = html;

    // Add click handlers for sortable columns
    if (isSortable) {
      container.querySelectorAll('th.sortable').forEach(th => {
        th.addEventListener('click', () => {
          const field = th.dataset.sort;
          let direction = 'asc';
          if (this.sortField === field && this.sortDirection === 'asc') direction = 'desc';
          this.setSort(field, direction);
        });
      });
    }
  }

  // Render filter row
  renderFilterRow(columns, containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    let html = '<tr class="filter-row">';
    columns.forEach(col => {
      const isFilterable = this.filterFields.includes(col.key);
      if (isFilterable) {
        const currentValue = this.filters[col.key] || '';
        html += `<td><input type="text" class="filter-input" data-filter="${col.key}" value="${currentValue}" placeholder="Lọc..." style="width:100%;padding:4px 8px;border:1px solid var(--border);border-radius:4px;font-size:.8rem" /></td>`;
      } else {
        html += '<td></td>';
      }
    });
    html += '<td></td></tr>';
    container.innerHTML = html;

    // Debounced filter input
    let debounceTimer;
    container.querySelectorAll('.filter-input').forEach(input => {
      input.addEventListener('input', (e) => {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
          this.setFilters({ [e.target.dataset.filter]: e.target.value });
        }, 300);
      });
    });
  }
}

// Export for module usage
window.Pagination = Pagination;
