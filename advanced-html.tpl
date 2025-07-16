<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Trivy Vulnerability Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 8px 12px; border: 1px solid #ccc; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>🔍 Trivy Vulnerability Report</h1>
    <p>Generated at: {{ .GeneratedAt }}</p>

    <canvas id="severityChart" width="400" height="200"></canvas>

    <script>
        const data = {
            labels: ["UNKNOWN", "LOW", "MEDIUM", "HIGH", "CRITICAL"],
            datasets: [{
                label: 'Nombre de vulnérabilités',
                data: [
                    {{ len (filterVulns .Vulnerabilities "UNKNOWN") }},
                    {{ len (filterVulns .Vulnerabilities "LOW") }},
                    {{ len (filterVulns .Vulnerabilities "MEDIUM") }},
                    {{ len (filterVulns .Vulnerabilities "HIGH") }},
                    {{ len (filterVulns .Vulnerabilities "CRITICAL") }}
                ],
                backgroundColor: ["gray", "green", "orange", "red", "darkred"]
            }]
        };

        new Chart(document.getElementById('severityChart'), {
            type: 'bar',
            data: data
        });
    </script>

    <h2>Détails des vulnérabilités</h2>
    <table>
        <thead>
            <tr>
                <th>Paquet</th>
                <th>Version</th>
                <th>Vulnérabilité</th>
                <th>Gravité</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            {{ range .Vulnerabilities }}
            <tr>
                <td>{{ .PkgName }}</td>
                <td>{{ .InstalledVersion }}</td>
                <td><a href="{{ .PrimaryURL }}" target="_blank">{{ .VulnerabilityID }}</a></td>
                <td>{{ .Severity }}</td>
                <td>{{ .Title }}</td>
            </tr>
            {{ end }}
        </tbody>
    </table>
</body>
</html>


