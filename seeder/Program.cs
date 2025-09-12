using System;
using System.Text;
using MySqlConnector;

class Program
{
    static void Main(string[] args)
    {
        if (args.Length != 1 || !int.TryParse(args[0], out int count) || count <= 0 || count > 1000)
        {
            Console.WriteLine("Usage: dotnet run <count>");
            Console.WriteLine("Count must be a positive integer between 1 and 1000");
            return;
        }

        SeedDatabase(count);
    }

    static void SeedDatabase(int count)
    {
        string connectionString = "Server=localhost;Database=maltalist;User=maltalist_user;Password=M@LtApass;";

        var locations = new[]
        {
            "Valletta", "Sliema", "St. Julian's", "Birkirkara", "Mosta", "Qormi", "Zebbug", "Attard", "Balzan", "Birzebbuga",
            "Fgura", "Floriana", "Gzira", "Hamrun", "Marsaskala", "Marsaxlokk", "Mdina", "Mellieha", "Msida", "Naxxar",
            "Paola", "Pembroke", "Rabat", "San Gwann", "Santa Venera", "Siggiewi", "Swieqi", "Tarxien", "Vittoriosa",
            "Xghajra", "Zabbar", "Zejtun", "Zurrieq", "Gozo - Victoria", "Gozo - Xewkija", "Gozo - Nadur", "Gozo - Qala",
            "Gozo - Ghajnsielem", "Gozo - Xaghra", "Gozo - Sannat", "Gozo - Munxar", "Gozo - Fontana", "Gozo - Gharb",
            "Gozo - San Lawrenz", "Gozo - Zebbug"
        };
        var categories = new[] { "Electronics", "Furniture", "Clothing", "Vehicles", "Real Estate", "Sports&Hobby", "Books", "Other" };
        var titles = new[]
        {
            "Brand New Laptop", "Used Bicycle", "Vintage Watch", "Gaming Console", "Smartphone", "Bookshelf", "Dining Table",
            "Winter Jacket", "Mountain Bike", "Apartment for Rent", "Collectible Coins", "Musical Instrument", "Office Chair",
            "Garden Tools", "Antique Vase", "Fitness Equipment", "Car Tires", "Jewelry Set", "Board Games", "Camping Gear"
        };
        var descriptions = new[]
        {
            "Short description.",
            "This is a medium length description with some details about the item.",
            "This is a longer description that provides more information about the product, its condition, features, and any other relevant details that a buyer might want to know before making a purchase. It includes multiple sentences to give a comprehensive overview."
        };

        var random = new Random();
        int usersNeeded = (int)Math.Ceiling((double)count / 10);

        using (var conn = new MySqlConnection(connectionString))
        {
            conn.Open();

            for (int i = 0; i < usersNeeded; i++)
            {
                string userId = GenerateRandom18DigitString(random);
                string userName = "User" + userId.Substring(0, 5);
                string email = $"user{userId}@example.com";
                string phoneNumber = random.Next(2) == 0 ? $"+356{random.Next(10000000, 99999999)}" : null;
                DateTime now = DateTime.UtcNow;

                string insertUser = @"INSERT INTO Users (Id, UserName, PhoneNumber, UserPicture, Email, CreatedAt, LastOnline) 
                                      VALUES (@Id, @UserName, @PhoneNumber, @UserPicture, @Email, @CreatedAt, @LastOnline)";
                using (var cmd = new MySqlCommand(insertUser, conn))
                {
                    cmd.Parameters.AddWithValue("@Id", userId);
                    cmd.Parameters.AddWithValue("@UserName", userName);
                    cmd.Parameters.AddWithValue("@PhoneNumber", phoneNumber);
                    cmd.Parameters.AddWithValue("@UserPicture", "");
                    cmd.Parameters.AddWithValue("@Email", email);
                    cmd.Parameters.AddWithValue("@CreatedAt", now);
                    cmd.Parameters.AddWithValue("@LastOnline", now);
                    cmd.ExecuteNonQuery();
                }

                int listingsForUser = Math.Min(10, count - i * 10);
                for (int j = 0; j < listingsForUser; j++)
                {
                    string title = titles[random.Next(titles.Length)];
                    string description = descriptions[random.Next(descriptions.Length)];
                    decimal price = random.Next(1, 10001);
                    string category = categories[random.Next(categories.Length)];
                    string location = locations[random.Next(locations.Length)];

                    string insertListing = @"INSERT INTO Listings (Title, Description, Price, Category, Location, UserId, CreatedAt, UpdatedAt) 
                                             VALUES (@Title, @Description, @Price, @Category, @Location, @UserId, @CreatedAt, @UpdatedAt)";
                    using (var cmd = new MySqlCommand(insertListing, conn))
                    {
                        cmd.Parameters.AddWithValue("@Title", title);
                        cmd.Parameters.AddWithValue("@Description", description);
                        cmd.Parameters.AddWithValue("@Price", price);
                        cmd.Parameters.AddWithValue("@Category", category);
                        cmd.Parameters.AddWithValue("@Location", location);
                        cmd.Parameters.AddWithValue("@UserId", userId);
                        cmd.Parameters.AddWithValue("@CreatedAt", now);
                        cmd.Parameters.AddWithValue("@UpdatedAt", now);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
        }

        Console.WriteLine($"Seeded {count} listings across {usersNeeded} users.");
    }

    static string GenerateRandom18DigitString(Random random)
    {
        var sb = new StringBuilder(18);
        for (int i = 0; i < 18; i++)
        {
            sb.Append(random.Next(0, 10));
        }
        return sb.ToString();
    }
}
