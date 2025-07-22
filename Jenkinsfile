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
        SONAR_HOST_URL = 'http://localhost:9000'
    }

    stages {
        stage('🚀 Build et Déploiement Complet') {
            steps {
                script {
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat",
                        depth: 50
                    )

                    withEnv([
                        "SPRING_DATASOURCE_URL=${env.DB_URL}",
                        "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                        "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                    ]) {
                        stage('🛠️ Build Maven') {
                            sh """
                                mvn clean package \
                                -DskipTests \
                                -Dspring.profiles.active=prod \
                                -B -V -e
                            """
                        }

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
                                        -Dsonar.java.libraries=target/*.jar \
                                        -Dsonar.scm.provider=git \
                                        -Dsonar.scm.disabled=false
                                    """
                                }
                            }
                        }

                        stage('🛂 Vérification Quality Gate') {
                            timeout(time: 30, unit: 'MINUTES') {
                                def qg = waitForQualityGate()
                                if (qg.status != 'OK') {
                                    error "Quality Gate échouée : ${qg.status}"
                                }
                            }
                        }

                        def jarFile = findFiles(glob: 'target/*.jar')[0]?.name
                        if (!jarFile) {
                            error "❌ Aucun fichier JAR trouvé dans target/"
                        }

                        docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                            def image = docker.build("dalifer/springfoyer:${env.BUILD_NUMBER}", ".")
                            image.push()
                            image.push('latest')
                        }
                    }
                }
            }
        }

        stage('🔍 Analyse Trivy') {
            steps {
                script {
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
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
            sh 'rm -f html.tpl trivy-report.* || true'
            
            script {
                def duration = currentBuild.durationString.replace(' and counting', '')
                echo "📊 Résultat final: ${currentBuild.currentResult}"
                echo "⏱️ Durée totale: ${duration}"
                
                if (currentBuild.currentResult == 'SUCCESS') {
                    echo "🎉 Pipeline réussi - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                } else {
                    echo "❌ Pipeline échoué - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                }
            }
        }
    }
}
