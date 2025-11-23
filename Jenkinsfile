pipeline {
    agent any

    environment {
        SONAR_PROJECT_KEY = 'backend-petclinic'
        SONAR_PROJECT_NAME = 'Backend PetClinic'
    }

    stages {
        // ETAPA 1: Checkout del codi font
        stage('Checkout SCM') {
            steps {
                checkout scm
                script {
                    currentBuild.description = "Backend Build #${currentBuild.number}"
                }
            }
        }

        // ETAPA 2: Compilació i execució de tests
        stage('Build & Tests') {
            steps {
                bat 'mvn clean verify'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    archiveArtifacts 'target/*.jar'
                }
            }
        }

        // ETAPA 3: Generació d'informes de cobertura
        stage('Coverage Report') {
            steps {
                bat 'mvn jacoco:report'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'target/site/jacoco',
                    reportFiles: 'index.html',
                    reportName: 'JaCoCo Coverage Report'
                ])
                archiveArtifacts 'target/site/jacoco/**/*'
            }
        }

        // ETAPA 4: Anàlisi de qualitat amb SonarQube
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-qube') {
                    bat """
                    mvn sonar:sonar ^
                      -Dsonar.projectKey=${SONAR_PROJECT_KEY} ^
                      -Dsonar.projectName="${SONAR_PROJECT_NAME}" ^
                      -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    """
                }
            }
        }

        // ETAPA 5: Verificació de Quality Gate
        stage('Quality Gate Check') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
            post {
                success {
                    echo "✅ QUALITY GATE PASSED - El código cumple los estándares de calidad"
                    script {
                        currentBuild.description += " | ✅ Quality Gate"
                    }
                }
                failure {
                    echo "❌ QUALITY GATE FAILED - Revisar métricas en SonarQube"
                    script {
                        currentBuild.description += " | ❌ Quality Gate"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "=== PIPELINE BACKEND COMPLETAT ==="
                echo "Projecte: ${SONAR_PROJECT_NAME}"
                echo "Build: #${currentBuild.number}"
                echo "Estat: ${currentBuild.result ?: 'SUCCESS'}"
                echo "URL Build: ${env.BUILD_URL}"
                echo "URL SonarQube: http://localhost:9000/dashboard?id=${SONAR_PROJECT_KEY}"

                // Recordatori per captures de pantalla
                if (currentBuild.result == 'SUCCESS') {
                    echo "📸 CAPTURES PER LA FASE 4:"
                    echo "   1. Pipeline complet amb totes les etapes en verd"
                    echo "   2. Quality Gate PASSED a la consola"
                    echo "   3. Projecte a SonarQube amb Quality Gate en verd"
                    echo "   4. Informes de cobertura i tests"
                }
            }
        }
        success {
            echo "🎉 PIPELINE FINALITZAT AMB ÈXIT"
            echo "✅ Tests executats i reportats"
            echo "✅ Cobertura generada i publicada"
            echo "✅ Anàlisi SonarQube completat"
            echo "✅ Quality Gate aprovada"
        }
        failure {
            echo "❌ PIPELINE FALLIT"
            echo "💡 Accions correctores:"
            echo "   - Revisar errors de compilació"
            echo "   - Verificar tests unitaris"
            echo "   - Consultar SonarQube per mètriques: http://localhost:9000/dashboard?id=${SONAR_PROJECT_KEY}"
        }
        unstable {
            echo "⚠️  PIPELINE COMPLETAT AMB ADVERTÈNCIES"
            echo "🔍 Revisar Quality Gate a SonarQube"
        }
    }
}
