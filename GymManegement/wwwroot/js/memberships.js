/**
 * Memberships Management Module
 */

let membershipsCurrentPage = 1;
let membershipsPageSize = 10;

// Available packages for purchase
const AVAILABLE_PACKAGES = [
  { id: 'basic', name: 'GÃ³i CÆ¡ Báº£n', price: 500000, durationDays: 30, description: '1 thÃ¡ng - Sá»­ dá»¥ng táº¥t cáº£ thiáº¿t bá»‹' },
  { id: 'advanced', name: 'GÃ³i NÃ¢ng Cao', price: 1200000, durationDays: 90, description: '3 thÃ¡ng - Bao gá»“m 2 buá»•i PT/thÃ¡ng' },
  { id: 'vip', name: 'GÃ³i VIP', price: 2000000, durationDays: 180, description: '6 thÃ¡ng - KhÃ´ng giá»›i háº¡n PT + dinh dÆ°á»¡ng' },
  { id: 'annual', name: 'GÃ³i NÄƒm', price: 3500000, durationDays: 365, description: '12 thÃ¡ng - Táº¥t cáº£ dá»‹ch vá»¥ cao cáº¥p' }
];

// Inject modal styles once
function injectModalStyles() {
    if (document.getElementById('membership-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'membership-modal-styles';
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
            max-width: 420px;
            width: 90%;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
        }
        .gym-modal h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: #2c3e50;
        }
        .gym-modal-buttons {
            display: flex;
            gap: 12px;
            margin-top: 24px;
            justify-content: flex-end;
        }
        .qr-placeholder {
            width: 180px;
            height: 180px;
            background: #f0f0f0;
            border: 2px dashed #999;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
            margin: 20px auto;
            border-radius: 8px;
        }
        .date-picker-group {
            margin: 16px 0;
        }
        .date-picker-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        .date-picker-group input[type="date"] {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .date-display {
            margin-top: 12px;
            padding: 12px;
            background: #f8f9fa;
            border-radius: 6px;
            color: #495057;
        }
        .confirm-input-group {
            margin: 20px 0;
        }
        .confirm-input-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        .confirm-input-group input {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .warning-text {
            background: #fff3cd;
            border: 1px solid #ffc107;
            padding: 12px;
            border-radius: 6px;
            color: #856404;
            margin: 16px 0;
        }
    `;
    document.head.appendChild(style);
}

async function renderMemberships(container) {
    const role = getRole();
    const memberId = getMemberId();
    
    if (role === 'Member' && memberId) {
        // Member view - show only own memberships
        await renderMemberMemberships(container, memberId);
    } else {
        // Admin/Trainer view - show all memberships
        await renderAllMemberships(container);
    }
}

function renderAvailablePackages(memberId) {
    let html = '<div class="packages-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin-bottom: 20px;">';
    
    AVAILABLE_PACKAGES.forEach(pkg => {
        html += `
            <div class="package-card" style="border: 2px solid #27ae60; border-radius: 12px; padding: 20px; background: #f8fff8;">
                <h4 style="margin: 0 0 12px 0; color: #27ae60; font-size: 18px;">${escapeHtml(pkg.name)}</h4>
                <div style="font-size: 24px; font-weight: bold; color: #2c3e50; margin-bottom: 8px;">${formatCurrency(pkg.price)}</div>
                <div style="color: #7f8c8d; margin-bottom: 12px; font-size: 14px;">${escapeHtml(pkg.description)}</div>
                <div style="margin-bottom: 16px; color: #555;">â±ï¸ ${pkg.durationDays} ngÃ y</div>
                <button class="btn btn-success" onclick="showPurchaseModal(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId})" style="width: 100%;">ðŸ’³ Mua GÃ³i</button>
            </div>
        `;
    });
    
    html += '</div>';
    return html;
}

function showPurchaseModal(pkg, memberId) {
    injectModalStyles();
    
    const today = new Date().toISOString().split('T')[0];
    const oneYearFromNow = new Date();
    oneYearFromNow.setFullYear(oneYearFromNow.getFullYear() + 1);
    const maxDate = oneYearFromNow.toISOString().split('T')[0];
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>XÃ¡c Nháº­n Mua GÃ³i</h3>
            <div style="margin-bottom: 16px;">
                <strong>GÃ³i:</strong> ${escapeHtml(pkg.name)}
            </div>
            <div style="margin-bottom: 16px;">
                <strong>GiÃ¡:</strong> ${formatCurrency(pkg.price)}
            </div>
            <div style="margin-bottom: 16px;">
                <strong>Thá»i háº¡n:</strong> ${pkg.durationDays} ngÃ y
            </div>
            <div class="date-picker-group">
                <label for="startDatePicker">NgÃ y báº¯t Ä‘áº§u:</label>
                <input type="date" id="startDatePicker" value="${today}" min="${today}" max="${maxDate}">
            </div>
            <div class="date-display" id="endDateDisplay">
                <strong>NgÃ y káº¿t thÃºc:</strong> <span id="endDateValue">Äang tÃ­nh toÃ¡n...</span>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Há»§y</button>
                <button class="btn btn-success" onclick="processPurchaseWithDate(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}, 'Cash'); this.closest('.gym-modal-overlay').remove();">ðŸ’µ Tiá»n Máº·t</button>
                <button class="btn btn-primary" onclick="showQRPaymentModalWithDate(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}); this.closest('.gym-modal-overlay').remove();">ðŸ“± Thanh ToÃ¡n QR</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Update end date when start date changes
    const startDatePicker = document.getElementById('startDatePicker');
    const updateEndDate = () => {
        const startDate = startDatePicker.value;
        const endDate = calculateEndDate(startDate, pkg.durationDays);
        document.getElementById('endDateValue').textContent = formatDate(endDate);
    };
    startDatePicker.addEventListener('change', updateEndDate);
    updateEndDate(); // Initial calculation
}

function calculateEndDate(startDate, durationDays) {
    const start = new Date(startDate);
    const end = new Date(start);
    end.setDate(start.getDate() + durationDays - 1); // -1 because if you start on day 1 of a 30-day package, it ends on day 30
    return end.toISOString().split('T')[0];
}

function processPurchaseWithDate(pkg, memberId, paymentMethod) {
    const startDatePicker = document.getElementById('startDatePicker');
    const startDate = startDatePicker ? startDatePicker.value : new Date().toISOString().split('T')[0];
    processPurchase(pkg, memberId, paymentMethod, startDate);
}

function showQRPaymentModal(pkg, memberId) {
    injectModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Thanh ToÃ¡n QR</h3>
            <div class="qr-placeholder">ðŸ“±</div>
            <div style="text-align: center; margin: 16px 0; font-size: 16px; color: #2c3e50;">
                QuÃ©t mÃ£ QR Ä‘á»ƒ thanh toÃ¡n <strong>${formatCurrency(pkg.price)}</strong>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Há»§y</button>
                <button class="btn btn-success" onclick="processPurchase(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}, 'QRCode'); this.closest('.gym-modal-overlay').remove();">âœ… XÃ¡c Nháº­n ÄÃ£ Thanh ToÃ¡n</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

function showQRPaymentModalWithDate(pkg, memberId) {
    const startDatePicker = document.getElementById('startDatePicker');
    const startDate = startDatePicker ? startDatePicker.value : new Date().toISOString().split('T')[0];
    
    injectModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>Thanh ToÃ¡n QR</h3>
            <div class="qr-placeholder">ðŸ“±</div>
            <div style="text-align: center; margin: 16px 0; font-size: 16px; color: #2c3e50;">
                QuÃ©t mÃ£ QR Ä‘á»ƒ thanh toÃ¡n <strong>${formatCurrency(pkg.price)}</strong>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Há»§y</button>
                <button class="btn btn-success" onclick="processPurchase(${JSON.stringify(pkg).replace(/"/g, '&quot;')}, ${memberId}, 'QRCode', '${startDate}'); this.closest('.gym-modal-overlay').remove();">âœ… XÃ¡c Nháº­n ÄÃ£ Thanh ToÃ¡n</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

async function processPurchase(pkg, memberId, method = 'QRCode', startDate = null) {
    try {
        showLoading();
        
        // Use provided start date or default to today
        const start = startDate ? new Date(startDate) : new Date();
        const end = new Date(start);
        end.setDate(start.getDate() + pkg.durationDays - 1);
        // Set end time to end of day
        end.setHours(23, 59, 59, 999);
        
        // Step 1: Create payment record (using /process endpoint for Members)
        const paymentData = {
            memberId: memberId,
            amount: pkg.price,
            paymentMethod: method,
            paymentDate: new Date().toISOString(),
            transactionId: (method === 'Cash' ? 'CASH_' : 'QR_') + Date.now(),
            status: 'Completed'
        };
        
        await apiFetch('/api/Payment/process', {
            method: 'POST',
            body: JSON.stringify(paymentData)
        });
        
        // Step 2: Create membership (using /purchase endpoint for Members)
        const membershipData = {
            memberId: memberId,
            packageName: pkg.name,
            price: pkg.price,
            startDate: start.toISOString(),
            endDate: end.toISOString()
        };
        
        await apiFetch('/api/Membership/purchase', {
            method: 'POST',
            body: JSON.stringify(membershipData)
        });
        
        hideLoading();
        showToast('Mua gÃ³i táº­p thÃ nh cÃ´ng!', 'success');
        
        // Reload to show new membership
        setTimeout(() => {
            reloadCurrentPage();
        }, 1500);
        
    } catch (error) {
        hideLoading();
        let errorMessage = 'ÄÃ£ xáº£y ra lá»—i há»‡ thá»‘ng. Vui lÃ²ng thá»­ láº¡i sau.';
        
        // Check for specific error messages
        if (error.message) {
            if (error.message.toLowerCase().includes('active membership') || 
                error.message.toLowerCase().includes('Ä‘Ã£ cÃ³ gÃ³i táº­p')) {
                errorMessage = 'Báº¡n Ä‘Ã£ cÃ³ gÃ³i táº­p Ä‘ang hoáº¡t Ä‘á»™ng. Vui lÃ²ng há»§y gÃ³i hiá»‡n táº¡i trÆ°á»›c khi mua gÃ³i má»›i.';
            } else if (error.message.toLowerCase().includes('payment')) {
                errorMessage = 'Lá»—i thanh toÃ¡n. Vui lÃ²ng thá»­ láº¡i sau.';
            } else if (error.message.toLowerCase().includes('membership')) {
                errorMessage = 'Lá»—i táº¡o gÃ³i táº­p. Vui lÃ²ng liÃªn há»‡ quáº£n trá»‹ viÃªn.';
            } else {
                errorMessage = error.message;
            }
        }
        
        showToast('Lá»—i mua gÃ³i táº­p: ' + errorMessage, 'error');
    }
}

async function renderMemberMemberships(container, memberId) {
    injectModalStyles();
    
    container.innerHTML = `
        <div class="card" style="margin-bottom: 24px;">
            <div class="card-header">
                <h2 class="card-title">GÃ³i Táº­p CÃ³ Sáºµn</h2>
            </div>
            <div id="availablePackagesContainer" style="padding: 20px;"></div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">GÃ³i Táº­p Cá»§a TÃ´i</h2>
            </div>
            <div id="myMembershipsContainer"></div>
        </div>
    `;
    
    // Render available packages
    document.getElementById('availablePackagesContainer').innerHTML = renderAvailablePackages(memberId);
    
    try {
        showLoading();
        const memberships = await apiFetch(`/api/Membership/member/${memberId}`);
        hideLoading();
        
        const myContainer = document.getElementById('myMembershipsContainer');
        if (!memberships || memberships.length === 0) {
            myContainer.innerHTML = '<div class="empty-state"><div class="empty-state-icon">ðŸŽ«</div><div class="empty-state-text">Báº¡n chÆ°a cÃ³ gÃ³i táº­p nÃ o</div></div>';
            return;
        }
        
        let html = '<table><thead><tr><th>GÃ³i</th><th>GiÃ¡</th><th>NgÃ y báº¯t Ä‘áº§u</th><th>NgÃ y káº¿t thÃºc</th><th>CÃ²n láº¡i</th><th>Thao tÃ¡c</th></tr></thead><tbody>';
        
        memberships.forEach(m => {
            const daysClass = m.daysRemaining < 7 ? 'badge-danger' : m.daysRemaining < 30 ? 'badge-warning' : 'badge-success';
            const isActive = m.daysRemaining > 0;
            html += `
                <tr>
                    <td>${escapeHtml(m.packageName)}</td>
                    <td>${formatCurrency(m.price)}</td>
                    <td>${formatDate(m.startDate)}</td>
                    <td>${formatDate(m.endDate)}</td>
                    <td><span class="badge ${daysClass}">${m.daysRemaining} ngÃ y</span></td>
                    <td>
                        ${isActive ? `<button class="btn btn-sm btn-danger" onclick="cancelMembership(${m.membershipId})">âŒ Há»§y GÃ³i</button>` : '<span style="color: #999;">ÄÃ£ háº¿t háº¡n</span>'}
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        myContainer.innerHTML = html;
        
    } catch (error) {
        hideLoading();
        showError('Lá»—i táº£i gÃ³i táº­p: ' + error.message);
    }
}

async function renderAllMemberships(container) {
    const role = getRole();
    const canManage = role === 'Admin';
    
    container.innerHTML = `
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">Quáº£n lÃ½ GÃ³i Táº­p</h2>
                ${canManage ? '<button class="btn btn-primary" onclick="showCreateMembershipModal()">âž• ThÃªm gÃ³i táº­p</button>' : ''}
            </div>
            
            <div class="filters">
                <input type="text" id="membershipSearch" placeholder="TÃ¬m kiáº¿m..." style="width: 300px;">
                <button class="btn btn-info" onclick="loadMemberships()">ðŸ” TÃ¬m</button>
            </div>
            
            <div class="table-container" id="membershipsTableContainer"></div>
            <div id="membershipsPagination" class="pagination"></div>
        </div>
    `;
    
    await loadMemberships();
}

async function loadMemberships() {
    const searchTerm = document.getElementById('membershipSearch')?.value || '';
    
    try {
        showLoading();
        const data = await apiFetch(`/api/Membership?pageNumber=${membershipsCurrentPage}&pageSize=${membershipsPageSize}&searchTerm=${encodeURIComponent(searchTerm)}`);
        hideLoading();
        
        renderMembershipsTable(data);
        renderMembershipsPagination(data);
    } catch (error) {
        hideLoading();
        showError('Lá»—i táº£i danh sÃ¡ch gÃ³i táº­p: ' + error.message);
    }
}

function renderMembershipsTable(data) {
    const container = document.getElementById('membershipsTableContainer');
    const role = getRole();
    const canManage = role === 'Admin';
    
    // Defensive accessor for items
    const items = data?.data || data?.items || [];
    if (items.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">ðŸŽ«</div><div class="empty-state-text">KhÃ´ng cÃ³ gÃ³i táº­p nÃ o</div></div>';
        return;
    }
    
    let html = `
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>ThÃ nh viÃªn</th>
                    <th>GÃ³i</th>
                    <th>GiÃ¡</th>
                    <th>NgÃ y báº¯t Ä‘áº§u</th>
                    <th>NgÃ y káº¿t thÃºc</th>
                    <th>CÃ²n láº¡i</th>
                    ${canManage ? '<th>Thao tÃ¡c</th>' : ''}
                </tr>
            </thead>
            <tbody>
    `;
    
    items.forEach(m => {
        const daysClass = m.daysRemaining < 7 ? 'badge-danger' : m.daysRemaining < 30 ? 'badge-warning' : 'badge-success';
        html += `
            <tr>
                <td>${m.membershipId}</td>
                <td>${m.memberName || 'Member ' + m.memberId}</td>
                <td>${escapeHtml(m.packageName)}</td>
                <td>${formatCurrency(m.price)}</td>
                <td>${formatDate(m.startDate)}</td>
                <td>${formatDate(m.endDate)}</td>
                <td><span class="badge ${daysClass}">${m.daysRemaining} ngÃ y</span></td>
                ${canManage ? `
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-info" onclick="showEditMembershipModal(${m.membershipId})">âœï¸</button>
                            <button class="btn btn-sm btn-danger" onclick="deleteMembership(${m.membershipId})">ðŸ—‘ï¸ XÃ³a</button>
                        </div>
                    </td>
                ` : ''}
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderMembershipsPagination(data) {
    const container = document.getElementById('membershipsPagination');
    if (!data) return;
    
    // Defensive accessors for pagination metadata
    const pageNumber = data?.pageNumber || 1;
    const totalPages = data?.totalPages || 1;
    
    let html = `
        <button ${pageNumber <= 1 ? 'disabled' : ''} onclick="changeMembershipsPage(${pageNumber - 1})">â€¹ TrÆ°á»›c</button>
        <span class="page-info">Trang ${pageNumber} / ${totalPages}</span>
        <button ${pageNumber >= totalPages ? 'disabled' : ''} onclick="changeMembershipsPage(${pageNumber + 1})">Sau â€º</button>
    `;
    
    container.innerHTML = html;
}

function changeMembershipsPage(page) {
    membershipsCurrentPage = page;
    loadMemberships();
}

async function showCreateMembershipModal() {
    injectModalStyles();
    
    try {
        showLoading();
        // Fetch members for dropdown
        const membersData = await apiFetch('/api/Member?pageNumber=1&pageSize=1000');
        hideLoading();
        
        const members = membersData.items || [];
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()" style="position: absolute; top: 16px; right: 16px; background: none; border: none; font-size: 24px; cursor: pointer; color: #999;">&times;</button>
                <h3>âž• Táº¡o GÃ³i Táº­p Má»›i</h3>
                <form id="createMembershipForm">
                    <div class="form-group">
                        <label>ThÃ nh viÃªn <span class="required">*</span></label>
                        <select id="memberId" name="memberId" required style="width: 100%; padding: 10px; border: 2px solid #ddd; border-radius: 6px;">
                            <option value="">-- Chá»n thÃ nh viÃªn --</option>
                            ${members.map(m => `<option value="${m.memberId}">${escapeHtml(m.fullName)} (ID: ${m.memberId})</option>`).join('')}
                        </select>
                        <div class="error" id="memberIdError"></div>
                    </div>
                    <div class="form-group">
                        <label>TÃªn gÃ³i <span class="required">*</span></label>
                        <input type="text" id="packageName" name="packageName" required placeholder="VD: GÃ³i CÆ¡ Báº£n, GÃ³i VIP">
                        <div class="error" id="packageNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>GiÃ¡ (VNÄ) <span class="required">*</span></label>
                        <input type="number" id="price" name="price" required min="0" step="1000" placeholder="500000">
                        <div class="error" id="priceError"></div>
                    </div>
                    <div class="form-group">
                        <label>NgÃ y báº¯t Ä‘áº§u <span class="required">*</span></label>
                        <input type="date" id="startDate" name="startDate" required>
                        <div class="error" id="startDateError"></div>
                    </div>
                    <div class="form-group">
                        <label>NgÃ y káº¿t thÃºc <span class="required">*</span></label>
                        <input type="date" id="endDate" name="endDate" required>
                        <div class="error" id="endDateError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Há»§y</button>
                        <button type="submit" class="btn btn-primary">Táº¡o GÃ³i</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Set default dates
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('startDate').value = today;
        
        // Form submit handler
        const form = document.getElementById('createMembershipForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (!validateMembershipForm()) {
                return;
            }
            
            const formData = {
                memberId: parseInt(document.getElementById('memberId').value),
                packageName: document.getElementById('packageName').value.trim(),
                price: parseFloat(document.getElementById('price').value),
                startDate: new Date(document.getElementById('startDate').value).toISOString(),
                endDate: new Date(document.getElementById('endDate').value + 'T23:59:59').toISOString()
            };
            
            try {
                showLoading();
                await apiFetch('/api/Membership', {
                    method: 'POST',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Táº¡o gÃ³i táº­p thÃ nh cÃ´ng!');
                modal.remove();
                await loadMemberships();
            } catch (error) {
                hideLoading();
                showError('Lá»—i táº¡o gÃ³i táº­p: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lá»—i táº£i danh sÃ¡ch thÃ nh viÃªn: ' + error.message);
    }
}

async function showEditMembershipModal(membershipId) {
    injectModalStyles();
    
    try {
        showLoading();
        const membership = await apiFetch(`/api/Membership/${membershipId}`);
        hideLoading();
        
        if (!membership) {
            showError('KhÃ´ng tÃ¬m tháº¥y gÃ³i táº­p');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()" style="position: absolute; top: 16px; right: 16px; background: none; border: none; font-size: 24px; cursor: pointer; color: #999;">&times;</button>
                <h3>âœï¸ Sá»­a GÃ³i Táº­p</h3>
                <form id="editMembershipForm">
                    <div class="form-group">
                        <label>Member ID</label>
                        <input type="text" value="${membership.memberId}" disabled style="background: #f5f5f5;">
                    </div>
                    <div class="form-group">
                        <label>TÃªn gÃ³i <span class="required">*</span></label>
                        <input type="text" id="editPackageName" name="packageName" value="${escapeHtml(membership.packageName)}" required>
                        <div class="error" id="editPackageNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>GiÃ¡ (VNÄ) <span class="required">*</span></label>
                        <input type="number" id="editPrice" name="price" value="${membership.price}" required min="0" step="1000">
                        <div class="error" id="editPriceError"></div>
                    </div>
                    <div class="form-group">
                        <label>NgÃ y báº¯t Ä‘áº§u <span class="required">*</span></label>
                        <input type="date" id="editStartDate" name="startDate" value="${membership.startDate.split('T')[0]}" required>
                        <div class="error" id="editStartDateError"></div>
                    </div>
                    <div class="form-group">
                        <label>NgÃ y káº¿t thÃºc <span class="required">*</span></label>
                        <input type="date" id="editEndDate" name="endDate" value="${membership.endDate.split('T')[0]}" required>
                        <div class="error" id="editEndDateError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Há»§y</button>
                        <button type="submit" class="btn btn-primary">Cáº­p Nháº­t</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Form submit handler
        const form = document.getElementById('editMembershipForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (!validateMembershipForm(true)) {
                return;
            }
            
            const formData = {
                packageName: document.getElementById('editPackageName').value.trim(),
                price: parseFloat(document.getElementById('editPrice').value),
                startDate: new Date(document.getElementById('editStartDate').value).toISOString(),
                endDate: new Date(document.getElementById('editEndDate').value + 'T23:59:59').toISOString()
            };
            
            try {
                showLoading();
                await apiFetch(`/api/Membership/${membershipId}`, {
                    method: 'PUT',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Cáº­p nháº­t gÃ³i táº­p thÃ nh cÃ´ng!');
                modal.remove();
                await loadMemberships();
            } catch (error) {
                hideLoading();
                showError('Lá»—i cáº­p nháº­t gÃ³i táº­p: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lá»—i táº£i thÃ´ng tin gÃ³i táº­p: ' + error.message);
    }
}

function validateMembershipForm(isEdit = false) {
    const prefix = isEdit ? 'edit' : '';
    const packageName = document.getElementById(prefix + 'packageName');
    const price = document.getElementById(prefix + 'price');
    const startDate = document.getElementById(prefix + 'startDate');
    const endDate = document.getElementById(prefix + 'endDate');
    
    let isValid = true;
    
    // Clear previous errors
    document.getElementById(prefix + 'packageNameError').textContent = '';
    document.getElementById(prefix + 'priceError').textContent = '';
    document.getElementById(prefix + 'startDateError').textContent = '';
    document.getElementById(prefix + 'endDateError').textContent = '';
    packageName.classList.remove('invalid');
    price.classList.remove('invalid');
    startDate.classList.remove('invalid');
    endDate.classList.remove('invalid');
    
    // Validate package name
    if (!packageName.value.trim()) {
        document.getElementById(prefix + 'packageNameError').textContent = 'Vui lÃ²ng nháº­p tÃªn gÃ³i';
        packageName.classList.add('invalid');
        isValid = false;
    }
    
    // Validate price
    const priceValue = parseFloat(price.value);
    if (!price.value || priceValue < 0) {
        document.getElementById(prefix + 'priceError').textContent = 'Vui lÃ²ng nháº­p giÃ¡ há»£p lá»‡';
        price.classList.add('invalid');
        isValid = false;
    }
    
    // Validate dates
    if (!startDate.value) {
        document.getElementById(prefix + 'startDateError').textContent = 'Vui lÃ²ng chá»n ngÃ y báº¯t Ä‘áº§u';
        startDate.classList.add('invalid');
        isValid = false;
    }
    
    if (!endDate.value) {
        document.getElementById(prefix + 'endDateError').textContent = 'Vui lÃ²ng chá»n ngÃ y káº¿t thÃºc';
        endDate.classList.add('invalid');
        isValid = false;
    }
    
    // Validate end date after start date
    if (startDate.value && endDate.value && new Date(endDate.value) <= new Date(startDate.value)) {
        document.getElementById(prefix + 'endDateError').textContent = 'NgÃ y káº¿t thÃºc pháº£i sau ngÃ y báº¯t Ä‘áº§u';
        endDate.classList.add('invalid');
        isValid = false;
    }
    
    // Validate member ID for create form
    if (!isEdit) {
        const memberId = document.getElementById('memberId');
        if (!memberId.value) {
            document.getElementById('memberIdError').textContent = 'Vui lÃ²ng chá»n thÃ nh viÃªn';
            memberId.classList.add('invalid');
            isValid = false;
        }
    }
    
    return isValid;
}

async function cancelMembership(membershipId) {
    // Show custom confirmation modal
    injectModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal">
            <h3>XÃ¡c Nháº­n Há»§y GÃ³i Táº­p</h3>
            <div class="warning-text">
                âš ï¸ GÃ³i táº­p sáº½ káº¿t thÃºc ngay hÃ´m nay. HÃ nh Ä‘á»™ng nÃ y khÃ´ng thá»ƒ hoÃ n tÃ¡c.
            </div>
            <div class="confirm-input-group">
                <label for="cancelConfirmInput">Nháº­p "XÃ¡c Nháº­n" Ä‘á»ƒ tiáº¿p tá»¥c:</label>
                <input type="text" id="cancelConfirmInput" placeholder='Nháº­p "XÃ¡c Nháº­n"'>
            </div>
            <div class="gym-modal-buttons">
                <button class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Há»§y Bá»</button>
                <button class="btn btn-danger" id="confirmCancelBtn" disabled onclick="executeCancelMembership(${membershipId}); this.closest('.gym-modal-overlay').remove();">Há»§y GÃ³i Táº­p</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Enable button only when exact text is entered
    const input = document.getElementById('cancelConfirmInput');
    const confirmBtn = document.getElementById('confirmCancelBtn');
    input.addEventListener('input', () => {
        confirmBtn.disabled = input.value !== 'XÃ¡c Nháº­n';
    });
    input.focus();
}

async function executeCancelMembership(membershipId) {
    try {
        showLoading();
        await apiFetch(`/api/Membership/${membershipId}/cancel`, { method: 'POST' });
        hideLoading();
        showToast('Há»§y gÃ³i táº­p thÃ nh cÃ´ng!', 'success');
        
        // Reload membership list
        const role = getRole();
        const memberId = getMemberId();
        const container = document.querySelector('.main-content');
        if (container) {
            await renderMemberships(container);
        } else {
            reloadCurrentPage();
        }
    } catch (err) {
        hideLoading();
        showToast('Lá»—i há»§y gÃ³i: ' + err.message, 'error');
    }
}

async function deleteMembership(membershipId) {
    if (!confirm('Bạn có chắc chắn muốn xóa gói tập này? Thao tác này không thể hoàn tác.')) {
        return;
    }
    try {
        showLoading();
        await apiFetch(`/api/Membership/${membershipId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa gói tập thành công!');
        await loadMemberships();
    } catch (error) {
        hideLoading();
        showError('Lỗi khi xóa gói tập: ' + error.message);
    }
}
