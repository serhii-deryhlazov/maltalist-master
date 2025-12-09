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
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .tabs {
            display: flex;
            gap: 10px;
            margin: 20px 0;
            border-bottom: 2px solid #ddd;
        }
        .tab {
            padding: 10px 20px;
            cursor: pointer;
            background-color: #f0f0f0;
            border: 1px solid #ddd;
            border-bottom: none;
            text-decoration: none;
            color: #333;
        }
        .tab:hover {
            background-color: #e0e0e0;
        }
        .tab.active {
            background-color: #fff;
            border-bottom: 2px solid #fff;
            margin-bottom: -2px;
            font-weight: bold;
        }
        .pagination {
            margin: 20px 0;
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .pagination a, .pagination span {
            padding: 5px 10px;
            border: 1px solid #ddd;
            text-decoration: none;
            color: #333;
        }
        .pagination a:hover {
            background-color: #f0f0f0;
        }
        .pagination .current {
            background-color: #007bff;
            color: white;
            border-color: #007bff;
        }
        .stats {
            display: flex;
            gap: 20px;
            margin: 20px 0;
        }
        .stat-box {
            padding: 15px;
            background-color: #f8f9fa;
            border: 1px solid #ddd;
            border-radius: 5px;
        }
        .stat-box strong {
            display: block;
            font-size: 24px;
            color: #007bff;
        }
    </style>
</head>
<body>
    <h1>Database Stats</h1>
    <a href="index.php">Back to Monitoring</a>

    <?php
    $servername = "db";
    $username = "maltalist_user";
    $password = getenv('MYSQL_PASSWORD') ?: "M@LtApass";
    $dbname = "maltalist";

    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    // Handle approve action
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['approve_listing'])) {
        $listingId = intval($_POST['listing_id']);
        $approvedValue = isset($_POST['approved']) ? 1 : 0;
        
        $stmt = $conn->prepare("UPDATE Listings SET Approved = ? WHERE id = ?");
        $stmt->bind_param("ii", $approvedValue, $listingId);
        $stmt->execute();
        $stmt->close();
        
        // Redirect to refresh the page
        header("Location: " . $_SERVER['PHP_SELF'] . "?view=" . ($_GET['view'] ?? 'unapproved') . "&page=" . ($_GET['page'] ?? 1));
        exit();
    }

    // Get current view and page
    $view = $_GET['view'] ?? 'unapproved';
    $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
    $perPage = 20;
    $offset = ($page - 1) * $perPage;

    // Total users
    $sql = "SELECT COUNT(*) as total FROM Users";
    $result = $conn->query($sql);
    $totalUsers = $result->fetch_assoc()['total'];

    // Total listings
    $sql = "SELECT COUNT(*) as total FROM Listings";
    $result = $conn->query($sql);
    $totalListings = $result->fetch_assoc()['total'];

    // Approved listings
    $sql = "SELECT COUNT(*) as total FROM Listings WHERE Approved = 1";
    $result = $conn->query($sql);
    $approvedListings = $result->fetch_assoc()['total'];

    // Unapproved listings
    $sql = "SELECT COUNT(*) as total FROM Listings WHERE Approved = 0";
    $result = $conn->query($sql);
    $unapprovedListings = $result->fetch_assoc()['total'];

    // Get listings based on view
    $listings = [];
    $totalCount = 0;

    if ($view === 'unapproved') {
        // Count total unapproved
        $sql = "SELECT COUNT(*) as total FROM Listings WHERE Approved = 0";
        $result = $conn->query($sql);
        $totalCount = $result->fetch_assoc()['total'];

        // Get paginated unapproved listings
        $sql = "SELECT id, title, Approved, createdAt FROM Listings WHERE Approved = 0 ORDER BY createdAt DESC LIMIT ? OFFSET ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $perPage, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        while($row = $result->fetch_assoc()) {
            $listings[] = $row;
        }
        $stmt->close();
    } elseif ($view === 'today') {
        // Count today's listings
        $sql = "SELECT COUNT(*) as total FROM Listings WHERE DATE(createdAt) = CURDATE()";
        $result = $conn->query($sql);
        $totalCount = $result->fetch_assoc()['total'];

        // Get today's listings
        $sql = "SELECT id, title, Approved, createdAt FROM Listings WHERE DATE(createdAt) = CURDATE() ORDER BY createdAt DESC LIMIT ? OFFSET ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $perPage, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        while($row = $result->fetch_assoc()) {
            $listings[] = $row;
        }
        $stmt->close();
    } else { // all
        // Count all listings
        $totalCount = $totalListings;

        // Get all listings
        $sql = "SELECT id, title, Approved, createdAt FROM Listings ORDER BY createdAt DESC LIMIT ? OFFSET ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $perPage, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        while($row = $result->fetch_assoc()) {
            $listings[] = $row;
        }
        $stmt->close();
    }

    $totalPages = ceil($totalCount / $perPage);

    $conn->close();
    ?>

    <div class="stats">
        <div class="stat-box">
            <strong><?php echo $totalUsers; ?></strong>
            <span>Total Users</span>
        </div>
        <div class="stat-box">
            <strong><?php echo $totalListings; ?></strong>
            <span>Total Listings</span>
        </div>
        <div class="stat-box">
            <strong><?php echo $approvedListings; ?></strong>
            <span>Approved</span>
        </div>
        <div class="stat-box">
            <strong><?php echo $unapprovedListings; ?></strong>
            <span>Unapproved</span>
        </div>
    </div>

    <div class="tabs">
        <a href="?view=unapproved&page=1" class="tab <?php echo $view === 'unapproved' ? 'active' : ''; ?>">
            Unapproved (<?php echo $unapprovedListings; ?>)
        </a>
        <a href="?view=today&page=1" class="tab <?php echo $view === 'today' ? 'active' : ''; ?>">
            Today's Listings
        </a>
        <a href="?view=all&page=1" class="tab <?php echo $view === 'all' ? 'active' : ''; ?>">
            All Listings
        </a>
    </div>

    <?php if (count($listings) > 0): ?>
        <div class="pagination">
            <?php if ($page > 1): ?>
                <a href="?view=<?php echo $view; ?>&page=<?php echo $page - 1; ?>">« Previous</a>
            <?php endif; ?>
            
            <span>Page <?php echo $page; ?> of <?php echo $totalPages; ?></span>
            <span>(<?php echo $totalCount; ?> total)</span>
            
            <?php if ($page < $totalPages): ?>
                <a href="?view=<?php echo $view; ?>&page=<?php echo $page + 1; ?>">Next »</a>
            <?php endif; ?>
        </div>

        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Title</th>
                    <th>Created At</th>
                    <th>Link</th>
                    <th>Approved</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($listings as $listing): ?>
                    <tr>
                        <td><?php echo $listing['id']; ?></td>
                        <td><?php echo htmlspecialchars($listing['title']); ?></td>
                        <td><?php echo date('Y-m-d H:i:s', strtotime($listing['createdAt'])); ?></td>
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

        <div class="pagination">
            <?php if ($page > 1): ?>
                <a href="?view=<?php echo $view; ?>&page=<?php echo $page - 1; ?>">« Previous</a>
            <?php endif; ?>
            
            <span>Page <?php echo $page; ?> of <?php echo $totalPages; ?></span>
            
            <?php if ($page < $totalPages): ?>
                <a href="?view=<?php echo $view; ?>&page=<?php echo $page + 1; ?>">Next »</a>
            <?php endif; ?>
        </div>
    <?php else: ?>
        <p>No listings found for this view.</p>
    <?php endif; ?>
</body>
</html>
