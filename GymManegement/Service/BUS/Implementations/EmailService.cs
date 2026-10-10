using System.Net;
using System.Net.Mail;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendOTPEmailAsync(string toEmail, string otpCode, string fullName)
        {
            var smtpHost = _config["Email:SmtpHost"] ?? "smtp.gmail.com";
            var smtpPort = _config.GetValue<int>("Email:SmtpPort", 587);
            var senderEmail = _config["Email:SenderEmail"];
            var senderPassword = _config["Email:SenderPassword"];
            var senderName = _config["Email:SenderName"] ?? "Gym Management System";

            if (string.IsNullOrEmpty(senderEmail) || string.IsNullOrEmpty(senderPassword))
            {
                // ponytail: email not configured, log OTP instead
                Console.WriteLine($"[EMAIL] OTP for {toEmail}: {otpCode}");
                return;
            }

            var mailMessage = new MailMessage
            {
                From = new MailAddress(senderEmail, senderName),
                Subject = "Xác nhận đăng ký tài khoản - Gym Management",
                Body = $@"
                    <html>
                    <body style='font-family: Arial, sans-serif;'>
                        <h2>Xin chào {fullName},</h2>
                        <p>Cảm ơn bạn đã đăng ký tài khoản tại Gym Management System.</p>
                        <p>Mã OTP xác nhận email của bạn là:</p>
                        <h1 style='color: #4CAF50; font-size: 32px; letter-spacing: 5px;'>{otpCode}</h1>
                        <p>Mã này có hiệu lực trong <strong>10 phút</strong>.</p>
                        <p>Nếu bạn không thực hiện đăng ký này, vui lòng bỏ qua email.</p>
                        <hr>
                        <p style='color: #888; font-size: 12px;'>Email tự động, vui lòng không trả lời.</p>
                    </body>
                    </html>",
                IsBodyHtml = true
            };
            mailMessage.To.Add(toEmail);

            using var smtpClient = new SmtpClient(smtpHost, smtpPort)
            {
                Credentials = new NetworkCredential(senderEmail, senderPassword),
                EnableSsl = true
            };

            await smtpClient.SendMailAsync(mailMessage);
        }
    }
}
