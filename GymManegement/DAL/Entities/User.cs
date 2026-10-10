namespace GymManegement.DAL.Entities
{
    public class User
    {
        public int       UserId       { get; set; }
        public string    Username     { get; set; } = string.Empty;
        public string    PasswordHash { get; set; } = string.Empty;
        public string    FullName     { get; set; } = string.Empty;
        public string    Email        { get; set; } = string.Empty;
        public string    Role         { get; set; } = string.Empty; // "Admin", "Trainer", or "Member"
        public bool      IsActive     { get; set; } = true;
        public DateTime? LastLoginAt  { get; set; }
        public DateTime  CreatedAt    { get; set; }
        public DateTime? UpdatedAt    { get; set; }
        public bool      IsDeleted    { get; set; }
        public DateTime? DeletedAt    { get; set; }
    }
}
