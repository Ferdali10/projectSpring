<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Rapport de Sécurité - Trivy</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
    th { background-color: #f4f4f4; }
    .no-vuln { color: green; font-weight: bold; font-size: 1.2em; }
  </style>
</head>
<body>
  <h1>📊 Rapport de Sécurité - Trivy</h1>

  <canvas id="chart" width="600" height="300"></canvas>
  <script>
    const data = {
      labels: ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"],
      datasets: [{
        label: "Nombre de vulnérabilités",
        backgroundColor: ["darkred", "red", "orange", "green", "gray"],
        data: [0, 0, 0, 0, 0]
      }]
    };

    {{ range . }}
      {{ if .Vulnerabilities }}
        {{ range .Vulnerabilities }}
          const severity = "{{ .Severity }}";
          const idx = data.labels.indexOf(severity);
          if (idx >= 0) { data.datasets[0].data[idx]++; }
        {{ end }}
      {{ end }}
    {{ end }}

    new Chart(document.getElementById("chart"), {
      type: 'bar',
      data: data
    });
  </script>

  <h2>📋 Détail des vulnérabilités</h2>
  {{ $total := 0 }}
  {{ range . }}
    {{ if .Vulnerabilities }}
      <h3>{{ .Target }}</h3>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Package</th>
            <th>Version</th>
            <th>Gravité</th>
            <th>Lien</th>
          </tr>
        </thead>
        <tbody>
          {{ range .Vulnerabilities }}
            {{ $total = add $total 1 }}
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

  {{ if eq $total 0 }}
    <p class="no-vuln">✅ Aucune vulnérabilité détectée.</p>
  {{ end }}
</body>
</html>






