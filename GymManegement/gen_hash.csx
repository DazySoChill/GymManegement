using BCrypt.Net;
var hash = BCrypt.Net.BCrypt.HashPassword("gym@2026", workFactor: 11);
Console.WriteLine(hash);
