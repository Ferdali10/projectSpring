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

                    // 💥 Ajout de debug pour afficher le contenu de target/
                    sh 'pwd'
                    sh 'ls -la target'

                    // Récupération du jar
                    def jarPath = sh(script: 'ls target/*.jar | head -n 1', returnStdout: true).trim()
                    echo "Chemin du JAR généré : ${jarPath}"

                    // Vérification avec shell
                    def exists = sh(script: "[ -f '${jarPath}' ] && echo exists || echo missing", returnStdout: true).trim()
                    if (exists != "exists") {
                        error "Le fichier JAR ${jarPath} est introuvable (vérifié par shell)"
                    }

                    // Nom du jar
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




