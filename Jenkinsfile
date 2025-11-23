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
                echo "=== RESUMEN DEL BUILD ==="
                echo "Proyecto: ${SONAR_PROJECT_NAME}"
                echo "Build: #${currentBuild.number}"
                echo "Estado: ${currentBuild.result ?: 'SUCCESS'}"
                echo "URL: ${env.BUILD_URL}"

                if (currentBuild.result == 'FAILURE') {
                    echo "🔍 Revisar SonarQube para detalles de la Quality Gate"
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
            echo "   - Métricas en SonarQube"
        }
    }
}
