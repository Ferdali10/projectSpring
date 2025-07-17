@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        SONAR_PROJECT_KEY = 'springfoyer'
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
    }

    stages {
        stage('🔧 Préparation') {
            steps {
                script {
                    cleanWs()
                    
                    // Clone avec permissions explicites
                    sh '''
                        git config --global --add safe.directory '*'
                        git clone --depth 1 -b master \
                        https://github.com/Ferdali10/projectSpring.git .
                    '''
                    
                    // Donner les permissions à mvnw
                    sh 'chmod +x mvnw'
                }
            }
        }

        stage('🛠️ Build Maven') {
            steps {
                script {
                    try {
                        // Build avec output détaillé
                        sh '''
                            ./mvnw clean package \
                            -DskipTests \
                            -Dspring.profiles.active=prod \
                            -B -V -e | tee maven.log
                        '''
                        
                        // Vérification du JAR
                        if (!fileExists('target/springFoyer-0.0.2-SNAPSHOT.jar')) {
                            error 'Fichier JAR introuvable'
                        }
                    } catch (e) {
                        archiveArtifacts artifacts: 'maven.log,**/target/surefire-reports/**', fingerprint: true
                        error "Échec du build Maven: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('📊 Analyse SonarQube') {
            steps {
                script {
                    withSonarQubeEnv('SonanQubeServer') {
                        withCredentials([string(credentialsId: 'jenkins-key', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                ./mvnw sonar:sonar \
                                -Dsonar.login=$SONAR_TOKEN \
                                -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                                -Dsonar.sources=src/main/java \
                                -Dsonar.tests=src/test/java \
                                -Dsonar.java.binaries=target/classes
                            '''
                        }
                    }
                }
            }
        }

        stage('🐳 Build Docker') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                        def image = docker.build(
                            "dalifer/springfoyer:${env.BUILD_NUMBER}", 
                            "--build-arg JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar ."
                        )
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    sh '''
                        curl -sLO $TRIVY_TEMPLATE_URL || true
                        [ -f advanced-html.tpl ] && mv advanced-html.tpl html.tpl
                        
                        trivy image --download-db-only
                        trivy image \
                            --scanners vuln \
                            --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --format template \
                            --template '@html.tpl' \
                            -o trivy-report.html \
                            dalifer/springfoyer:latest || true
                    '''
                    publishHTML([
                        allowMissing: true,
                        reportDir: '.',
                        reportFiles: 'trivy-report.html',
                        reportName: 'Rapport Trivy'
                    ])
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
            sh 'rm -f html.tpl trivy-report.* || true'
        }
        failure {
            archiveArtifacts artifacts: '**/target/*.log,**/surefire-reports/**', fingerprint: true
        }
    }
}







