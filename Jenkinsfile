@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        SONAR_PROJECT_KEY = 'springfoyer'
    }

    stages {
        stage('🚀 Build et Déploiement') {
            steps {
                script {
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )

                    // Build Maven optimisé
                    withEnv(["MAVEN_OPTS=-Dmaven.wagon.http.retryHandler.count=5 -Dmaven.wagon.http.timeout=300000"]) {
                        buildProject(
                            buildTool: 'maven',
                            args: "-DskipTests -Dspring.profiles.active=prod"
                        )
                    }

                    // Construction Docker
                    dockerBuildFullImage(
                        imageName: "dalifer/springfoyer",
                        tags: ["latest", "${env.BUILD_NUMBER}"],
                        buildArgs: "--build-arg JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar",
                        credentialsId: "docker-hub-creds"
                    )
                }
            }
        }

        stage('📊 Analyse SonarQube') {
            when {
                expression { env.SONAR_TOKEN != null }
            }
            steps {
                script {
                    withSonarQubeEnv('SonarQubeServer') {
                        sh """
                            ./mvnw sonar:sonar \
                            -Dsonar.login=${env.SONAR_TOKEN} \
                            -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                            -Dsonar.sources=src/main/java \
                            -Dsonar.tests=src/test/java
                        """
                    }
                }
            }
        }

        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    def imageName = "dalifer/springfoyer:latest"
                    
                    // Téléchargement template
                    sh """
                        curl -sLO ${env.TRIVY_TEMPLATE_URL} || true
                        [ -f advanced-html.tpl ] && mv advanced-html.tpl html.tpl
                    """

                    // Analyse
                    sh """
                        trivy image --security-checks vuln \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --format template \
                        --template '@html.tpl' \
                        -o trivy-report.html \
                        ${imageName} || true
                    """

                    // Publication rapport
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
    }
}







