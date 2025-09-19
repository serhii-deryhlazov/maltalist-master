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
            "This is a longer description that provides more information about the product, its condition, features, and any other relevant details that a buyer might want to know before making a purchase. It includes multiple sentences to give a comprehensive overview.",
            "I'm selling this because I'm moving abroad next month and can't take everything with me. It's been well maintained and I've always kept it in good condition. Originally bought it for much more but need to sell quickly. The item works perfectly, no issues at all. I've taken good care of it and it shows. Would prefer if buyer can pick up this week as I'm quite busy with packing. Cash only please, and serious buyers only. You won't find a better deal anywhere else, I've checked the prices online. Feel free to message me if you have any questions, I usually respond quite fast. Really need this gone soon so willing to negotiate a bit on the price for quick sale.",
            "Honestly, I hate to sell this but we desperately need the space and money right now. My wife has been nagging me to get rid of it for months and I finally gave in. This thing has served us really well over the years, never had any major problems with it. I remember when I first got it, I was so excited and used it all the time. But life changes and priorities shift, you know how it is. The kids are grown up now and we just don't need it anymore. It's taking up valuable space in our garage and my wife wants to park her car there instead. I've been putting off selling it but she gave me an ultimatum last week. It still works like a charm, maybe needs a bit of cleaning but that's about it. I've seen similar items selling for way more online but I just want it gone without the hassle of dealing with time wasters. If you're genuinely interested and can come pick it up this weekend, we can work something out. I'm usually home in the evenings after 6pm or weekends. Just give me a call or text, don't really check emails that often. Really hoping to find someone who will appreciate it as much as I did.",
            "Listen, I'm only selling this because my business is struggling and I need the cash urgently. Bills are piling up and the bank is breathing down my neck. This has been sitting in my workshop for the past year and I keep telling myself I'll use it again but let's be honest, I probably won't. When times were good I bought all sorts of equipment and tools, thinking I'd expand the business. Well, that didn't work out as planned and now I'm stuck with all this stuff I can't afford to keep. My accountant told me to liquidate whatever I can to keep the business afloat. It breaks my heart to let it go because I know its true value, but desperate times call for desperate measures. The condition is excellent, barely used actually. I'm meticulous about maintaining my equipment so you know it's been looked after properly. I've got all the original documentation and accessories that came with it. Price is firm because I already calculated the minimum I need to get from it. No lowballers please, I know what it's worth and I'm already selling below market value. If you're serious about buying, bring cash and we can close the deal immediately. I'm available most days during business hours, just call ahead to make sure I'm at the workshop. Really need to move this quickly before the end of the month.",
            "OK so this is going to sound like a really long story but I need to explain why I'm selling this and why it means so much to me, and hopefully you'll understand why I'm being so picky about who buys it. This belonged to my grandfather who passed away last year, and it's been in our family for over 30 years. He bought it brand new back in the day when he was starting his own little business from his garage. I remember being a kid and watching him work with it every weekend, he was so proud of that thing and always kept it spotless. When he got older and couldn't work anymore, it just sat there in his shed gathering dust, but he refused to sell it because he said one day someone in the family would need it. Well, that someone turned out to be me when I decided to follow in his footsteps and start my own project. For the past five years I've been using it regularly and it brought back so many memories of him every time. The thing is built like a tank, they just don't make them like this anymore. Everything nowadays is cheap plastic junk that breaks after a year, but this is solid metal and will outlast us all. I've maintained it exactly the way he taught me, checking all the moving parts, keeping it oiled and clean, storing it properly when not in use. It's never let me down once, starts up first time every time, runs smooth as butter. The only reason I'm selling it now is because my wife and I are getting divorced and we need to split everything. She doesn't understand the sentimental value and just sees it as another thing taking up space. The lawyers said everything has to go and we need to liquidate assets to divide them fairly. It's breaking my heart to let it go but I don't have much choice in the matter. I've been putting this off for months hoping we could work things out, but the divorce is final next month and I can't delay anymore. I've looked up similar models online and they're going for way more than what I'm asking, especially in this condition. Some of them are beat up and rusty, missing parts, or clearly haven't been maintained properly. Mine still has all the original accessories, the manual, even the warranty card from 1993. I'm not looking to make a profit here, I just want to make sure it goes to someone who will actually use it and take care of it the way it deserves. I've already had a bunch of people come look at it who clearly just wanted to flip it for a quick profit, and I sent them all away. One guy even had the nerve to offer me half my asking price saying it was 'old junk'. That really ticked me off because this is far from junk, it's a classic piece of equipment that's probably worth more now than when it was new. I work from home most days so viewing is pretty flexible, but please don't waste my time if you're not serious. I'd prefer to sell it to someone who actually knows what they're looking at and can appreciate the quality. If you're just starting out and this is your first purchase, that's fine too, we all have to start somewhere. I'm happy to show you how everything works and even throw in some tips that my grandfather taught me. The price is what it is because I've already calculated the minimum I need to get from it to satisfy the divorce settlement. I wish I could keep it but life has other plans sometimes. Really hoping to find the right buyer who will give it the respect it deserves."
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
