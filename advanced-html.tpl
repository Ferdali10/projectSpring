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
          let sev = "{{ .Severity }}";
          let i = data.labels.indexOf(sev);
          if (i !== -1) {
            data.datasets[0].data[i]++;
          }
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
      {{ $target := .Target }}
      <h3>{{ $target }}</h3>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Package





