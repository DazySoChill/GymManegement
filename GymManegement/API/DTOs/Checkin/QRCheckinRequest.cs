namespace GymManegement.API.DTOs.Checkin
{
    /// <summary>Dùng khi check-in bằng QR Code scan</summary>
    public class QRCheckinRequest
    {
        public string QRCodeValue { get; set; } = string.Empty;
        public int SessionId { get; set; }
    }
}
