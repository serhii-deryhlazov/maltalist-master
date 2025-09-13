from flask import Flask
import mysql.connector
import requests
import os
import subprocess

app = Flask(__name__)

def get_db_stats():
    try:
        conn = mysql.connector.connect(
            host=os.getenv('DB_HOST', 'db'),
            user=os.getenv('DB_USER', 'maltalist_user'),
            password=os.getenv('DB_PASSWORD', 'M@LtApass'),
            database=os.getenv('DB_NAME', 'maltalist')
        )
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM Users")
        users_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM Listings")
        listings_count = cursor.fetchone()[0]
        conn.close()
        return users_count, listings_count
    except Exception as e:
        return None, str(e)

def check_service_health(service_name, url):
    try:
        response = requests.get(url, timeout=5)
        return response.status_code == 200
    except:
        return False

def get_container_stats():
    try:
        result = subprocess.run(['docker', 'stats', '--no-stream', '--format', 'table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}'], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            if len(lines) > 1:
                headers = lines[0].split('\t')
                stats = []
                for line in lines[1:]:
                    parts = line.split('\t')
                    if len(parts) >= len(headers):
                        stat = dict(zip(headers, parts))
                        stats.append(stat)
                return stats
        return []
    except Exception as e:
        return []

@app.route('/')
def dashboard():
    users_count, listings_count = get_db_stats()
    api_health = check_service_health('API', 'http://api:5023/api/Listings/categories')
    ui_health = check_service_health('UI', 'http://ui/')
    db_health = users_count is not None
    container_stats = get_container_stats()
    table_html = '<table style="width:100%; border-collapse: collapse;"><tr><th>Container ID</th><th>Name</th><th>CPU %</th><th>Mem Usage</th><th>Mem %</th><th>Net I/O</th><th>Block I/O</th></tr>'
    for stat in container_stats:
        table_html += f'<tr><td>{stat.get("CONTAINER ID", "")}</td><td>{stat.get("NAME", "")}</td><td>{stat.get("CPU %", "")}</td><td>{stat.get("MEM USAGE / LIMIT", "")}</td><td>{stat.get("MEM %", "")}</td><td>{stat.get("NET I/O", "")}</td><td>{stat.get("BLOCK I/O", "")}</td></tr>'
    table_html += '</table>'

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Maltalist Monitoring Dashboard</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f4; }}
            .container {{ max-width: 800px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }}
            h1 {{ color: #333; text-align: center; }}
            .stat {{ display: flex; justify-content: space-between; margin: 20px 0; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }}
            .stat span {{ font-weight: bold; }}
            .healthy {{ color: green; }}
            .unhealthy {{ color: red; }}
            table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
            th, td {{ padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }}
            th {{ background-color: #f2f2f2; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Maltalist Monitoring Dashboard</h1>
            <h2>Database Stats</h2>
            <div class="stat">
                <span>Total Users:</span>
                <span>{users_count if users_count is not None else 'Error'}</span>
            </div>
            <div class="stat">
                <span>Total Listings:</span>
                <span>{listings_count if listings_count is not None else 'Error'}</span>
            </div>
            <h2>Service Health</h2>
            <div class="stat">
                <span>Database:</span>
                <span class="{'healthy' if db_health else 'unhealthy'}">{ 'Healthy' if db_health else 'Unhealthy' }</span>
            </div>
            <div class="stat">
                <span>API:</span>
                <span class="{'healthy' if api_health else 'unhealthy'}">{ 'Healthy' if api_health else 'Unhealthy' }</span>
            </div>
            <div class="stat">
                <span>UI:</span>
                <span class="{'healthy' if ui_health else 'unhealthy'}">{ 'Healthy' if ui_health else 'Unhealthy' }</span>
            </div>
            <h2>Container Stats</h2>
            {table_html}
        </div>
    </body>
    </html>
    """
    return html

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
