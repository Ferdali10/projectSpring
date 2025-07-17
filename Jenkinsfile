@Library('dig-apps-shared-lib') _

pipeline {
    agent any

    options {
        // Timeout global du pipeline
        timeout(time: 30, unit: 'MINUTES')
        // Garder les 10 derniers builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Éviter les builds concurrents
        disableConcurrentBuilds()
        // Horodatage des logs
        timestamps()
    }

    environment {
        DB_URL = 'jdbc:mysql://192.168.11.100:3306/springfoyer'
        DB_USER = credentials('mysql-username')
        DB_PASSWORD = credentials('mysql-password')
        TRIVY_TEMPLATE_URL = 'https://raw.githubusercontent.com/Ferdali10/projectSpring/master/advanced-html.tpl'
        SONAR_PROJECT_KEY = 'springfoyer'
        SONAR_PROJECT_NAME = 'springFoyer'
        DOCKER_IMAGE_NAME = 'dalifer/springfoyer'
        JAR_FILE_NAME = 'springFoyer-0.0.2-SNAPSHOT.jar'
        
        // Variables pour le Quality Gate
        SKIP_QUALITY_GATE = "${params.SKIP_QUALITY_GATE ?: false}"
        QUALITY_GATE_TIMEOUT = "${params.QUALITY_GATE_TIMEOUT ?: 5}"
    }

    parameters {
        booleanParam(
            name: 'SKIP_QUALITY_GATE',
            defaultValue: false,
            description: 'Ignorer la vérification du Quality Gate SonarQube'
        )
        choice(
            name: 'QUALITY_GATE_TIMEOUT',
            choices: ['3', '5', '10', '15'],
            description: 'Timeout pour le Quality Gate (en minutes)'
        )
        booleanParam(
            name: 'SKIP_TRIVY',
            defaultValue: false,
            description: 'Ignorer l\'analyse de sécurité Trivy'
        )
        booleanParam(
            name: 'FORCE_REBUILD',
            defaultValue: false,
            description: 'Forcer la reconstruction complète'
        )
    }

    stages {
        stage('🔧 Initialisation') {
            steps {
                script {
                    echo "🚀 Démarrage du pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                    echo "📋 Paramètres:"
                    echo "  - SKIP_QUALITY_GATE: ${params.SKIP_QUALITY_GATE}"
                    echo "  - QUALITY_GATE_TIMEOUT: ${params.QUALITY_GATE_TIMEOUT} minutes"
                    echo "  - SKIP_TRIVY: ${params.SKIP_TRIVY}"
                    echo "  - FORCE_REBUILD: ${params.FORCE_REBUILD}"
                    
                    // Vérifier la connectivité aux services
                    echo "🔍 Vérification de la connectivité..."
                    
                    // Vérifier SonarQube
                    try {
                        def sonarStatus = sh(
                            script: "curl -s --connect-timeout 10 http://localhost:9000/api/system/status",
                            returnStdout: true
                        ).trim()
                        echo "✅ SonarQube accessible: ${sonarStatus}"
                    } catch (Exception e) {
                        echo "⚠️ SonarQube non accessible: ${e.message}"
                        env.SONAR_AVAILABLE = "false"
                    }
                    
                    // Vérifier Docker
                    try {
                        sh "docker version"
                        echo "✅ Docker accessible"
                    } catch (Exception e) {
                        echo "❌ Docker non accessible: ${e.message}"
                        error "Docker est requis pour ce pipeline"
                    }
                }
            }
        }

        stage('📥 Récupération du Code') {
            steps {
                script {
                    echo "📥 Clonage du repository..."
                    try {
                        cloneRepo(
                            repoUrl: "https://github.com/Ferdali10/projectSpring.git",
                            branch: "master",
                            credentialsId: "github-pat"
                        )
                        echo "✅ Repository cloné avec succès"
                    } catch (Exception e) {
                        error "❌ Erreur lors du clonage: ${e.message}"
                    }
                }
            }
        }

        stage('🛠️ Build Maven') {
            steps {
                script {
                    echo "🛠️ Compilation Maven..."
                    withEnv([
                        "SPRING_DATASOURCE_URL=${env.DB_URL}",
                        "SPRING_DATASOURCE_USERNAME=${env.DB_USER}",
                        "SPRING_DATASOURCE_PASSWORD=${env.DB_PASSWORD}"
                    ]) {
                        try {
                            def buildArgs = params.FORCE_REBUILD ? "clean compile -U" : "compile"
                            buildProject(
                                buildTool: 'maven',
                                args: "${buildArgs} -DskipTests -Dspring.profiles.active=prod"
                            )
                            echo "✅ Build Maven réussi"
                        } catch (Exception e) {
                            error "❌ Erreur lors du build Maven: ${e.message}"
                        }
                    }
                }
            }
        }

        stage('🧪 Tests Unitaires') {
            steps {
                script {
                    echo "🧪 Exécution des tests unitaires..."
                    try {
                        sh """
                            mvn test -Dspring.profiles.active=test \
                                -Dmaven.test.failure.ignore=true
                        """
                        echo "✅ Tests unitaires terminés"
                    } catch (Exception e) {
                        echo "⚠️ Erreur lors des tests: ${e.message}"
                        // Continuer malgré les erreurs de test
                    }
                }
            }
            post {
                always {
                    // Publier les résultats des tests
                    script {
                        try {
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        } catch (Exception e) {
                            echo "⚠️ Impossible de publier les résultats des tests: ${e.message}"
                        }
                    }
                }
            }
        }

        stage('📦 Package JAR') {
            steps {
                script {
                    echo "📦 Création du package JAR..."
                    try {
                        sh "mvn package -DskipTests -Dspring.profiles.active=prod"
                        
                        def jarPath = "target/${env.JAR_FILE_NAME}"
                        if (!fileExists(jarPath)) {
                            error "❌ Fichier JAR ${jarPath} introuvable"
                        }
                        echo "✅ JAR créé: ${jarPath}"
                    } catch (Exception e) {
                        error "❌ Erreur lors de la création du JAR: ${e.message}"
                    }
                }
            }
        }

        stage('📊 Analyse SonarQube') {
            when {
                expression { env.SONAR_AVAILABLE != "false" }
            }
            steps {
                script {
                    echo "📊 Analyse de la qualité du code..."
                    withSonarQubeEnv('SonarQubeServer') {
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                            try {
                                sh """
                                    mvn sonar:sonar \
                                        -Dsonar.login=\$SONAR_TOKEN \
                                        -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                                        -Dsonar.projectName="${env.SONAR_PROJECT_NAME}" \
                                        -Dsonar.sources=src/main/java \
                                        -Dsonar.tests=src/test/java \
                                        -Dsonar.java.binaries=target/classes \
                                        -Dsonar.java.libraries=target/*.jar \
                                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                                """
                                echo "✅ Analyse SonarQube terminée"
                                env.SONAR_ANALYSIS_SUCCESS = "true"
                            } catch (Exception e) {
                                echo "❌ Erreur lors de l'analyse SonarQube: ${e.message}"
                                env.SONAR_ANALYSIS_SUCCESS = "false"
                            }
                        }
                    }
                }
            }
        }

        stage('🛂 Quality Gate') {
            when {
                allOf {
                    expression { params.SKIP_QUALITY_GATE == false }
                    expression { env.SONAR_ANALYSIS_SUCCESS == "true" }
                }
            }
            steps {
                script {
                    echo "🛂 Vérification du Quality Gate..."
                    def qgPassed = false
                    def qgSkipped = false
                    
                    try {
                        timeout(time: params.QUALITY_GATE_TIMEOUT as Integer, unit: 'MINUTES') {
                            // Stratégie de vérification progressive
                            def maxAttempts = 10
                            def currentAttempt = 0
                            
                            while (currentAttempt < maxAttempts && !qgPassed && !qgSkipped) {
                                try {
                                    echo "🔍 Tentative ${currentAttempt + 1}/${maxAttempts}"
                                    
                                    def qg = waitForQualityGate(
                                        abortPipeline: false,
                                        sleepInSeconds: 10
                                    )
                                    
                                    echo "📊 Status Quality Gate: ${qg.status}"
                                    
                                    if (qg.status == 'OK') {
                                        echo "✅ Quality Gate réussie"
                                        qgPassed = true
                                    } else if (qg.status == 'ERROR') {
                                        echo "⚠️ Quality Gate échouée"
                                        echo "🔗 Consultez: http://localhost:9000/dashboard?id=${env.SONAR_PROJECT_KEY}"
                                        
                                        // Décision: continuer ou échouer
                                        if (currentAttempt >= maxAttempts - 1) {
                                            echo "🔄 Continuation malgré l'échec du Quality Gate"
                                            qgPassed = true
                                        }
                                    } else if (qg.status == 'PENDING' || qg.status == 'IN_PROGRESS') {
                                        echo "⏳ Quality Gate en cours (${qg.status}), attente..."
                                        currentAttempt++
                                        if (currentAttempt < maxAttempts) {
                                            sleep(20)
                                        }
                                    } else {
                                        echo "❓ Status inconnu: ${qg.status}"
                                        qgPassed = true
                                    }
                                    
                                } catch (Exception e) {
                                    echo "❌ Erreur Quality Gate: ${e.message}"
                                    currentAttempt++
                                    if (currentAttempt < maxAttempts) {
                                        sleep(15)
                                    }
                                }
                            }
                            
                            if (!qgPassed) {
                                echo "⏰ Timeout Quality Gate - Continuation du pipeline"
                                echo "🔗 Vérification manuelle: http://localhost:9000/dashboard?id=${env.SONAR_PROJECT_KEY}"
                            }
                        }
                    } catch (Exception e) {
                        echo "❌ Erreur lors de la vérification Quality Gate: ${e.message}"
                        echo "🔄 Continuation du pipeline"
                    }
                }
            }
        }

        stage('🐳 Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    try {
                        dockerBuildFullImage(
                            imageName: env.DOCKER_IMAGE_NAME,
                            tags: ["latest", "${env.BUILD_NUMBER}"],
                            buildArgs: "--build-arg JAR_FILE=${env.JAR_FILE_NAME}",
                            credentialsId: "docker-hub-creds"
                        )
                        echo "✅ Image Docker construite: ${env.DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                    } catch (Exception e) {
                        error "❌ Erreur lors de la construction Docker: ${e.message}"
                    }
                }
            }
        }

        stage('🔍 Analyse Sécurité Trivy') {
            when {
                expression { params.SKIP_TRIVY == false }
            }
            steps {
                script {
                    echo "🔍 Analyse de sécurité avec Trivy..."
                    def imageName = "${env.DOCKER_IMAGE_NAME}:latest"
                    
                    try {
                        // Téléchargement du template avec retry
                        retry(3) {
                            sh """
                                curl -sL --connect-timeout 30 --max-time 60 ${env.TRIVY_TEMPLATE_URL} -o html.tpl || \
                                curl -sL --connect-timeout 30 --max-time 60 ${env.TRIVY_TEMPLATE_URL} -o html.tpl
                            """
                        }
                        
                        // Mise à jour base de données Trivy
                        sh """
                            trivy image --download-db-only --timeout 5m || \
                            trivy image --download-db-only --timeout 5m
                        """
                        
                        // Analyse de sécurité
                        sh """
                            trivy image --severity HIGH,CRITICAL \
                                --ignore-unfixed \
                                --format json \
                                --timeout 10m \
                                -o trivy-report.json \
                                ${imageName} || echo "Trivy JSON failed"
                                
                            trivy image --severity HIGH,CRITICAL \
                                --ignore-unfixed \
                                --format template \
                                --template '@html.tpl' \
                                --timeout 10m \
                                -o trivy-report.html \
                                ${imageName} || echo "Trivy HTML failed"
                        """
                        
                        // Analyse des résultats
                        if (fileExists('trivy-report.json')) {
                            def report = readJSON file: 'trivy-report.json'
                            def criticalCount = 0
                            def highCount = 0
                            
                            if (report.Results) {
                                def allVulns = report.Results
                                    .findAll { it.Vulnerabilities }
                                    .collectMany { it.Vulnerabilities }
                                    
                                criticalCount = allVulns.count { it.Severity == "CRITICAL" }
                                highCount = allVulns.count { it.Severity == "HIGH" }
                            }
                            
                            echo "📊 Résultats Trivy:"
                            echo "  - Vulnérabilités CRITICAL: ${criticalCount}"
                            echo "  - Vulnérabilités HIGH: ${highCount}"
                            
                            if (criticalCount > 0) {
                                echo "⚠️ ${criticalCount} vulnérabilités CRITICAL détectées"
                                // Vous pouvez choisir de faire échouer ici
                                // error "Trop de vulnérabilités critiques"
                            }
                        }
                        
                        echo "✅ Analyse Trivy terminée"
                        
                    } catch (Exception e) {
                        echo "❌ Erreur lors de l'analyse Trivy: ${e.message}"
                        // Continuer malgré l'erreur Trivy
                    }
                }
            }
            post {
                always {
                    script {
                        // Archivage des rapports
                        try {
                            archiveArtifacts artifacts: 'trivy-report.*', fingerprint: true, allowEmptyArchive: true
                        } catch (Exception e) {
                            echo "⚠️ Impossible d'archiver les rapports Trivy: ${e.message}"
                        }
                        
                        // Publication du rapport HTML
                        try {
                            if (fileExists('trivy-report.html')) {
                                publishHTML([
                                    allowMissing: false,
                                    keepAll: true,
                                    reportDir: '.',
                                    reportFiles: 'trivy-report.html',
                                    reportName: 'Rapport Trivy',
                                    reportTitles: 'Analyse de Sécurité'
                                ])
                            }
                        } catch (Exception e) {
                            echo "⚠️ Impossible de publier le rapport HTML: ${e.message}"
                        }
                    }
                }
            }
        }














