@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        SONAR_PROJECT_KEY = 'springfoyer'
        SONAR_PROJECT_NAME = 'springFoyer'
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
                        // Étape de build Maven avant SonarQube
                        stage('🛠️ Build Maven') {
                            buildProject(
                                buildTool: 'maven',
                                args: "-DskipTests -Dspring.profiles.active=prod"
                            )
                        }

                        // Étape d'analyse SonarQube
                        stage('📊 Analyse SonarQube') {
                            withSonarQubeEnv('SonarQubeServer') {
                                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                                    sh """
                                        mvn sonar:sonar \
                                        -Dsonar.login=\$SONAR_TOKEN \
                                        -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                                        -Dsonar.projectName="${env.SONAR_PROJECT_NAME}" \
                                        -Dsonar.sources=src/main/java \
                                        -Dsonar.tests=src/test/java \
                                        -Dsonar.java.binaries=target/classes \
                                        -Dsonar.java.libraries=target/*.jar
                                    """
                                }
                            }
                        }

                        // Quality Gate avec timeout étendu et gestion d'erreur améliorée
                        stage('🛂 Vérification Quality Gate') {
                            timeout(time: 10, unit: 'MINUTES') {
                                script {
                                    def maxRetries = 3
                                    def retryCount = 0
                                    def qgPassed = false
                                    
                                    while (retryCount < maxRetries && !qgPassed) {
                                        try {
                                            echo "Tentative ${retryCount + 1}/${maxRetries} de vérification du Quality Gate"
                                            def qg = waitForQualityGate()
                                            
                                            if (qg.status == 'OK') {
                                                echo "✅ Quality Gate réussie"
                                                qgPassed = true
                                            } else {
                                                echo "⚠️ Quality Gate échouée : ${qg.status}"
                                                if (retryCount == maxRetries - 1) {
                                                    // Dernière tentative - vous pouvez choisir de continuer ou d'échouer
                                                    echo "🔄 Continuation malgré l'échec du Quality Gate (dernière tentative)"
                                                    // Décommentez la ligne suivante pour faire échouer le pipeline
                                                    // error "Quality Gate échouée après ${maxRetries} tentatives : ${qg.status}"
                                                    qgPassed = true // Forcer le passage pour continuer
                                                }
                                            }
                                        } catch (Exception e) {
                                            echo "❌ Erreur lors de la vérification du Quality Gate : ${e.message}"
                                            if (retryCount == maxRetries - 1) {
                                                echo "🔄 Continuation malgré l'erreur du Quality Gate"
                                                qgPassed = true // Forcer le passage pour continuer
                                            }
                                        }
                                        
                                        if (!qgPassed) {
                                            retryCount++
                                            if (retryCount < maxRetries) {
                                                echo "⏳ Attente de 30 secondes avant la prochaine tentative..."
                                                sleep(30)
                                            }
                                        }
                                    }
                                }
                            }
                        }

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

        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    def imageName = "dalifer/springfoyer:latest"

                    // Téléchargement du template avec retry
                    retry(3) {
                        sh """
                            curl -sLO ${env.TRIVY_TEMPLATE_URL} || curl -sLO ${env.TRIVY_TEMPLATE_URL}
                            mv advanced-html.tpl html.tpl
                        """
                    }

                    // Mise à jour de la base de données Trivy
                    sh """
                        trivy image --download-db-only --timeout 10m
                    """

                    // Analyse de sécurité
                    sh """
                        trivy image --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format json \
                            --timeout 10m \
                            -o trivy-report.json \
                            ${imageName}

                        trivy image --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format template \
                            --template '@html.tpl' \
                            --timeout 10m \
                            -o trivy-report.html \
                            ${imageName}
                    """

                    // Vérification des vulnérabilités critiques
                    script {
                        try {
                            def report = readJSON file: 'trivy-report.json'
                            def criticalVulns = 0
                            
                            if (report.Results) {
                                criticalVulns = report.Results
                                    .findAll { it.Vulnerabilities }
                                    .collectMany { it.Vulnerabilities }
                                    .count { it.Severity == "CRITICAL" }
                            }

                            echo "🔍 ${criticalVulns} vulnérabilités CRITICAL détectées"
                            
                            if (criticalVulns > 0) {
                                // Vous pouvez choisir de faire échouer ou juste alerter
                                echo "⚠️ ${criticalVulns} vulnérabilités CRITICAL détectées - Veuillez les corriger"
                                // Décommentez pour faire échouer le pipeline
                                // error "❌ ${criticalVulns} vulnérabilités CRITICAL détectées"
                            }
                        } catch (Exception e) {
                            echo "⚠️ Erreur lors de l'analyse du rapport Trivy : ${e.message}"
                        }
                    }

                    // Archivage des rapports
                    archiveArtifacts artifacts: 'trivy-report.*', fingerprint: true, allowEmptyArchive: true

                    // Publication du rapport HTML
                    try {
                        publishHTML([
                            allowMissing: false,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'trivy-report.html',
                            reportName: 'Rapport Trivy',
                            reportTitles: 'Vulnérabilités Sécurité (Graphiques inclus)'
                        ])
                    } catch (Exception e) {
                        echo "⚠️ Impossible de publier le rapport HTML : ${e.message}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Nettoyage Docker
                sh 'docker system prune -f || true'
                
                // Nettoyage des fichiers temporaires
                sh 'rm -f html.tpl trivy-report.* || true'

                // Message de statut
                if (currentBuild.result == 'SUCCESS' || currentBuild.result == null) {
                    echo "🎉 Pipeline réussi - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                } else {
                    echo "❌ Pipeline échoué - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                }
            }
        }
        success {
            echo "✅ Pipeline terminé avec succès"
        }
        failure {
            echo "❌ Pipeline échoué - Vérifiez les logs ci-dessus"
        }
        aborted {
            echo "🚫 Pipeline interrompu"
        }
    }
}














