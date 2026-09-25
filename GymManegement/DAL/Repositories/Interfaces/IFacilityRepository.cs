using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IFacilityRepository : IRepository<Facility>
    {
        Task<IEnumerable<Facility>> GetActiveAsync();
    }
}
