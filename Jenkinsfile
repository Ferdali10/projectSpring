pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'dalifer'
        IMAGE_NAME = "dalifer/springfoyer"
    }

    tools {
        maven 'Maven 3.9.6'
        jdk 'jdk17'
    }

    stages {

        stage('📦 Cloner le projet') {
            steps {
                git url: 'https://github.com/ton-utilisateur/springFoyer.git', branch: 'main'
            }
        }

        stage('🔨 Maven Build') {
            steps {
                sh './mvnw clean install -DskipTests'
            }
        }

        stage('🧪 Analyse SonarQube') {
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            ./mvnw verify sonar:sonar \
                            -Dsonar.login=$SONAR_TOKEN \
                            -Dsonar.projectKey=springfoyer \
                            -Dsonar.projectName="springFoyer" \
                            -Dsonar.sources=src/main/java \
                            -Dsonar.tests=src/test/java \
                            -Dsonar.java.binaries=target/classes
                        '''
                    }
                }
            }
        }

        stage('🐳 Docker Build') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${env.BUILD_NUMBER}")
                }
            }
        }

        stage('📤 Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker tag ${IMAGE_NAME}:${env.BUILD_NUMBER} ${IMAGE_NAME}:latest
                        docker push ${IMAGE_NAME}:${env.BUILD_NUMBER}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }

    }

    post {
        success {
            echo '✅ Pipeline terminée avec succès.'
        }
        failure {
            echo '❌ La pipeline a échoué.'
        }
    }
}







