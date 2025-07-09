@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
    }

    stages {
        stage('Build et Déploiement') {
            steps {
                script {
                    // ✅ Correction ici : URL du bon dépôt
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )

                    // 2. Build avec Maven
                    buildProject(
                        buildTool: 'maven',
                        args: "-Pprod -Dspring.profiles.active=prod"
                    )

                    // 3. Build et Push Docker
                    dockerBuildFullImage(
                        imageName: "dalifer/springfoyer",
                        tags: ["latest", "${env.BUILD_NUMBER}"],
                        buildArgs: "--build-arg JAR_FILE=target/*.jar"
                    )
                }
            }
        }
    }
}
