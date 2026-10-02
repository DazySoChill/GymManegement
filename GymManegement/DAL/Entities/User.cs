namespace GymManegement.DAL.Entities
{
    public class User
    {
        public int    UserId       { get; set; }
        public string Username     { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string Role         { get; set; } = string.Empty; // SuperAdmin | Trainer | Member
        public int?   MemberId     { get; set; }
        public int?   TrainerId    { get; set; }
        public bool   IsActive     { get; set; }
        public DateTime CreatedAt  { get; set; }
    }
}
