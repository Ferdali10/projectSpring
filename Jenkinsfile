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

                    // 📁 On entre dans le dossier cloné
                    dir('projectSpring') {
                        withEnv([
                            "SPRING_DATASOURCE_URL=${env.DB_URL}",
                            "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                            "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                        ]) {
                            buildProject(
                                buildTool: 'maven',
                                args: "-DskipTests -Dspring.profiles.active=prod"
                            )
                        }

                        def jarFileName = "springFoyer-0.0.2-SNAPSHOT.jar"
                        def jarPath = "target/${jarFileName}"

                        echo "Fichier JAR généré : ${jarPath}"

                        if (!fileExists(jarPath)) {
                            error "❌ Le fichier JAR ${jarPath} est introuvable."
                        }

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
}






