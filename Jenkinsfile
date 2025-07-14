@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
    }

    stages {
        stage('🔁 Clone du dépôt') {
            steps {
                script {
                    // Clone du repository
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )
                }
            }
        }

        stage('🏗 Build Spring Boot + MySQL') {
            steps {
                script {
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
                    }
                }
            }
        }

        stage('🐳 Build/Push Docker') {
            steps {
                script {
                    // Vérification du JAR avant build Docker
                    def jarFileName = "springFoyer-0.0.2-SNAPSHOT.jar"
                    def jarPath = "target/${jarFileName}"

                    echo "Vérification du fichier JAR : ${jarPath}"
                    def jarExists = sh(
                        script: "test -f ${jarPath} && echo 'EXISTS' || echo 'NOT_FOUND'",
                        returnStdout: true
                    ).trim()

                    if (jarExists == 'NOT_FOUND') {
                        sh 'echo "=== Contenu du répertoire target ==="'
                        sh 'ls -la target/ || echo "Répertoire target introuvable"'
                        error "❌ Le fichier JAR ${jarPath} est introuvable."
                    } else {
                        echo "✅ Fichier JAR trouvé : ${jarPath}"

                        // Build + push image Docker
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
