namespace GymManegement.API.DTOs.Session
{
    public class UpdateSessionRequest
    {
        /// <summary>Scheduled | Completed | Cancelled</summary>
        public string Status { get; set; } = string.Empty;
    }
}
