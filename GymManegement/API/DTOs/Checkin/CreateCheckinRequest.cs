namespace GymManegement.API.DTOs.Checkin
{
    public class CreateCheckinRequest
    {
        public int MemberId { get; set; }
        public int SessionId { get; set; }
        public DateTime CheckinTime { get; set; } = DateTime.UtcNow;
        /// <summary>Manual | QRCode | Card</summary>
        public string CheckinMethod { get; set; } = "Manual";
    }
}
