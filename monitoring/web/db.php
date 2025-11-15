<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Database Stats</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <h1>Database Stats</h1>
    <a href="index.php">Back to Monitoring</a>
    <br><br>

    <?php
    $servername = "db";
    $username = "maltalist_user";
    $password = "M@LtApass";
    $dbname = "maltalist";

    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    // Total users
    $sql = "SELECT COUNT(*) as total FROM Users";
    $result = $conn->query($sql);
    $totalUsers = $result->fetch_assoc()['total'];

    // Total listings
    $sql = "SELECT COUNT(*) as total FROM Listings";
    $result = $conn->query($sql);
    $totalListings = $result->fetch_assoc()['total'];

    // Listings added today
    $sql = "SELECT id, title, Approved FROM Listings WHERE DATE(createdAt) = CURDATE()";
    $result = $conn->query($sql);
    $listingsToday = [];
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $listingsToday[] = $row;
        }
    }

    // Handle approve action
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['approve_listing'])) {
        $listingId = intval($_POST['listing_id']);
        $approvedValue = isset($_POST['approved']) ? 1 : 0;
        
        $conn = new mysqli($servername, $username, $password, $dbname);
        $stmt = $conn->prepare("UPDATE Listings SET Approved = ? WHERE id = ?");
        $stmt->bind_param("ii", $approvedValue, $listingId);
        $stmt->execute();
        $stmt->close();
        $conn->close();
        
        // Redirect to refresh the page
        header("Location: " . $_SERVER['PHP_SELF']);
        exit();
    }

    $conn->close();
    ?>

    <p><strong>Total Users:</strong> <?php echo $totalUsers; ?></p>
    <p><strong>Total Listings:</strong> <?php echo $totalListings; ?></p>

    <h2>Listings Added Today</h2>
    <?php if (count($listingsToday) > 0): ?>
        <table>
            <thead>
                <tr>
                    <th>Title</th>
                    <th>Link</th>
                    <th>Approved</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($listingsToday as $listing): ?>
                    <tr>
                        <td><?php echo htmlspecialchars($listing['title']); ?></td>
                        <td><a href="http://localhost/listing/<?php echo $listing['id']; ?>" target="_blank">View Listing</a></td>
                        <td>
                            <form method="POST" style="display: inline;">
                                <input type="hidden" name="listing_id" value="<?php echo $listing['id']; ?>">
                                <input type="hidden" name="approve_listing" value="1">
                                <input type="checkbox" 
                                       name="approved" 
                                       value="1" 
                                       <?php echo $listing['Approved'] ? 'checked' : ''; ?>
                                       onchange="this.form.submit()">
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php else: ?>
        <p>No listings added today.</p>
    <?php endif; ?>
</body>
</html>
