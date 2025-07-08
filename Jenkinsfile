@Library('dig-apps-shared-lib') _

pipeline {
    agent any
    environment {
        DB_URL = 'jdbc:mysql://mysql-service:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
    }
    stages {
        stage('Build et Déploiement') {
            steps {
                script {
                    // 1. Clone (optionnel si Jenkins fait déjà le checkout)
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/springFoyer.git",
                        branch: "master"
                    )

                    // 2. Build avec Maven
                    buildProject(
                        buildTool: 'maven',
                        args: "-Pprod -Dspring.profiles.active=prod"
                    )

                    // 3. Build et Push Docker
                    dockerBuildFullImage(
                        imageName: "votredockerhub/springfoyer",
                        tags: ["latest", "${env.BUILD_NUMBER}"],
                        buildArgs: "--build-arg JAR_FILE=target/*.jar"
                    )
                }
            }
        }
    }
}
