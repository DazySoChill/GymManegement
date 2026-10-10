namespace GymManegement.API.DTOs.Common
{
    public class ExportRequest
    {
        public string Format { get; set; } = "excel"; // "excel" hoặc "pdf"
        public string? SearchTerm { get; set; }
        public Dictionary<string, string>? Filters { get; set; }
        public string? SortBy { get; set; }
        public string? SortDir { get; set; } // "asc" hoặc "desc"
        public List<string>? Columns { get; set; } // Các cột muốn xuất, null = tất cả
    }
}
