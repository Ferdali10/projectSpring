@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        // Configuration base de données
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        
        // Configuration Trivy
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        TRIVY_DB_REPOSITORY = 'ghcr.io/aquasecurity/trivy-db'
        
        // Configuration SonarQube
        SONAR_HOST = 'http://localhost:9000' // À adapter
        SONAR_PROJECT_KEY = 'springfoyer'
        SKIP_QUALITY_GATE = 'false'
    }

    stages {
        stage('🛠️ Préparation') {
            steps {
                script {
                    echo "Initialisation du pipeline - Build #${env.BUILD_NUMBER}"
                    sh 'git config --global http.sslVerify false' // Optionnel si problèmes SSL
                }
            }
        }

        stage('📥 Clone du dépôt') {
            steps {
                script {
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )
                }
            }
        }

        stage('🏗️ Build Maven') {
            steps {
                script {
                    withEnv([
                        "SPRING_DATASOURCE_URL=${env.DB_URL}",
                        "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                        "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                    ]) {
                        buildProject(
                            buildTool: 'maven',
                            args: "-DskipTests -Dspring.profiles.active=prod"
                        )
                    }
                    
                    def jarPath = "target/springFoyer-0.0.2-SNAPSHOT.jar"
                    if (!fileExists(jarPath)) {
                        error "❌ Fichier JAR ${jarPath} introuvable"
                    }
                }
            }
        }

        stage('🐳 Build Docker') {
            steps {
                script {
                    dockerBuildFullImage(
                        imageName: "dalifer/springfoyer",
                        tags: ["latest", "${env.BUILD_NUMBER}"],
                        buildArgs: "--build-arg JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar",
                        credentialsId: "docker-hub-creds"
                    )
                }
            }
        }

        stage('🔍 Analyse SonarQube') {
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                        -Dsonar.host.url=${env.SONAR_HOST}
                    """
                }
            }
        }

        stage('📊 Rapport Qualité') {
            when {
                expression { env.SKIP_QUALITY_GATE != 'true' }
            }
            steps {
                script {
                    timeout(time: 15, unit: 'MINUTES') {
                        def qg = waitForQualityGate abortPipeline: false
                        
                        // Génération du rapport simplifié
                        def reportContent = """
                            <!DOCTYPE html>
                            <html>
                            <head>
                                <title>Rapport Qualité - ${env.SONAR_PROJECT_KEY}</title>
                                <style>
                                    body { font-family: Arial, sans-serif; margin: 20px; }
                                    .passed { color: #4CAF50; font-weight: bold; }
                                    .failed { color: #F44336; font-weight: bold; }
                                    .info { margin: 20px 0; padding: 15px; background: #f8f8f8; }
                                    a { color: #2196F3; }
                                </style>
                            </head>
                            <body>
                                <h1>Rapport d'analyse qualité</h1>
                                <div class="info">
                                    <p>Projet: <strong>${env.SONAR_PROJECT_KEY}</strong></p>
                                    <p>Statut Quality Gate: <span class="${qg.status == 'OK' ? 'passed' : 'failed'}">${qg.status}</span></p>
                                    <p>Lien vers le rapport complet: <a href="${env.SONAR_HOST}/dashboard?id=${env.SONAR_PROJECT_KEY}" target="_blank">Ouvrir dans SonarQube</a></p>
                                </div>
                                ${qg.status != 'OK' ? '<h2>⚠️ Des problèmes de qualité ont été détectés</h2><p>Veuillez corriger les problèmes identifiés dans SonarQube</p>' : ''}
                            </body>
                            </html>
                        """
                        
                        writeFile file: 'sonar-report.html', text: reportContent
                        publishHTML([
                            reportDir: '.',
                            reportFiles: 'sonar-report.html',
                            reportName: 'Rapport Qualité SonarQube',
                            keepAll: true
                        ])

                        if (qg.status != 'OK') {
                            unstable("Des problèmes de qualité ont été détectés")
                        }
                    }
                }
            }
        }

        stage('🔒 Analyse de sécurité (Trivy)') {
            steps {
                script {
                    def imageName = "dalifer/springfoyer:latest"

                    // Téléchargement du template
                    sh """
                        curl --retry 3 -sLO ${env.TRIVY_TEMPLATE_URL} || echo "⚠️ Échec téléchargement template"
                        [ -f advanced-html.tpl ] && mv advanced-html.tpl html.tpl || echo "ℹ️ Utilisation du cache local"
                    """

                    // Mise à jour de la base de données Trivy
                    sh """
                        trivy image --download-db-only --timeout 10m || echo "⚠️ Échec mise à jour DB Trivy"
                    """

                    // Analyse de sécurité
                    sh """
                        trivy image --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format json \
                            -o trivy-report.json \
                            ${imageName} || echo "⚠️ Échec analyse Trivy"

                        if [ -f html.tpl ]; then
                            trivy image --severity HIGH,CRITICAL \
                                --ignore-unfixed \
                                --format template \
                                --template '@html.tpl' \
                                -o trivy-report.html \
                                ${imageName} || echo "⚠️ Échec génération rapport HTML"
                        fi
                    """

                    // Traitement des résultats
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
                            echo "❌ Erreur analyse rapport Trivy: ${e.getMessage()}"
                        }
                    }

                    // Archivage des rapports
                    archiveArtifacts artifacts: 'trivy-report.*', allowEmptyArchive: true
                    
                    // Publication du rapport HTML
                    if (fileExists('trivy-report.html')) {
                        publishHTML([
                            reportDir: '.',
                            reportFiles: 'trivy-report.html',
                            reportName: 'Rapport de Sécurité Trivy',
                            keepAll: true
                        ])
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Nettoyage
                sh 'docker system prune -f || true'
                sh 'rm -f html.tpl *.json *.html || true'
                
                // Rapport final
                def statusMessages = [
                    'SUCCESS': "✅ Pipeline terminé avec succès",
                    'UNSTABLE': "⚠️ Pipeline terminé avec des avertissements",
                    'FAILURE': "❌ Pipeline en échec",
                    'ABORTED': "⏹ Pipeline interrompu"
                ]
                
                echo "${statusMessages.get(currentBuild.result, 'État inconnu')} - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                
                // Notification pour les builds instables/échecs
                if (currentBuild.result in ['UNSTABLE', 'FAILURE']) {
                    emailext (
                        subject: "[${currentBuild.result}] ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                        body: """
                            Bonjour,
                            
                            Le pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} a terminé avec le statut : ${currentBuild.result}
                            
                            Détails :
                            - Rapport SonarQube : ${env.SONAR_HOST}/dashboard?id=${env.SONAR_PROJECT_KEY}
                            - Console du build : ${env.BUILD_URL}console
                            
                            Cordialement,
                            Votre plateforme CI/CD
                        """,
                        to: 'equipe-dev@votre-domaine.com',
                        attachLog: true
                    )
                }
            }
        }
    }
}
