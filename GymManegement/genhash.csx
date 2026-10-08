using BCrypt.Net.BCrypt;

var hash = HashPassword("gym@2026", 11);
Console.WriteLine(hash);
