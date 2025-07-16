stage('🔍 Analyse Trivy') {
  steps {
    script {
      def imageName = "dalifer/springfoyer:latest"
      sh """
        curl -sLO ${env.TRIVY_TEMPLATE_URL}
        mv advanced-html.tpl html.tpl
        trivy image --download-db-only
      """

      sh """
        trivy image --format json -o trivy-report.json ${imageName}
        trivy image --format template --template '@html.tpl' -o trivy-report.html ${imageName}
      """

      def report = readJSON file: 'trivy-report.json'
      def critical = report.Results.collectMany { it.Vulnerabilities ?: [] }
                              .count { it.Severity == 'CRITICAL' }
      if (critical > 0) {
        error "❌ ${critical} vulnérabilités CRITICAL détectées"
      }

      archiveArtifacts artifacts: 'trivy-report.*', fingerprint: true
      publishHTML([
        allowMissing: false,
        keepAll: true,
        reportDir: '.',
        reportFiles: 'trivy-report.html',
        reportName: 'Rapport Trivy',
        reportTitles: 'Vulnérabilités Sécurité'
      ])
    }
  }
}




