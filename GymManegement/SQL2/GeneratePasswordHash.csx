#!/usr/bin/env dotnet-script
#r "nuget: BCrypt.Net-Next, 4.0.3"

using BCrypt.Net;

// Generate BCrypt hash for password: gym@2026
string password = "gym@2026";
string hash = BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);

Console.WriteLine("Password: " + password);
Console.WriteLine("BCrypt Hash: " + hash);
Console.WriteLine();
Console.WriteLine("Verification: " + BCrypt.Net.BCrypt.Verify(password, hash));
