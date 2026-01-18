<?php
require_once 'db.php';

// Handle POST actions (update status, delete)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json');
    
    if (isset($_POST['action'])) {
        if ($_POST['action'] === 'update-status') {
            $id = $_POST['id'] ?? null;
            $status = $_POST['status'] ?? null;
            $reviewNotes = $_POST['reviewNotes'] ?? '';
            
            if (!$id || !$status) {
                echo json_encode(['success' => false, 'error' => 'Missing required fields']);
                exit;
            }
            
            try {
                $query = "UPDATE Reports SET Status = ?, ReviewedAt = NOW(), ReviewNotes = ? WHERE Id = ?";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("ssi", $status, $reviewNotes, $id);
                $stmt->execute();
                
                if ($stmt->affected_rows > 0 || $conn->affected_rows === 0) {
                    echo json_encode(['success' => true]);
                } else {
                    echo json_encode(['success' => false, 'error' => 'Report not found']);
                }
                $stmt->close();
            } catch (Exception $e) {
                echo json_encode(['success' => false, 'error' => $e->getMessage()]);
            }
            exit;
        }
        
        if ($_POST['action'] === 'delete') {
            $id = $_POST['id'] ?? null;
            
            if (!$id) {
                echo json_encode(['success' => false, 'error' => 'Missing report ID']);
                exit;
            }
            
            try {
                $query = "DELETE FROM Reports WHERE Id = ?";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("i", $id);
                $stmt->execute();
                
                if ($stmt->affected_rows > 0) {
                    echo json_encode(['success' => true]);
                } else {
                    echo json_encode(['success' => false, 'error' => 'Report not found']);
                }
                $stmt->close();
            } catch (Exception $e) {
                echo json_encode(['success' => false, 'error' => $e->getMessage()]);
            }
            exit;
        }
    }
}

// Fetch all reports from database
$statusFilter = $_GET['status'] ?? '';
try {
    $query = "SELECT r.*, l.Title as ListingTitle 
              FROM Reports r 
              LEFT JOIN Listings l ON r.ListingId = l.Id";
    
    if ($statusFilter) {
        $query .= " WHERE r.Status = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $statusFilter);
    } else {
        $stmt = $conn->prepare($query);
    }
    
    $query .= " ORDER BY r.CreatedAt DESC";
    $stmt = $conn->prepare($query);
    if ($statusFilter) {
        $stmt->bind_param("s", $statusFilter);
    }
    $stmt->execute();
    $result = $stmt->get_result();
    $reports = [];
    
    while ($row = $result->fetch_assoc()) {
        $reports[] = $row;
    }
    $stmt->close();
} catch (Exception $e) {
    $reports = [];
    $error = $e->getMessage();
}

// Calculate statistics
$stats = [
    'pending' => 0,
    'reviewed' => 0,
    'resolved' => 0,
    'dismissed' => 0
];
foreach ($reports as $report) {
    if (isset($stats[$report['Status']])) {
        $stats[$report['Status']]++;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Content Reports - MaltaListing Monitoring</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            padding: 30px;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
        }
        h1 {
            color: #333;
            font-size: 28px;
        }
        .nav-links {
            display: flex;
            gap: 15px;
        }
        .nav-links a {
            padding: 10px 20px;
            background: #034d88;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.2s;
        }
        .nav-links a:hover {
            background: #023a66;
        }
        .filters {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            align-items: center;
        }
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .filter-group label {
            font-size: 12px;
            color: #666;
            font-weight: 600;
        }
        select, button {
            padding: 10px 15px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            cursor: pointer;
        }
        select {
            background: white;
        }
        button {
            background: #034d88;
            color: white;
            border: none;
            transition: background 0.2s;
        }
        button:hover {
            background: #023a66;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 25px;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .stat-card.pending { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .stat-card.reviewed { background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); }
        .stat-card.resolved { background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); }
        .stat-card.dismissed { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .stat-label {
            font-size: 14px;
            opacity: 0.9;
        }
        .reports-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .reports-table th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #dee2e6;
        }
        .reports-table td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
        }
        .reports-table tr:hover {
            background: #f8f9fa;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .status-pending { background: #fee; color: #c00; }
        .status-reviewed { background: #e3f2fd; color: #1976d2; }
        .status-resolved { background: #e8f5e9; color: #2e7d32; }
        .status-dismissed { background: #f3e5f5; color: #7b1fa2; }
        .actions {
            display: flex;
            gap: 8px;
        }
        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
            border-radius: 4px;
        }
        .btn-view {
            background: #034d88;
            color: white;
            border: none;
        }
        .btn-delete {
            background: #dc3545;
            color: white;
            border: none;
        }
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }
        .modal.active {
            display: flex;
        }
        .modal-content {
            background: white;
            padding: 30px;
            border-radius: 8px;
            max-width: 600px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
        }
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid #dee2e6;
        }
        .modal-close {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #666;
            padding: 0;
            width: 30px;
            height: 30px;
        }
        .detail-row {
            margin-bottom: 15px;
        }
        .detail-label {
            font-weight: 600;
            color: #666;
            font-size: 12px;
            text-transform: uppercase;
            margin-bottom: 5px;
        }
        .detail-value {
            color: #333;
            font-size: 14px;
        }
        textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-family: inherit;
            font-size: 14px;
            resize: vertical;
        }
        .no-reports {
            text-align: center;
            padding: 60px 20px;
            color: #666;
        }
        .loading {
            text-align: center;
            padding: 40px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📋 Content Reports</h1>
            <div class="nav-links">
                <a href="index.php">← Back to Monitoring</a>
                <a href="db.php">Manage DB</a>
            </div>
        </div>

        <div class="stats" id="stats">
            <div class="stat-card pending">
                <div class="stat-value"><?php echo $stats['pending']; ?></div>
                <div class="stat-label">Pending</div>
            </div>
            <div class="stat-card reviewed">
                <div class="stat-value"><?php echo $stats['reviewed']; ?></div>
                <div class="stat-label">Reviewed</div>
            </div>
            <div class="stat-card resolved">
                <div class="stat-value"><?php echo $stats['resolved']; ?></div>
                <div class="stat-label">Resolved</div>
            </div>
            <div class="stat-card dismissed">
                <div class="stat-value"><?php echo $stats['dismissed']; ?></div>
                <div class="stat-label">Dismissed</div>
            </div>
        </div>

        <div class="filters">
            <div class="filter-group">
                <label>Filter by Status</label>
                <select id="status-filter" onchange="filterReports()">
                    <option value="">All Reports</option>
                    <option value="pending" <?php echo $statusFilter === 'pending' ? 'selected' : ''; ?>>Pending</option>
                    <option value="reviewed" <?php echo $statusFilter === 'reviewed' ? 'selected' : ''; ?>>Reviewed</option>
                    <option value="resolved" <?php echo $statusFilter === 'resolved' ? 'selected' : ''; ?>>Resolved</option>
                    <option value="dismissed" <?php echo $statusFilter === 'dismissed' ? 'selected' : ''; ?>>Dismissed</option>
                </select>
            </div>
            <div class="filter-group">
                <label>&nbsp;</label>
                <button onclick="location.reload()">🔄 Refresh</button>
            </div>
        </div>

        <div id="reports-container">
            <?php if (isset($error)): ?>
                <div class="no-reports">❌ Error loading reports: <?php echo htmlspecialchars($error); ?></div>
            <?php elseif (count($reports) === 0): ?>
                <div class="no-reports">✅ No reports found</div>
            <?php else: ?>
                <table class="reports-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Listing</th>
                            <th>Reason</th>
                            <th>Reporter</th>
                            <th>Status</th>
                            <th>Created</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($reports as $report): ?>
                        <tr>
                            <td>#<?php echo $report['Id']; ?></td>
                            <td>
                                <a href="/listing/<?php echo $report['ListingId']; ?>" target="_blank" style="color: #034d88;">
                                    <?php echo htmlspecialchars($report['ListingTitle'] ?? 'N/A'); ?>
                                </a>
                            </td>
                            <td><?php echo htmlspecialchars($report['Reason']); ?></td>
                            <td><?php echo htmlspecialchars($report['ReporterEmail'] ?? $report['ReporterName'] ?? 'Anonymous'); ?></td>
                            <td><span class="status-badge status-<?php echo $report['Status']; ?>"><?php echo $report['Status']; ?></span></td>
                            <td><?php echo date('M d, Y H:i', strtotime($report['CreatedAt'])); ?></td>
                            <td>
                                <div class="actions">
                                    <button class="btn-sm btn-view" onclick='viewReport(<?php echo json_encode($report); ?>)'>View</button>
                                    <button class="btn-sm btn-delete" onclick="deleteReport(<?php echo $report['Id']; ?>)">Delete</button>
                                </div>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>
        </div>
    </div>

    <!-- Report Detail Modal -->
    <div class="modal" id="report-modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>Report Details</h2>
                <button class="modal-close" onclick="closeModal()">×</button>
            </div>
            <div id="modal-body"></div>
        </div>
    </div>

    <script>
        let currentReport = null;

        function filterReports() {
            const status = document.getElementById('status-filter').value;
            window.location.href = 'reports.php' + (status ? '?status=' + status : '');
        }

        function viewReport(report) {
            currentReport = report;
            const modalBody = document.getElementById('modal-body');
            const reviewedAt = report.ReviewedAt ? new Date(report.ReviewedAt).toLocaleString() : '';
            
            modalBody.innerHTML = `
                <div class="detail-row">
                    <div class="detail-label">Report ID</div>
                    <div class="detail-value">#${report.Id}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Listing</div>
                    <div class="detail-value">
                        <a href="/listing/${report.ListingId}" target="_blank" style="color: #034d88;">
                            ${report.ListingTitle || 'Listing #' + report.ListingId}
                        </a>
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Reporter Name</div>
                    <div class="detail-value">${report.ReporterName || 'Anonymous'}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Reporter Email</div>
                    <div class="detail-value">${report.ReporterEmail || 'Not provided'}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Reason</div>
                    <div class="detail-value">${report.Reason}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Description</div>
                    <div class="detail-value">${report.Description || 'No additional details provided'}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Current Status</div>
                    <div class="detail-value">
                        <span class="status-badge status-${report.Status}">${report.Status}</span>
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Created</div>
                    <div class="detail-value">${new Date(report.CreatedAt).toLocaleString()}</div>
                </div>
                ${reviewedAt ? `
                    <div class="detail-row">
                        <div class="detail-label">Reviewed</div>
                        <div class="detail-value">${reviewedAt}</div>
                    </div>
                ` : ''}
                ${report.ReviewNotes ? `
                    <div class="detail-row">
                        <div class="detail-label">Review Notes</div>
                        <div class="detail-value">${report.ReviewNotes}</div>
                    </div>
                ` : ''}
                <div class="detail-row" style="margin-top: 20px;">
                    <div class="detail-label">Update Status</div>
                    <select id="new-status" style="width: 100%; margin-bottom: 10px;">
                        <option value="pending" ${report.Status === 'pending' ? 'selected' : ''}>Pending</option>
                        <option value="reviewed" ${report.Status === 'reviewed' ? 'selected' : ''}>Reviewed</option>
                        <option value="resolved" ${report.Status === 'resolved' ? 'selected' : ''}>Resolved</option>
                        <option value="dismissed" ${report.Status === 'dismissed' ? 'selected' : ''}>Dismissed</option>
                    </select>
                    <textarea id="review-notes" placeholder="Add review notes (optional)" rows="3">${report.ReviewNotes || ''}</textarea>
                    <button onclick="updateStatus(${report.Id})" style="width: 100%; margin-top: 10px;">Update Status</button>
                </div>
            `;
            
            document.getElementById('report-modal').classList.add('active');
        }

        function closeModal() {
            document.getElementById('report-modal').classList.remove('active');
        }

        async function updateStatus(id) {
            const newStatus = document.getElementById('new-status').value;
            const reviewNotes = document.getElementById('review-notes').value;
            
            const formData = new FormData();
            formData.append('action', 'update-status');
            formData.append('id', id);
            formData.append('status', newStatus);
            formData.append('reviewNotes', reviewNotes);
            
            try {
                const response = await fetch('reports.php', {
                    method: 'POST',
                    body: formData
                });
                
                const data = await response.json();
                
                if (data.success) {
                    alert('✅ Report status updated successfully');
                    closeModal();
                    location.reload();
                } else {
                    alert('❌ Error: ' + data.error);
                }
            } catch (error) {
                console.error('Error updating status:', error);
                alert('❌ Failed to update status');
            }
        }

        async function deleteReport(id) {
            if (!confirm('Are you sure you want to delete this report? This action cannot be undone.')) {
                return;
            }
            
            const formData = new FormData();
            formData.append('action', 'delete');
            formData.append('id', id);
            
            try {
                const response = await fetch('reports.php', {
                    method: 'POST',
                    body: formData
                });
                
                const data = await response.json();
                
                if (data.success) {
                    alert('✅ Report deleted successfully');
                    location.reload();
                } else {
                    alert('❌ Error: ' + data.error);
                }
            } catch (error) {
                console.error('Error deleting report:', error);
                alert('❌ Failed to delete report');
            }
        }

        // Close modal when clicking outside
        document.getElementById('report-modal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeModal();
            }
        });
    </script>
</body>
</html>
