package main

import (
	"database/sql"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"

	_ "github.com/go-sql-driver/mysql"
)

type Stats struct {
	Users    interface{}
	Listings interface{}
}

type HealthStatus struct {
	Database bool
	API      bool
	UI       bool
}

type ContainerStat struct {
	Container string
	Name      string
	CPU       string
	MemUsage  string
	MemPerc   string
	NetIO     string
	BlockIO   string
}

func getDbStats() Stats {
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "db"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "maltalist_user"
	}
	dbPass := os.Getenv("DB_PASSWORD")
	if dbPass == "" {
		dbPass = "M@LtApass"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "maltalist"
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s", dbUser, dbPass, dbHost, dbName)
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Printf("DB connection error: %v", err)
		return Stats{Users: nil, Listings: nil}
	}
	defer db.Close()

	var users, listings int
	err = db.QueryRow("SELECT COUNT(*) FROM Users").Scan(&users)
	if err != nil {
		log.Printf("Users query error: %v", err)
		users = -1
	}

	err = db.QueryRow("SELECT COUNT(*) FROM Listings").Scan(&listings)
	if err != nil {
		log.Printf("Listings query error: %v", err)
		listings = -1
	}

	return Stats{Users: users, Listings: listings}
}

func checkServiceHealth(url string) bool {
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("Health check error for %s: %v", url, err)
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode == 200
}

func getContainerStats() []ContainerStat {
	cmd := exec.Command("docker", "stats", "--no-stream")
	output, err := cmd.Output()
	if err != nil {
		log.Printf("Docker stats error: %v", err)
		return []ContainerStat{}
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(lines) < 2 {
		return []ContainerStat{}
	}

	headers := strings.Fields(lines[0])
	stats := []ContainerStat{}

	for i := 1; i < len(lines); i++ {
		parts := strings.Fields(lines[i])
		if len(parts) >= len(headers) {
			stat := ContainerStat{
				Container: parts[0],
				Name:      parts[1],
				CPU:       parts[2],
				MemUsage:  parts[3],
				MemPerc:   parts[4],
				NetIO:     parts[5],
				BlockIO:   parts[6],
			}
			stats = append(stats, stat)
		}
	}

	return stats
}

func dashboardHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Loading dashboard...")

	stats := getDbStats()
	apiHealth := checkServiceHealth("http://api:5023/api/Listings/categories")
	uiHealth := checkServiceHealth("http://ui/")
	dbHealth := stats.Users != nil

	containerStats := getContainerStats()

	tmpl := `
<!DOCTYPE html>
<html>
<head>
    <title>Maltalist Monitoring Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f4; }
        .container { max-width: 800px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .stat { display: flex; justify-content: space-between; margin: 20px 0; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
        .stat span { font-weight: bold; }
        .healthy { color: green; }
        .unhealthy { color: red; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Maltalist Monitoring Dashboard</h1>
        <h2>Database Stats</h2>
        <div class="stat">
            <span>Total Users:</span>
            <span>{{if .Stats.Users}}{{.Stats.Users}}{{else}}Error{{end}}</span>
        </div>
        <div class="stat">
            <span>Total Listings:</span>
            <span>{{if .Stats.Listings}}{{.Stats.Listings}}{{else}}Error{{end}}</span>
        </div>
        <h2>Service Health</h2>
        <div class="stat">
            <span>Database:</span>
            <span class="{{if .Health.Database}}healthy{{else}}unhealthy{{end}}">{{if .Health.Database}}Healthy{{else}}Unhealthy{{end}}</span>
        </div>
        <div class="stat">
            <span>API:</span>
            <span class="{{if .Health.API}}healthy{{else}}unhealthy{{end}}">{{if .Health.API}}Healthy{{else}}Unhealthy{{end}}</span>
        </div>
        <div class="stat">
            <span>UI:</span>
            <span class="{{if .Health.UI}}healthy{{else}}unhealthy{{end}}">{{if .Health.UI}}Healthy{{else}}Unhealthy{{end}}</span>
        </div>
        <h2>Container Stats</h2>
        <table>
            <tr><th>CONTAINER</th><th>NAME</th><th>CPU %</th><th>MEM USAGE</th><th>MEM %</th><th>NET I/O</th><th>BLOCK I/O</th></tr>
            {{range .ContainerStats}}
            <tr><td>{{.Container}}</td><td>{{.Name}}</td><td>{{.CPU}}</td><td>{{.MemUsage}}</td><td>{{.MemPerc}}</td><td>{{.NetIO}}</td><td>{{.BlockIO}}</td></tr>
            {{end}}
        </table>
    </div>
</body>
</html>`

	t := template.Must(template.New("dashboard").Parse(tmpl))
	data := struct {
		Stats          Stats
		Health         HealthStatus
		ContainerStats []ContainerStat
	}{
		Stats:          stats,
		Health:         HealthStatus{Database: dbHealth, API: apiHealth, UI: uiHealth},
		ContainerStats: containerStats,
	}

	w.Header().Set("Content-Type", "text/html")
	t.Execute(w, data)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func main() {
	http.HandleFunc("/", dashboardHandler)
	http.HandleFunc("/health", healthHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Monitor app listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
