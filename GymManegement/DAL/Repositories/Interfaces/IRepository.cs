namespace GymManegement.DAL.Repositories.Interfaces
{
    /// <summary>Generic repository: CRUD cơ bản dùng chung cho tất cả entity</summary>
    public interface IRepository<T> where T : class
    {
        Task<IEnumerable<T>> GetAllAsync();
        Task<T?> GetByIdAsync(int id);
        Task<T> CreateAsync(T entity);
        Task<T> UpdateAsync(T entity);
        Task DeleteAsync(int id);
    }
}
