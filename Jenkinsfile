@Library('dig-apps-shared-lib') _

pipeline {
    agent any
    options {
        skipDefaultCheckout true  // Désactive le checkout SCM automatique
    }

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
    }

    stages {
        stage('🔁 1. Récupération du code') {
            steps {
                script {
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )
                }
            }
        }

        stage('🏗 2. Compilation et packaging') {
            steps {
                script {
                    withEnv([
                        "SPRING_DATASOURCE_URL=${env.DB_URL}",
                        "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                        "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                    ]) {
                        buildProject(
                            buildTool: 'maven',
                            args: "-DskipTests -Dspring.profiles.active=prod"
                        )

                        // Vérification du JAR
                        def jarFileName = "springFoyer-0.0.2-SNAPSHOT.jar"
                        def jarPath = "target/${jarFileName}"
                        
                        if (!fileExists(jarPath)) {
                            sh 'ls -la target/ || echo "Répertoire target introuvable"'
                            error "❌ Fichier JAR ${jarPath} introuvable"
                        }
                        echo "✅ JAR généré : ${jarPath}"
                    }
                }
            }
        }

        stage('🐳 3. Construction et déploiement Docker') {
            steps {
                script {
                    dockerBuildFullImage(
                        imageName: "dalifer/springfoyer",
                        tags: ["latest", "${env.BUILD_NUMBER}"],
                        buildArgs: "--build-arg JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar",
                        credentialsId: "docker-hub-creds"
                    )
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
            archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
        }
        failure {
            echo "❌ Échec du pipeline - Consultez les logs"
        }
    }
}









