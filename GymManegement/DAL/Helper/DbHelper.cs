using GymManegement.DAL.DbContext;

namespace Gym.DAL.Helper
{
    public class DbHelper
    {

        private readonly GymDbContext _context;

        public DbHelper(GymDbContext context)
        {
            _context = context;
        }

        public GymDbContext Context => _context;

        public async Task SaveAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}
