@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
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

                    withCredentials([
                        usernamePassword(credentialsId: 'mysql-credentials-id', usernameVariable: 'DB_USER', passwordVariable: 'DB_PASSWORD')
                    ]) {
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

                        // Récupérer juste le nom du jar (sans dossier)
                        def jarFile = sh(script: "basename $(ls target/*.jar | head -n 1)", returnStdout: true).trim()
                        echo "Fichier JAR généré : ${jarFile}"

                        if (!fileExists("target/${jarFile}")) {
                            error "Le fichier JAR target/${jarFile} est introuvable"
                        }

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
}
