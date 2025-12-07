<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'prune') {
    header('Content-Type: application/json');
    $file = 'stats/stats.json';
    if (file_put_contents($file, '[]') !== false) {
        echo json_encode(['success' => true, 'message' => 'Stats pruned successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to prune stats']);
    }
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Docker Monitoring</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            width: 100%;
        }
        #charts{
            columns: 2;
            column-gap: 20px;
        }
        .chart-container {
            width: 100%;
            overflow-x: scroll;
            margin-bottom: 20px;
            break-inside: avoid;
        }
        canvas {
            width: 100%;
            height: 400px;
        }
    </style>
</head>
<body>
    <div style="display: flex; justify-content: space-between; align-items: center;">
        <h2>Charts Over Time</h2>
        <button onclick="pruneStats()" style="background-color: #ff4444; color: white; padding: 10px; border: none; cursor: pointer; border-radius: 4px;">Prune Stats</button>
    </div>
    <div id="charts"></div>

    <h1>Docker Container Stats</h1>
    <table border="1">
        <thead>
            <tr>
                <th>Container Name</th>
                <th>CPU %</th>
                <th>Memory %</th>
                <th>Memory Usage</th>
            </tr>
        </thead>
        <tbody id="stats-table">
        </tbody>
    </table>

    <a href="db.php">Manage DB</a>

    <script>
        async function pruneStats() {
            if (!confirm('Are you sure you want to delete all stats history?')) return;
            
            try {
                const response = await fetch('?action=prune', { method: 'POST' });
                const result = await response.json();
                
                if (result.success) {
                    // Clear UI
                    document.getElementById('stats-table').innerHTML = '';
                    document.getElementById('charts').innerHTML = '';
                    // Reload data
                    const data = await loadData();
                    if (data.length > 0) {
                        updateTable(data[data.length - 1]);
                        createCharts(data);
                    }
                } else {
                    alert('Error: ' + result.message);
                }
            } catch (e) {
                alert('Error pruning stats');
                console.error(e);
            }
        }

        async function loadData() {
            const response = await fetch('stats/stats.json');
            const data = await response.json();
            return data;
        }

        function updateTable(latest) {
            const tbody = document.getElementById('stats-table');
            tbody.innerHTML = '';
            latest.stats.forEach(stat => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${stat.name}</td>
                    <td>${stat.cpu}</td>
                    <td>${stat.mem_perc}</td>
                    <td>${stat.mem_usage}</td>
                `;
                tbody.appendChild(row);
            });
        }

        function createCharts(data) {
            const chartsDiv = document.getElementById('charts');
            chartsDiv.innerHTML = '';

            // Get all container names
            const containers = [...new Set(data.flatMap(entry => entry.stats.map(s => s.name)))];

            containers.forEach(container => {
                const containerData = data.map(entry => {
                    const stat = entry.stats.find(s => s.name === container);
                    return {
                        timestamp: entry.timestamp,
                        cpu: stat ? parseFloat(stat.cpu.replace('%', '')) : 0,
                        mem: stat ? parseFloat(stat.mem_perc.replace('%', '')) : 0
                    };
                });

                const labels = containerData.map(d => new Date(d.timestamp * 1000).toLocaleTimeString());
                const cpuData = containerData.map(d => d.cpu);
                const memData = containerData.map(d => d.mem);

                const div = document.createElement('div');
                div.className = 'chart-container';
                div.innerHTML = `<h3>${container}</h3><canvas id="chart-${container}"></canvas>`;
                chartsDiv.appendChild(div);

                const ctx = document.getElementById(`chart-${container}`).getContext('2d');
                new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: labels,
                        datasets: [{
                            label: 'CPU %',
                            data: cpuData,
                            borderColor: 'rgb(75, 192, 192)',
                            tension: 0.1
                        }, {
                            label: 'Memory %',
                            data: memData,
                            borderColor: 'rgb(255, 99, 132)',
                            tension: 0.1
                        }]
                    },
                    options: {
                        responsive: false,
                        maintainAspectRatio: false,
                        animation: false
                    }
                });
            });
        }

        loadData().then(data => {
            if (data.length > 0) {
                updateTable(data[data.length - 1]);
                createCharts(data);
            }
        });

        setInterval(() => {
            loadData().then(data => {
                if (data.length > 0) {
                    updateTable(data[data.length - 1]);
                    createCharts(data);
                }
            });
        }, 120000);
    </script>
</body>
</html>
