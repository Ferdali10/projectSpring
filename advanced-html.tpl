<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Trivy HTML Report</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
    th { background-color: #f4f4f4; }
  </style>
</head>
<body>
  <h1>📊 Rapport de Sécurité - Trivy</h1>

  <canvas id="severityChart" width="400" height="150"></canvas>
  <script>
    const vulnCounts = {
      "CRITICAL": 0,
      "HIGH": 0,
      "MEDIUM": 0,
      "LOW": 0,
      "UNKNOWN": 0
    };
    {{- range . }}
      {{- range .Vulnerabilities }}
        vulnCounts["{{ .Severity }}"] = vulnCounts["{{ .Severity }}"] + 1 || 1;
      {{- end }}
    {{- end }}

    const data = {
      labels: Object.keys(vulnCounts),
      datasets: [{
        label: 'Nombre de vulnérabilités',
        data: Object.values(vulnCounts),
        backgroundColor: ["darkred", "red", "orange", "green", "gray"]
      }]
    };

    new Chart(document.getElementById('severityChart'), {
      type: 'bar',
      data: data
    });
  </script>

  <h2>📋 Détail des vulnérabilités</h2>
  {{ range . }}
    {{ if .Vulnerabilities }}
      <h3>📦 {{ .Target }}</h3>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Package</th>
            <th>Version</th>
            <th>Gravité</th>
            <th>URL</th>
          </tr>
        </thead>
        <tbody>
          {{ range .Vulnerabilities }}
            <tr>
              <td>{{ .VulnerabilityID }}</td>
              <td>{{ .PkgName }}</td>
              <td>{{ .InstalledVersion }}</td>
              <td>{{ .Severity }}</td>
              <td><a href="{{ .PrimaryURL }}" target="_blank">🔗</a></td>
            </tr>
          {{ end }}
        </tbody>
      </table>
    {{ end }}
  {{ end }}
</body>
</html>



