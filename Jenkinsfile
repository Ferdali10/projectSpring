@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
    }

    stages {

        stage('🚀 Build et Déploiement Complet') {
            steps {
                script {
                    // Clone du repository
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )

                    withEnv([
                        "SPRING_DATASOURCE_URL=${env.DB_URL}",
                        "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                        "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                    ]) {
                        // Build Maven
                        buildProject(
                            buildTool: 'maven',
                            args: "-DskipTests -Dspring.profiles.active=prod"
                        )

                        def jarFileName = "springFoyer-0.0.2-SNAPSHOT.jar"
                        def jarPath = "target/${jarFileName}"

                        echo "Vérification du fichier JAR : ${jarPath}"
                        def jarExists = sh(
                            script: "test -f ${jarPath} && echo 'EXISTS' || echo 'NOT_FOUND'",
                            returnStdout: true
                        ).trim()

                        if (jarExists == 'NOT_FOUND') {
                            sh 'ls -la target/ || echo "Répertoire target introuvable"'
                            error "❌ Le fichier JAR ${jarPath} est introuvable."
                        }

                        echo "✅ Fichier JAR trouvé : ${jarPath}"

                        // Build et push image Docker
                        dockerBuildFullImage(
                            imageName: "dalifer/springfoyer",
                            tags: ["latest", "${env.BUILD_NUMBER}"],
                            buildArgs: "--build-arg JAR_FILE=${jarFileName}",
                            credentialsId: "docker-hub-creds"
                        )
                    }
                }
            }
        }

        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    def imageName = "dalifer/springfoyer:latest"

                    echo "📥 Téléchargement de la base Trivy (si nécessaire)"
                    sh 'trivy image --download-db-only || true'

                    echo "🔎 Lancement du scan Trivy sur l'image : ${imageName}"
                    sh "trivy image --severity HIGH,CRITICAL --format json -o trivy-report.json ${imageName} || true"

                    // Générer un rapport HTML (nécessite contrib/html.tpl fourni par Trivy)
                    sh """
                        trivy image \
                        --severity HIGH,CRITICAL \
                        --format template \
                        --template '@contrib/html.tpl' \
                        -o trivy-report.html \
                        ${imageName} || true
                    """

                    // Lecture du JSON pour compter les vulnérabilités
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

                    // Publier le rapport HTML dans Jenkins
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




