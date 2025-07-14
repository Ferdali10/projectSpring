pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
    }

    stages {

        // Ton stage de build + Docker ici...

        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    def imageName = "dalifer/springfoyer:latest"

                    echo "📥 Téléchargement de la base Trivy (si nécessaire)"
                    sh 'trivy image --download-db-only || true'

                    echo "🔎 Lancement du scan Trivy sur l'image : ${imageName}"
                    sh "trivy image --severity HIGH,CRITICAL --format json -o trivy-report.json ${imageName} || true"

                    // Génère rapport HTML
                    sh """
                        trivy image \
                        --severity HIGH,CRITICAL \
                        --format template \
                        --template "@contrib/html.tpl" \
                        -o trivy-report.html \
                        ${imageName} || true
                    """

                    def trivyJson = readJSON file: 'trivy-report.json'
                    def vulnCount = 0
                    def vulnSummary = ""

                    trivyJson.Results.each { result ->
                        if (result.Vulnerabilities) {
                            result.Vulnerabilities.each { vuln ->
                                if (["HIGH", "CRITICAL"].contains(vuln.Severity)) {
                                    vulnCount++
                                    vulnSummary += "- ${vuln.VulnerabilityID} (${vuln.Severity}) in ${vuln.PkgName} [${vuln.Title}]\n"
                                }
                            }
                        }
                    }

                    echo "🚨 Vulnérabilités critiques/hautes détectées : ${vulnCount}"

                    if (vulnCount > 3) {
                        echo "❌ Trop de vulnérabilités critiques (>${3})"
                        echo "📋 Détail des vulnérabilités :\n${vulnSummary}"
                        error("Pipeline stoppé pour raison de sécurité.")
                    } else {
                        echo "✅ Moins de 3 vulnérabilités importantes détectées. Poursuite du pipeline."
                    }

                    archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true

                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-report.html',
                        reportName: 'Trivy - Rapport de Sécurité',
                        reportTitles: 'Analyse des vulnérabilités Docker'
                    ])
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
        }
        success {
            echo "🎉 Pipeline exécuté avec succès !"
        }
        failure {
            echo "❌ Pipeline échoué. Vérifiez les logs ci-dessus."
        }
    }
}



