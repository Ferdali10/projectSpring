@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        SKIP_QUALITY_GATE = 'false'
        TRIVY_DB_REPOSITORY = 'ghcr.io/aquasecurity/trivy-db' // Alternative mirror
    }

    stages {
        stage('🚀 Build et Déploiement Complet') {
            steps {
                script {
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
                        buildProject(
                            buildTool: 'maven',
                            args: "-DskipTests -Dspring.profiles.active=prod"
                        )

                        def jarFileName = "springFoyer-0.0.2-SNAPSHOT.jar"
                        def jarPath = "target/${jarFileName}"

                        if (!fileExists(jarPath)) {
                            error "❌ Fichier JAR ${jarPath} introuvable"
                        }

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

        stage('📊 Analyse SonarQube') {
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    sh "mvn sonar:sonar -Dsonar.projectKey=springfoyer"
                }
            }
        }

        stage('🛂 Vérification Quality Gate') {
            when {
                expression { env.SKIP_QUALITY_GATE != 'true' }
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    def imageName = "dalifer/springfoyer:latest"

                    // Téléchargement avec gestion des erreurs
                    sh """
                        curl --retry 3 -sLO ${env.TRIVY_TEMPLATE_URL} || true
                        [ -f advanced-html.tpl ] && mv advanced-html.tpl html.tpl || echo "Template download failed"
                    """

                    // Téléchargement DB avec timeout augmenté
                    sh """
                        trivy image --download-db-only --timeout 10m || echo "DB download failed, proceeding with cached data"
                    """

                    // Analyse avec gestion des erreurs
                    sh """
                        trivy image --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format json \
                            -o trivy-report.json \
                            ${imageName} || echo "Scan failed"

                        if [ -f html.tpl ]; then
                            trivy image --severity HIGH,CRITICAL \
                                --ignore-unfixed \
                                --format template \
                                --template '@html.tpl' \
                                -o trivy-report.html \
                                ${imageName} || echo "HTML report generation failed"
                        fi
                    """

                    // Traitement des résultats avec vérification d'existence
                    if (fileExists('trivy-report.json')) {
                        try {
                            def report = readJSON file: 'trivy-report.json'
                            def criticalVulns = report.Results?.findAll { it.Vulnerabilities }
                                                  ?.collectMany { it.Vulnerabilities }
                                                  ?.count { it.Severity == "CRITICAL" } ?: 0

                            if (criticalVulns > 0) {
                                unstable("⚠️ ${criticalVulns} vulnérabilités CRITICAL détectées")
                            }
                        } catch (Exception e) {
                            echo "Erreur lors de l'analyse du rapport Trivy: ${e.getMessage()}"
                        }
                    }

                    // Archivage avec allowEmptyArchive
                    archiveArtifacts artifacts: 'trivy-report.*', allowEmptyArchive: true, fingerprint: true

                    // Publication HTML conditionnelle
                    if (fileExists('trivy-report.html')) {
                        publishHTML([
                            reportDir: '.',
                            reportFiles: 'trivy-report.html',
                            reportName: 'Rapport Trivy',
                            reportTitles: 'Vulnérabilités Sécurité',
                            keepAll: true,
                            allowMissing: false
                        ])
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
            script {
                sh 'rm -f html.tpl trivy-report.* || true'
                echo currentBuild.result == 'SUCCESS' 
                    ? "🎉 Pipeline réussi - ${env.JOB_NAME} #${env.BUILD_NUMBER}" 
                    : "❌ Pipeline en état: ${currentBuild.result} - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            }
        }
    }
}
