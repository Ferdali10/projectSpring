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
                        buildProject(
                            buildTool: 'maven',
                            args: "-Dspring.profiles.active=prod"
                        )
                    }

                    // Récupérer le chemin complet du jar
                    def jarPath = sh(script: 'ls target/*.jar | head -n 1', returnStdout: true).trim()
                    echo "Chemin du JAR généré : ${jarPath}"

                    // Vérifier que le fichier existe
                    if (!fileExists(jarPath)) {
                        error "Le fichier JAR ${jarPath} est introuvable"
                    }

                    // Extraire juste le nom du fichier
                    def jarFileName = jarPath.tokenize('/').last()
                    echo "Nom du JAR à injecter dans Docker : ${jarFileName}"

                    dockerBuildFullImage(
                        imageName: "dalifer/springfoyer",
                        tags: ["latest", "${env.BUILD_NUMBER}"],
                        buildArgs: "--build-arg JAR_FILE=${jarFileName}"
                    )
                }
            }
        }
    }
}


