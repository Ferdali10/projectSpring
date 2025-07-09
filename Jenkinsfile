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
                    // Cloner le dépôt
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )

                    // Injecter variables dans l'environnement Maven/Spring
                    withEnv([
                        "SPRING_DATASOURCE_URL=${env.DB_URL}",
                        "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                        "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                    ]) {
                        // Build Maven
                        buildProject(
                            buildTool: 'maven',
                            args: "-Dspring.profiles.active=prod"
                        )
                    }

                    // Récupérer dynamiquement le .jar généré
                    def jarFile = sh(script: "ls target/*.jar", returnStdout: true).trim()
                    echo "Le fichier JAR généré est : ${jarFile}"

                    // Build et push Docker avec le .jar exact
                    dockerBuildFullImage(
                        imageName: "dalifer/springfoyer",
                        tags: ["latest", "${env.BUILD_NUMBER}"],
                        buildArgs: "--build-arg JAR_FILE=${jarFile}"
                    )
                }
            }
        }
    }
}



