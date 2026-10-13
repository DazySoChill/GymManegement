# Vietnamese Text Standardization Plan

## Mục tiêu
Quét và sửa tất cả text trong admin JS files để:
1. Loại bỏ ký tự lỗi encoding
2. Chuẩn hóa tiếng Việt
3. Thống nhất terminology

## Files cần scan (17 files)
1. users.js
2. members.js
3. trainers.js
4. memberships.js
5. schedules.js
6. sessions.js
7. invoices.js
8. payments.js
9. checkins.js
10. facilities.js
11. dashboard.js
12. reports.js
13. member-schedule.js
14. profile.js
15. auth.js
16. api.js
17. app.js

## Common Issues Found

### 1. Mixed English/Vietnamese
- "Save" → "Lưu"
- "Cancel" → "Hủy"
- "Edit" → "Sửa"
- "Delete" → "Xóa"
- "Create" → "Tạo"
- "Add" → "Thêm"
- "View" → "Xem"
- "Loading..." → "Đang tải..."
- "Success" → "Thành công"
- "Error" → "Lỗi"

### 2. Terminology Consistency
- Member → "Thành viên" (consistent)
- Trainer → "Huấn luyện viên" or "HLV"
- Membership → "Gói tập"
- Invoice → "Hóa đơn"
- Payment → "Thanh toán"
- Check-in → "Check-in" (keep as is)
- Facility → "Cơ sở vật chất"
- Schedule → "Lịch tập"
- Session → "Buổi tập"

### 3. Status Labels
- Active → "Hoạt động"
- Inactive → "Không hoạt động"
- Pending → "Chờ xử lý"
- Completed → "Hoàn thành"
- Paid → "Đã thanh toán"
- Unpaid → "Chưa thanh toán"

## Priority Areas
1. Button labels
2. Modal titles
3. Form labels
4. Error/success messages
5. Table headers
6. Empty state messages
7. Confirmation dialogs

## Implementation
Will create separate fix for each file to avoid conflicts.
