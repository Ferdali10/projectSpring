{{- /* Trivy Custom HTML Template with Graphs */ -}}
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Trivy Scan Report - {{ .ArtifactName }}</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial; margin: 20px; }
    .section { margin-bottom: 30px; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; }
    th { background-color: #4CAF50; color: white; }
  </style>
</head>
<body>
  <h1>Trivy Security Report</h1>
  <p><strong>Image:</strong> {{ .ArtifactName }}</p>
  <p><strong>Generated At:</strong> {{ .CreatedAt }}</p>

  <div class="section">
    <h2>Résumé des vulnérabilités</h2>
    <canvas id="severityChart" width="600" height="300"></canvas>
  </div>

  <script>
    const data = {
      labels: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'UNKNOWN'],
      datasets: [{
        label: 'Vulnérabilités détectées',
        backgroundColor: ['#e74c3c', '#e67e22', '#f1c40f', '#3498db', '#7f8c8d'],
        data: [
          {{ countVulnerabilities . "CRITICAL" }},
          {{ countVulnerabilities . "HIGH" }},
          {{ countVulnerabilities . "MEDIUM" }},
          {{ countVulnerabilities . "LOW" }},
          {{ countVulnerabilities . "UNKNOWN" }}
        ]
      }]
    };

    new Chart(document.getElementById('severityChart'), {
      type: 'bar',
      data: data,
      options: { responsive: true }
    });
  </script>

  {{ range .Results }}
    {{ if .Vulnerabilities }}
    <div class="section">
      <h3>Target: {{ .Target }}</h3>
      <table>
        <thead>
          <tr>
            <th>Pkg Name</th><th>Installed</th><th>Fixed</th><th>Severity</th><th>Title</th>
          </tr>
        </thead>
        <tbody>
          {{ range .Vulnerabilities }}
          <tr>
            <td>{{ .PkgName }}</td>
            <td>{{ .InstalledVersion }}</td>
            <td>{{ .FixedVersion }}</td>
            <td>{{ .Severity }}</td>
            <td>{{ .Title }}</td>
          </tr>
          {{ end }}
        </tbody>
      </table>
    </div>
    {{ end }}
  {{ end }}
</body>
</html>
