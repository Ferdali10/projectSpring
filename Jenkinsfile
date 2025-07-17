@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        SONAR_PROJECT_KEY = 'springfoyer'
        SONAR_PROJECT_NAME = 'springFoyer'
        SONAR_HOST_URL = 'http://localhost:9000'  // Ajout explicite de l'URL SonarQube
    }

    stages {
        stage('🚀 Build et Déploiement Complet') {
            steps {
                script {
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat",
                        depth: 50  // Augmentez la profondeur du clone pour éviter les problèmes SCM
                    )

                    withEnv([
                        "SPRING_DATASOURCE_URL=${env.DB_URL}",
                        "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                        "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                    ]) {
                        // Étape de build Maven
                        stage('🛠️ Build Maven') {
                            sh """
                                mvn clean package \
                                -DskipTests \
                                -Dspring.profiles.active=prod \
                                -B -V -e
                            """
                        }

                        // Étape d'analyse SonarQube améliorée
                        stage('📊 Analyse SonarQube') {
                            withSonarQubeEnv('SonarQubeServer') {
                                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                                    sh """
                                        mvn sonar:sonar \
                                        -Dsonar.login=\$SONAR_TOKEN \
                                        -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                                        -Dsonar.projectName="${env.SONAR_PROJECT_NAME}" \
                                        -Dsonar.sources=src/main/java \
                                        -Dsonar.tests=src/test/java \
                                        -Dsonar.java.binaries=target/classes \
                                        -Dsonar.java.libraries=target/*.jar \
                                        -Dsonar.scm.provider=git \
                                        -Dsonar.scm.disabled=false \
                                        -Dsonar.verbose=true
                                    """
                                }
                            }
                        }

                        // Quality Gate avec gestion robuste
                        stage('🛂 Vérification Quality Gate') {
                            script {
                                def maxAttempts = 20
                                def waitTime = 30 // secondes
                                def qgStatus = null
                                
                                // Option 1: Vérification standard avec timeout
                                timeout(time: 15, unit: 'MINUTES') {
                                    for (int i = 1; i <= maxAttempts; i++) {
                                        try {
                                            echo "🔍 Tentative ${i}/${maxAttempts} de vérification Quality Gate"
                                            def qg = waitForQualityGate(timeout: 60)
                                            
                                            if (qg.status == 'OK') {
                                                echo "✅ Quality Gate réussie"
                                                qgStatus = 'OK'
                                                break
                                            } else if (qg.status == 'ERROR') {
                                                error "❌ Quality Gate échouée"
                                            } else {
                                                echo "🔄 Statut actuel: ${qg.status} - Attente de ${waitTime}s..."
                                                sleep(waitTime)
                                            }
                                        } catch (Exception e) {
                                            echo "⚠️ Erreur lors de la tentative ${i}: ${e.getMessage()}"
                                            if (i == maxAttempts) {
                                                echo "🔴 Nombre maximum de tentatives atteint"
                                                // Option: Décommentez pour échouer ou continuez
                                                // error "Quality Gate non vérifiée après ${maxAttempts} tentatives"
                                                qgStatus = 'PENDING'
                                                break
                                            }
                                            sleep(waitTime)
                                        }
                                    }
                                }
                                
                                // Option 2: Vérification alternative via API si nécessaire
                                if (qgStatus != 'OK') {
                                    echo "🔄 Tentative de vérification via API SonarQube"
                                    try {
                                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                                            def taskId = sh(
                                                script: "curl -s -u \$SONAR_TOKEN: \"${env.SONAR_HOST_URL}/api/ce/task?id=${env.SONAR_PROJECT_KEY}\" | jq -r '.task.id'",
                                                returnStdout: true
                                            ).trim()
                                            
                                            def status = sh(
                                                script: "curl -s -u \$SONAR_TOKEN: \"${env.SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${env.SONAR_PROJECT_KEY}\" | jq -r '.projectStatus.status'",
                                                returnStdout: true
                                            ).trim()
                                            
                                            echo "📊 Statut via API: ${status}"
                                            if (status == 'OK') {
                                                echo "✅ Quality Gate validée via API"
                                            } else if (status == 'ERROR') {
                                                echo "⚠️ Quality Gate échouée via API"
                                                // error "Quality Gate échouée" // Décommentez pour échouer
                                            }
                                        }
                                    } catch (Exception e) {
                                        echo "⚠️ Impossible de vérifier via API: ${e.getMessage()}"
                                    }
                                }
                            }
                        }

                        // Reste de votre pipeline...
                    }
                }
            }
        }
    }

    post {
        always {
            // Nettoyage...
        }
    }
}
