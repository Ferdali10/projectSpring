@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        // Configurations de base
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        
        // Configuration SonarQube
        SONAR_PROJECT_KEY = 'springfoyer'
        SONAR_PROJECT_NAME = 'springFoyer'
        
        // Configuration Trivy
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        
        // Optimisation Maven
        MAVEN_OPTS = '-Dmaven.wagon.http.retryHandler.count=5 -Dmaven.wagon.http.connectionTimeout=300000 -Dmaven.wagon.http.readTimeout=300000'
    }

    stages {
        /* ---------------------------- */
        /* ÉTAPE 1 : PRÉPARATION */
        /* ---------------------------- */
        stage('🔧 Préparation') {
            steps {
                script {
                    cleanWs()
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 2 : BUILD MAVEN */
        /* ---------------------------- */
        stage('🛠️ Build Maven') {
            steps {
                script {
                    try {
                        sh """
                            ./mvnw clean package \
                            -DskipTests \
                            -Dspring.profiles.active=prod \
                            -B -V -e
                        """
                        
                        def jarPath = "target/springFoyer-0.0.2-SNAPSHOT.jar"
                        if (!fileExists(jarPath)) {
                            error "❌ Fichier JAR introuvable : ${jarPath}"
                        }
                    } catch (e) {
                        archiveArtifacts artifacts: '**/target/*.log,**/target/surefire-reports/*', fingerprint: true
                        error "Échec du build Maven : ${e.getMessage()}"
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 3 : ANALYSE SONARQUBE */
        /* ---------------------------- */
        stage('📊 Analyse SonarQube') {
            steps {
                script {
                    withSonarQubeEnv('SonanQubeServer') {
                        withCredentials([string(credentialsId: 'jenkins-key', variable: 'SONAR_TOKEN')]) {
                            sh """
                                ./mvnw sonar:sonar \
                                -Dsonar.login=$SONAR_TOKEN \
                                -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                                -Dsonar.projectName="${env.SONAR_PROJECT_NAME}" \
                                -Dsonar.sources=src/main/java \
                                -Dsonar.tests=src/test/java \
                                -Dsonar.java.binaries=target/classes \
                                -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                            """
                        }
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 4 : QUALITY GATE */
        /* ---------------------------- */
        stage('🛂 Vérification Quality Gate') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Quality Gate échouée : ${qg.status}"
                        }
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 5 : BUILD DOCKER */
        /* ---------------------------- */
        stage('🐳 Build Docker') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                        def image = docker.build("dalifer/springfoyer:${env.BUILD_NUMBER}", "--build-arg JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar .")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 6 : ANALYSE TRIVY */
        /* ---------------------------- */
        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    // Téléchargement DB et template
                    sh """
                        trivy image --download-db-only
                        curl -sLO ${env.TRIVY_TEMPLATE_URL} || true
                        [ -f advanced-html.tpl ] && mv advanced-html.tpl html.tpl || echo "Template non trouvé, utilisation du défaut"
                    """

                    // Analyse de sécurité
                    sh """
                        trivy image \
                        --scanners vuln \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --format template \
                        --template '@html.tpl' \
                        -o trivy-report.html \
                        dalifer/springfoyer:latest || true
                    """

                    // Publication du rapport
                    publishHTML([
                        allowMissing: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-report.html',
                        reportName: 'Rapport Trivy',
                        reportTitles: 'Analyse de Sécurité'
                    ])
                }
            }
        }
    }

    post {
        always {
            script {
                // Nettoyage
                sh 'docker system prune -f || true'
                sh 'rm -f html.tpl trivy-report.* || true'
                
                // Notification dans les logs
                def buildStatus = currentBuild.currentResult
                echo "Build status: ${buildStatus}"
            }
        }
        
        success {
            echo "🎉 Pipeline réussi - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        
        failure {
            echo "❌ Pipeline échoué - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            archiveArtifacts artifacts: '**/target/*.log,**/surefire-reports/*', fingerprint: true
        }
        
        unstable {
            echo "⚠️ Pipeline instable - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}







