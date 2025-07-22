@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        SKIP_QUALITY_GATE = 'false'  // mettre 'true' pour ignorer la vérification Quality Gate
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
            environment {
                SONARQUBE_SCANNER_PARAMS = "-Dsonar.projectKey=springfoyer"
            }
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    sh "mvn sonar:sonar ${env.SONARQUBE_SCANNER_PARAMS}"
                }
            }
        }

        stage('🛂 Vérification Quality Gate') {
            when {
                expression { env.SKIP_QUALITY_GATE != 'true' }
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    // Continue même si la Quality Gate est en échec
                    waitForQualityGate abortPipeline: false
                }
            }
        }

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
                        trivy image --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format json \
                            -o trivy-report.json \
                            ${imageName}

                        trivy image --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format template \
                            --template '@html.tpl' \
                            -o trivy-report.html \
                            ${imageName}
                    """

                    def report = readJSON file: 'trivy-report.json'
                    def criticalVulns = report.Results
                        .findAll { it.Vulnerabilities }
                        .collectMany { it.Vulnerabilities }
                        .count { it.Severity == "CRITICAL" }

                    if (criticalVulns > 0) {
                        error "❌ ${criticalVulns} vulnérabilités CRITICAL détectées"
                    }

                    archiveArtifacts artifacts: 'trivy-report.*', fingerprint: true

                    publishHTML([
                        reportDir: '.',
                        reportFiles: 'trivy-report.html',
                        reportName: 'Rapport Trivy',
                        reportTitles: 'Vulnérabilités Sécurité (Graphiques inclus)',
                        keepAll: true,
                        allowMissing: false
                    ])
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
                    : "❌ Pipeline échoué - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            }
        }
    }
}
