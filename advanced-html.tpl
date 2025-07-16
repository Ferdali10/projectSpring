<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport Trivy - Docker Image Scan</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial; padding: 20px; background: #f8f9fa; }
        h1 { color: #333; }
        .section { margin-bottom: 40px; }
        canvas { max-width: 600px; }
    </style>
</head>
<body>
    <h1>📊 Rapport Trivy</h1>

    <div class="section">
        <h2>Vulnérabilités détectées</h2>
        <canvas id="vulnChart"></canvas>
    </div>

    <div class="section">
        <h2>Détails par composant</h2>
        {{- range .Results }}
            {{ if .Vulnerabilities }}
                <h3>{{ .Target }}</h3>
                <table border="1" cellspacing="0" cellpadding="5">
                    <thead>
                        <tr><th>ID</th><th>Pkg</th><th>Version</th><th>Severity</th><th>Title</th></tr>
                    </thead>
                    <tbody>
                    {{- range .Vulnerabilities }}
                        <tr>
                            <td>{{ .VulnerabilityID }}</td>
                            <td>{{ .PkgName }}</td>
                            <td>{{ .InstalledVersion }}</td>
                            <td>{{ .Severity }}</td>
                            <td>{{ .Title }}</td>
                        </tr>
                    {{- end }}
                    </tbody>
                </table>
            {{- end }}
        {{- end }}
    </div>

    <script>
        // Collect data from template
        const severities = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"];
        const counts = {
            "CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0, "UNKNOWN": 0
        };

        {{- range .Results }}
            {{- range .Vulnerabilities }}
                counts["{{ .Severity }}"] = (counts["{{ .Severity }}"] || 0) + 1;
            {{- end }}
        {{- end }}

        const ctx = document.getElementById('vulnChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: severities,
                datasets: [{
                    label: 'Vulnérabilités détectées',
                    data: severities.map(s => counts[s]),
                    backgroundColor: [
                        '#dc3545', '#fd7e14', '#ffc107', '#0d6efd', '#6c757d'
                    ],
                    borderColor: '#ccc',
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    </script>
</body>
</html>

