@echo off
REM Script para copiar el informe JaCoCo HTML al directorio coverage esperado por Jenkins

echo Copiando informe JaCoCo a directorio coverage...

if not exist "coverage" (
    echo Creando directorio coverage...
    mkdir coverage
)

if exist "target\site\jacoco" (
    echo Copiando archivos desde target\site\jacoco a coverage...
    xcopy /E /I /Y target\site\jacoco\* coverage\
    echo.
    echo Informe copiado exitosamente a: coverage\index.html
    exit /b 0
) else (
    echo ERROR: No se encontro el directorio target\site\jacoco
    echo Asegurate de ejecutar: mvn clean test jacoco:report
    exit /b 1
)

