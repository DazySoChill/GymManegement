namespace GymManegement.API.DTOs.Checkin
{
    /// <summary>Dùng khi check-in bằng QR Code scan</summary>
    public class QRCheckinRequest
    {
        public string QRCode { get; set; } = string.Empty;
    }
}
