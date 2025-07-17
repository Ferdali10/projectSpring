@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    environment {
        // Configurations de base
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        
        // Configuration SonarQube
        SONAR_PROJECT_KEY = 'springfoyer'
        SONAR_PROJECT_NAME = 'springFoyer'
        
        // Configuration Trivy
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        
        // Optimisation Maven
        MAVEN_OPTS = '-Dmaven.wagon.http.retryHandler.count=5 -Dmaven.wagon.http.connectionTimeout=300000 -Dmaven.wagon.http.readTimeout=300000'
    }

    stages {
        /* ---------------------------- */
        /* ÉTAPE 1 : PRÉPARATION */
        /* ---------------------------- */
        stage('🔧 Préparation') {
            steps {
                script {
                    cleanWs()
                    cloneRepo(
                        repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                        branch: "master",
                        credentialsId: "github-pat"
                    )
                    
                    // Vérification et correction des permissions
                    sh """
                        echo "Vérification des permissions..."
                        ls -la ./mvnw || echo "mvnw non trouvé"
                        
                        # Correction des permissions pour mvnw
                        if [ -f ./mvnw ]; then
                            chmod +x ./mvnw
                            echo "Permissions corrigées pour mvnw"
                        else
                            echo "Fichier mvnw non trouvé, utilisation de maven système"
                        fi
                        
                        # Vérification de l'environnement
                        java -version
                        echo "JAVA_HOME: $JAVA_HOME"
                        echo "PATH: $PATH"
                    """
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 2 : BUILD MAVEN */
        /* ---------------------------- */
        stage('🛠️ Build Maven') {
            steps {
                script {
                    try {
                        // Utilisation de Maven avec fallback
                        sh """
                            # Tentative avec mvnw en premier
                            if [ -f ./mvnw ] && [ -x ./mvnw ]; then
                                echo "Utilisation de Maven Wrapper"
                                ./mvnw clean package \\
                                -DskipTests \\
                                -Dspring.profiles.active=prod \\
                                -B -V -e
                            else
                                echo "Utilisation de Maven système"
                                mvn clean package \\
                                -DskipTests \\
                                -Dspring.profiles.active=prod \\
                                -B -V -e
                            fi
                        """
                        
                        // Vérification du JAR généré
                        sh """
                            echo "Vérification du build..."
                            ls -la target/
                            
                            # Recherche du JAR généré
                            JAR_FILE=\$(find target -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" | head -1)
                            if [ -z "\$JAR_FILE" ]; then
                                echo "❌ Aucun fichier JAR trouvé dans target/"
                                exit 1
                            else
                                echo "✅ JAR trouvé : \$JAR_FILE"
                                # Création d'un lien symbolique pour simplifier la référence
                                ln -sf \$JAR_FILE target/app.jar
                            fi
                        """
                        
                    } catch (Exception e) {
                        echo "❌ Erreur lors du build Maven : ${e.getMessage()}"
                        // Archivage des logs pour debug
                        sh """
                            echo "Collecte des logs de debug..."
                            find . -name "*.log" -type f -exec ls -la {} \\;
                            find . -name "surefire-reports" -type d -exec ls -la {} \\;
                        """
                        archiveArtifacts artifacts: '**/target/*.log,**/target/surefire-reports/*', allowEmptyArchive: true
                        throw e
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 3 : ANALYSE SONARQUBE */
        /* ---------------------------- */
        stage('📊 Analyse SonarQube') {
            steps {
                script {
                    try {
                        withSonarQubeEnv('SonanQubeServer') {
                            withCredentials([string(credentialsId: 'jenkins-key', variable: 'SONAR_TOKEN')]) {
                                sh """
                                    # Utilisation de Maven avec fallback
                                    if [ -f ./mvnw ] && [ -x ./mvnw ]; then
                                        ./mvnw sonar:sonar \\
                                        -Dsonar.login=\$SONAR_TOKEN \\
                                        -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \\
                                        -Dsonar.projectName="${env.SONAR_PROJECT_NAME}" \\
                                        -Dsonar.sources=src/main/java \\
                                        -Dsonar.tests=src/test/java \\
                                        -Dsonar.java.binaries=target/classes \\
                                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                                    else
                                        mvn sonar:sonar \\
                                        -Dsonar.login=\$SONAR_TOKEN \\
                                        -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \\
                                        -Dsonar.projectName="${env.SONAR_PROJECT_NAME}" \\
                                        -Dsonar.sources=src/main/java \\
                                        -Dsonar.tests=src/test/java \\
                                        -Dsonar.java.binaries=target/classes \\
                                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                                    fi
                                """
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠️ Erreur SonarQube : ${e.getMessage()}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 4 : QUALITY GATE */
        /* ---------------------------- */
        stage('🛂 Vérification Quality Gate') {
            steps {
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                echo "⚠️ Quality Gate échouée : ${qg.status}"
                                currentBuild.result = 'UNSTABLE'
                            } else {
                                echo "✅ Quality Gate réussie"
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠️ Erreur Quality Gate : ${e.getMessage()}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 5 : BUILD DOCKER */
        /* ---------------------------- */
        stage('🐳 Build Docker') {
            steps {
                script {
                    try {
                        // Vérification du Dockerfile
                        sh """
                            if [ ! -f Dockerfile ]; then
                                echo "❌ Dockerfile non trouvé"
                                exit 1
                            fi
                            
                            # Vérification du JAR
                            if [ ! -f target/app.jar ]; then
                                echo "❌ JAR non trouvé"
                                exit 1
                            fi
                            
                            echo "✅ Prérequis Docker OK"
                        """
                        
                        docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                            def image = docker.build("dalifer/springfoyer:${env.BUILD_NUMBER}", ".")
                            image.push()
                            image.push('latest')
                            
                            echo "✅ Image Docker publiée : dalifer/springfoyer:${env.BUILD_NUMBER}"
                        }
                    } catch (Exception e) {
                        echo "❌ Erreur lors du build Docker : ${e.getMessage()}"
                        throw e
                    }
                }
            }
        }

        /* ---------------------------- */
        /* ÉTAPE 6 : ANALYSE TRIVY */
        /* ---------------------------- */
        stage('🔍 Analyse Trivy') {
            steps {
                script {
                    try {
                        // Téléchargement DB et template
                        sh """
                            echo "Préparation de l'analyse Trivy..."
                            
                            # Téléchargement de la base de données Trivy
                            trivy image --download-db-only
                            
                            # Téléchargement du template
                            curl -sLO ${env.TRIVY_TEMPLATE_URL} || echo "Template non disponible"
                            
                            # Renommage du template si disponible
                            if [ -f advanced-html.tpl ]; then
                                mv advanced-html.tpl html.tpl
                                echo "Template HTML configuré"
                            else
                                echo "Utilisation du template par défaut"
                            fi
                        """

                        // Analyse de sécurité
                        sh """
                            echo "Analyse de sécurité avec Trivy..."
                            
                            # Analyse avec gestion d'erreur
                            trivy image \\
                            --scanners vuln \\
                            --severity HIGH,CRITICAL \\
                            --ignore-unfixed \\
                            --format template \\
                            --template '@html.tpl' \\
                            -o trivy-report.html \\
                            dalifer/springfoyer:latest || echo "Analyse Trivy terminée avec des avertissements"
                            
                            # Vérification du rapport
                            if [ -f trivy-report.html ]; then
                                echo "✅ Rapport Trivy généré"
                            else
                                echo "⚠️ Rapport Trivy non généré"
                            fi
                        """

                        // Publication du rapport
                        publishHTML([
                            allowMissing: true,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'trivy-report.html',
                            reportName: 'Rapport Trivy',
                            reportTitles: 'Analyse de Sécurité'
                        ])
                        
                    } catch (Exception e) {
                        echo "⚠️ Erreur lors de l'analyse Trivy : ${e.getMessage()}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🧹 Nettoyage post-build..."
                
                // Nettoyage Docker
                sh """
                    echo "Nettoyage Docker..."
                    docker system prune -f || echo "Erreur lors du nettoyage Docker"
                """
                
                // Nettoyage des fichiers temporaires
                sh """
                    echo "Nettoyage des fichiers temporaires..."
                    rm -f html.tpl trivy-report.* || echo "Fichiers temporaires déjà supprimés"
                """
                
                // Affichage du statut
                def buildStatus = currentBuild.currentResult
                echo "📊 Statut final du build : ${buildStatus}"
                
                // Informations sur l'espace disque
                sh """
                    echo "Informations système :"
                    df -h . || echo "Impossible d'afficher l'espace disque"
                """
            }
        }
        
        success {
            script {
                echo "🎉 Pipeline réussi avec succès !"
                echo "✅ Build ${env.JOB_NAME} #${env.BUILD_NUMBER} terminé"
                
                // Informations sur les artefacts
                sh """
                    echo "Artefacts générés :"
                    ls -la target/*.jar || echo "Aucun JAR trouvé"
                    docker images | grep dalifer/springfoyer || echo "Aucune image Docker trouvée"
                """
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline échoué"
                echo "🔍 Build ${env.JOB_NAME} #${env.BUILD_NUMBER} a échoué"
                
                // Archivage des logs pour debug
                archiveArtifacts artifacts: '**/target/*.log,**/target/surefire-reports/*,**/logs/*', allowEmptyArchive: true
                
                // Informations de debug
                sh """
                    echo "Informations de debug :"
                    pwd
                    ls -la
                    ls -la target/ || echo "Répertoire target non trouvé"
                """
            }
        }
        
        unstable {
            script {
                echo "⚠️ Pipeline instable"
                echo "🔧 Build ${env.JOB_NAME} #${env.BUILD_NUMBER} terminé avec des avertissements"
                
                // Archivage des logs
                archiveArtifacts artifacts: '**/target/*.log,**/target/surefire-reports/*', allowEmptyArchive: true
            }
        }
    }
}







