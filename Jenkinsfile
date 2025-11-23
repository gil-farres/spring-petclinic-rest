pipeline {
    agent any

    environment {
        SONAR_PROJECT_KEY = 'backend-petclinic'
        SONAR_PROJECT_NAME = 'Backend PetClinic'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    currentBuild.description = "Backend Build #${currentBuild.number}"
                }
            }
        }

        stage('Verify Environment') {
            steps {
                bat 'java -version'
                bat 'mvn --version'
                bat 'if exist pom.xml (echo "✅ pom.xml encontrado") else (echo "❌ pom.xml no encontrado" && exit 1)'
            }
        }

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

        stage('Quality Gate Check') {
            steps {
                script {
                    // Espera más tiempo y maneja mejor el timeout
                    timeout(time: 20, unit: 'MINUTES') {
                        echo "⏳ Esperando resultado de Quality Gate..."
                        def qg = waitForQualityGate()

                        if (qg.status == 'OK') {
                            echo "✅ QUALITY GATE PASSED - El código cumple los estándares de calidad"
                            currentBuild.description += " | ✅ Quality Gate"
                        } else {
                            error "❌ QUALITY GATE FAILED - Status: ${qg.status}. Revisar métricas en SonarQube"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "=== RESUMEN DEL BUILD ==="
                echo "Proyecto: ${SONAR_PROJECT_NAME}"
                echo "Build: #${currentBuild.number}"
                echo "Estado: ${currentBuild.result ?: 'SUCCESS'}"
                echo "URL: ${env.BUILD_URL}"
                echo "URL SonarQube: http://localhost:9000/dashboard?id=${SONAR_PROJECT_KEY}"

                if (currentBuild.result == 'FAILURE') {
                    echo "🔍 Revisar SonarQube para detalles: http://localhost:9000/dashboard?id=${SONAR_PROJECT_KEY}"
                }
            }
        }
        success {
            echo "🎉 BACKEND PIPELINE COMPLETADO EXITOSAMENTE"
            echo "✅ Tests ejecutados y reportes generados"
            echo "✅ Análisis SonarQube completado"
            echo "✅ Quality Gate aprobada"
        }
        failure {
            echo "❌ BACKEND PIPELINE FALLIDO"
            echo "💡 Verificar:"
            echo "   - Tests unitarios"
            echo "   - Cobertura de código"
            echo "   - Métricas en SonarQube: http://localhost:9000/dashboard?id=${SONAR_PROJECT_KEY}"
        }
    }
}
