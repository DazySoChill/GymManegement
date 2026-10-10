namespace GymManegement.Service.BUS.Interfaces
{
    public interface IEmailService
    {
        Task SendOTPEmailAsync(string toEmail, string otpCode, string fullName);
    }
}
