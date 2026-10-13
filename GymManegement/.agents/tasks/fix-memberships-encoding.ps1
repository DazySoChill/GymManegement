# Fix Vietnamese encoding in memberships.js
$filePath = "wwwroot/js/memberships.js"

# Define all replacements (mojibake -> correct UTF-8)
$replacements = @{
    'GÃ³i CÆ¡ Báº£n' = 'Gói Cơ Bản'
    'GÃ³i NÃ¢ng Cao' = 'Gói Nâng Cao'
    'GÃ³i VIP' = 'Gói VIP'
    'GÃ³i NÄƒm' = 'Gói Năm'
    '1 thÃ¡ng - Sá»­ dá»¥ng táº¥t cáº£ thiáº¿t bá»‹' = '1 tháng - Sử dụng tất cả thiết bị'
    '3 thÃ¡ng - Bao gá»"m 2 buá»•i PT/thÃ¡ng' = '3 tháng - Bao gồm 2 buổi PT/tháng'
    '6 thÃ¡ng - KhÃ´ng giá»›i háº¡n PT + dinh dÆ°á»¡ng' = '6 tháng - Không giới hạn PT + dinh dưỡng'
    '12 thÃ¡ng - Táº¥t cáº£ dá»‹ch vá»¥ cao cáº¥p' = '12 tháng - Tất cả dịch vụ cao cấp'
    'â±ï¸' = '⏱️'
    'ðŸ'³ Mua GÃ³i' = '💳 Mua Gói'
    'XÃ¡c Nháº­n Mua GÃ³i' = 'Xác Nhận Mua Gói'
    'GÃ³i:' = 'Gói:'
    'GiÃ¡:' = 'Giá:'
    'Thá»i háº¡n:' = 'Thời hạn:'
    'ngÃ y' = 'ngày'
    'NgÃ y báº¯t Ä'áº§u:' = 'Ngày bắt đầu:'
    'NgÃ y káº¿t thÃºc:' = 'Ngày kết thúc:'
    'Äang tÃ­nh toÃ¡n...' = 'Đang tính toán...'
    'Há»§y' = 'Hủy'
    'ðŸ'µ Tiá»n Máº·t' = '💵 Tiền Mặt'
    'ðŸ"± Thanh ToÃ¡n QR' = '📱 Thanh Toán QR'
    'QuÃ©t mÃ£ QR Ä'á»ƒ thanh toÃ¡n' = 'Quét mã QR để thanh toán'
    'âœ… XÃ¡c Nháº­n ÄÃ£ Thanh ToÃ¡n' = '✅ Xác Nhận Đã Thanh Toán'
    'Mua gÃ³i táº­p thÃ nh cÃ´ng!' = 'Mua gói tập thành công!'
    'ÄÃ£ xáº£y ra lá»—i há»‡ thá»'ng. Vui lÃ²ng thá»­ láº¡i sau.' = 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'
    'Báº¡n Ä'Ã£ cÃ³ gÃ³i táº­p Ä'ang hoáº¡t Ä'á»™ng. Vui lÃ²ng há»§y gÃ³i hiá»‡n táº¡i trÆ°á»›c khi mua gÃ³i má»›i.' = 'Bạn đã có gói tập đang hoạt động. Vui lòng hủy gói hiện tại trước khi mua gói mới.'
    'Lá»—i thanh toÃ¡n. Vui lÃ²ng thá»­ láº¡i sau.' = 'Lỗi thanh toán. Vui lòng thử lại sau.'
    'Lá»—i táº¡o gÃ³i táº­p. Vui lÃ²ng liÃªn há»‡ quáº£n trá»‹ viÃªn.' = 'Lỗi tạo gói tập. Vui lòng liên hệ quản trị viên.'
    'Lá»—i mua gÃ³i táº­p:' = 'Lỗi mua gói tập:'
    'GÃ³i Táº­p CÃ³ Sáºµn' = 'Gói Tập Có Sẵn'
    'GÃ³i Táº­p Cá»§a TÃ´i' = 'Gói Tập Của Tôi'
    'Báº¡n chÆ°a cÃ³ gÃ³i táº­p nÃ o' = 'Bạn chưa có gói tập nào'
    'ðŸŽ«' = '🎫'
    'GÃ³i' = 'Gói'
    'GiÃ¡' = 'Giá'
    'NgÃ y báº¯t Ä'áº§u' = 'Ngày bắt đầu'
    'NgÃ y káº¿t thÃºc' = 'Ngày kết thúc'
    'CÃ²n láº¡i' = 'Còn lại'
    'Thao tÃ¡c' = 'Thao tác'
    'âŒ Há»§y GÃ³i' = '❌ Hủy Gói'
    'ÄÃ£ háº¿t háº¡n' = 'Đã hết hạn'
    'Lá»—i táº£i gÃ³i táº­p:' = 'Lỗi tải gói tập:'
    'Quáº£n lÃ½ GÃ³i Táº­p' = 'Quản lý Gói Tập'
    'âž• ThÃªm gÃ³i táº­p' = '➕ Thêm gói tập'
    'TÃ¬m kiáº¿m...' = 'Tìm kiếm...'
    'ðŸ" TÃ¬m' = '🔍 Tìm'
    'Lá»—i táº£i danh sÃ¡ch gÃ³i táº­p:' = 'Lỗi tải danh sách gói tập:'
    'KhÃ´ng cÃ³ gÃ³i táº­p nÃ o' = 'Không có gói tập nào'
    'ThÃ nh viÃªn' = 'Thành viên'
    'âœï¸' = '✏️'
    'ðŸ—'ï¸ XÃ³a' = '🗑️ Xóa'
    'â€¹ TrÆ°á»›c' = '‹ Trước'
    'Trang' = 'Trang'
    'Sau â€º' = 'Sau ›'
    'âž• Táº¡o GÃ³i Táº­p Má»›i' = '➕ Tạo Gói Tập Mới'
    '-- Chá»n thÃ nh viÃªn --' = '-- Chọn thành viên --'
    'TÃªn gÃ³i' = 'Tên gói'
    'VD: GÃ³i CÆ¡ Báº£n, GÃ³i VIP' = 'VD: Gói Cơ Bản, Gói VIP'
    'Táº¡o GÃ³i' = 'Tạo Gói'
    'Táº¡o gÃ³i táº­p thÃ nh cÃ´ng!' = 'Tạo gói tập thành công!'
    'Lá»—i táº¡o gÃ³i táº­p:' = 'Lỗi tạo gói tập:'
    'Lá»—i táº£i danh sÃ¡ch thÃ nh viÃªn:' = 'Lỗi tải danh sách thành viên:'
    'âœï¸ Sá»­a GÃ³i Táº­p' = '✏️ Sửa Gói Tập'
    'KhÃ´ng tÃ¬m tháº¥y gÃ³i táº­p' = 'Không tìm thấy gói tập'
    'Cáº­p Nháº­t' = 'Cập Nhật'
    'Cáº­p nháº­t gÃ³i táº­p thÃ nh cÃ´ng!' = 'Cập nhật gói tập thành công!'
    'Lá»—i cáº­p nháº­t gÃ³i táº­p:' = 'Lỗi cập nhật gói tập:'
    'Lá»—i táº£i thÃ´ng tin gÃ³i táº­p:' = 'Lỗi tải thông tin gói tập:'
    'ðŸ—'ï¸' = '🗑️'
}

# Read the file content as raw bytes, then decode as UTF-8
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

Write-Output "Original file size: $($content.Length) characters"

# Apply all replacements
foreach ($key in $replacements.Keys) {
    $before = $content.Length
    $content = $content -replace [regex]::Escape($key), $replacements[$key]
    if ($content.Length -ne $before) {
        Write-Output "Replaced: '$key' -> '$($replacements[$key])'"
    }
}

Write-Output "After replacements: $($content.Length) characters"

# Write back with UTF-8 with BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($filePath, $content, $utf8WithBom)

Write-Output "`nFixed Vietnamese encoding in $filePath"
