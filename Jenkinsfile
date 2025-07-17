@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        // Configuration base de données
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        
        // Configuration SonarQube
        SONAR_PROJECT_KEY = 'springfoyer'
        SONAR_PROJECT_NAME = 'springFoyer'
        
        // Configuration Trivy
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        
        // Optimisation Maven
        MAVEN_OPTS = '-Xmx1024m -XX:MaxPermSize=256m'
    }

    stages {
        /* ---------------------------- */
        /* ÉTAPE 1 : PRÉPARATION       */
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
                    
                    // Vérification environnement
                    sh """
                        echo "=== ENVIRONNEMENT ==="
                        java -version
                        mvn -version
                        echo "JAVA_HOME: ${env.JAVA_HOME}"
                    """
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 2 : BUILD MAVEN        */
        /* ---------------------------- */
        stage('🛠️ Build Maven') {
            steps {
                script {
                    try {
                        sh """
                            mvn clean package \
                            -DskipTests \
                            -Dspring.profiles.active=prod \
                            -B -V -e
                        """
                        
                        // Vérification du JAR généré
                        def jarFile = findFiles(glob: 'target/*.jar')[0]?.name
                        if (!jarFile) {
                            error "❌ Aucun fichier JAR trouvé dans target/"
                        }
                        env.JAR_FILE = jarFile
                        echo "✅ Fichier JAR trouvé : ${jarFile}"
                        
                    } catch (Exception e) {
                        echo "❌ Erreur lors du build Maven : ${e.getMessage()}"
                        archiveArtifacts artifacts: '**/target/*.log,**/target/surefire-reports/*', allowEmptyArchive: true
                        throw e
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 3 : ANALYSE SONARQUBE  */
        /* ---------------------------- */
        stage('📊 Analyse SonarQube') {
            steps {
                script {
                    try {
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
                                    -Dsonar.java.libraries=target/*.jar \
                                    -Dsonar.scm.provider=git \
                                    -Dsonar.verbose=true
                                """
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠️ Erreur SonarQube : ${e.getMessage()}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 4 : QUALITY GATE       */
        /* ---------------------------- */
        stage('🛂 Vérification Quality Gate') {
            steps {
                script {
                    try {
                        timeout(time: 15, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            echo "=== RÉSULTAT QUALITY GATE ==="
                            echo "Statut: ${qg.status}"
                            
                            if (qg.status == 'IN_PROGRESS') {
                                error "Timeout - Quality Gate bloquée en IN_PROGRESS"
                            } else if (qg.status != 'OK') {
                                error "Quality Gate échouée : ${qg.status}"
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠️ Erreur Quality Gate : ${e.getMessage()}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 5 : BUILD DOCKER       */
        /* ---------------------------- */
        stage('🐳 Build Docker') {
            steps {
                script {
                    try {
                        docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                            def image = docker.build("dalifer/springfoyer:${env.BUILD_NUMBER}", ".")
                            image.push()
                            image.push('latest')
                            echo "✅ Image Docker publiée"
                        }
                    } catch (Exception e) {
                        echo "❌ Erreur Docker : ${e.getMessage()}"
                        throw e
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 6 : ANALYSE TRIVY      */
        /* ---------------------------- */
        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    try {
                        sh """
                            curl -sLO ${env.TRIVY_TEMPLATE_URL}
                            mv advanced-html.tpl html.tpl
                            trivy image --download-db-only
                            
                            trivy image \
                                --severity HIGH,CRITICAL \
                                --ignore-unfixed \
                                --format template \
                                --template '@html.tpl' \
                                -o trivy-report.html \
                                dalifer/springfoyer:latest
                        """

                        publishHTML([
                            allowMissing: true,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'trivy-report.html',
                            reportName: 'Rapport Trivy'
                        ])
                    } catch (Exception e) {
                        echo "⚠️ Erreur Trivy : ${e.getMessage()}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🧹 Nettoyage post-build..."
                sh 'docker system prune -f || true'
                sh 'rm -f html.tpl trivy-report.* || true'
                
                // Rapport final
                def duration = currentBuild.durationString.replace(' and counting', '')
                echo "📊 Résultat final: ${currentBuild.currentResult}"
                echo "⏱️ Durée totale: ${duration}"
            }
        }
        
        success {
            echo "✅ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} réussi"
            echo "📦 Artifact: dalifer/springfoyer:${env.BUILD_NUMBER}"
            echo "🔗 ${env.BUILD_URL}"
        }
        
        failure {
            echo "❌ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} échoué"
            echo "🔗 ${env.BUILD_URL}"
            echo "💡 Cause: ${currentBuild.result}"
        }
    }
}














