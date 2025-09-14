<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Docker Monitoring</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .chart-container {
            width: 100%;
            overflow-x: scroll;
            margin-bottom: 20px;
        }
        canvas {
            width: 2000px;
            height: 400px;
        }
    </style>
</head>
<body>
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

    <h2>Charts Over Time</h2>
    <div id="charts"></div>

    <script>
        async function loadData() {
            const response = await fetch('stats.json');
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
                        maintainAspectRatio: false
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
        }, 60000);
    </script>
</body>
</html>
