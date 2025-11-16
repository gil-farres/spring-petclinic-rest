# Guía de Configuración: Informe HTML de Cobertura JaCoCo en Jenkins

## Problema Resuelto
Jenkins fallaba con el error:
```
ERROR: Specified HTML directory 'C:\ProgramData\Jenkins\.jenkins\workspace\SpringPetclinic-CI\coverage' does not exist.
Build step 'Publish HTML reports' changed build result to FAILURE
```

## Solución Implementada

### 1. Cambios en el Proyecto

#### A. Modificación del `pom.xml`
Se agregó el formato HTML al plugin JaCoCo (líneas 318-328):
```xml
<execution>
    <id>report</id>
    <goals>
        <goal>report</goal>
    </goals>
    <configuration>
        <formats>
            <format>XML</format>
            <format>HTML</format>  <!-- ← AGREGADO -->
        </formats>
    </configuration>
</execution>
```

Esto hace que Maven genere el informe HTML en: `target/site/jacoco/index.html`

#### B. Script de Copia (`copy-jacoco-report.bat`)
Se creó un script batch que copia el informe generado al directorio esperado por Jenkins:
- Lee desde: `target\site\jacoco\*`
- Copia a: `coverage\*`

#### C. Jenkinsfile
Se creó un Jenkinsfile declarativo completo con:
- Etapa de tests con generación de cobertura
- Etapa de copia del informe al directorio `coverage`
- Publicación del HTML con el plugin HTML Publisher

---

## Opciones de Implementación en Jenkins

### OPCIÓN A: Usar el Jenkinsfile incluido (RECOMENDADO)

1. **Configurar el Job como Pipeline**:
   - En Jenkins: New Item → Pipeline
   - Pipeline Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: [tu repositorio]
   - Script Path: `Jenkinsfile`

2. **Configurar Herramientas Globales** (Manage Jenkins → Global Tool Configuration):
   - **JDK**: 
     - Name: `JDK17` (o el nombre que uses)
     - JAVA_HOME: `C:\Program Files\Java\jdk-17` (ajusta la ruta)
   - **Maven** (opcional, el proyecto usa mvnw.cmd):
     - Name: `Maven3`
     - MAVEN_HOME: ruta a tu instalación de Maven

3. **Ejecutar el Job**: El Jenkinsfile se encarga de todo automáticamente.

---

### OPCIÓN B: Job Estilo Libre (Freestyle)

Si prefieres usar un job estilo libre existente:

1. **Sección Build**:
   Agregar paso "Execute Windows batch command":
   ```batch
   REM Generar informe de cobertura
   .\mvnw.cmd clean test jacoco:report

   REM Copiar al directorio esperado por Jenkins
   if not exist coverage mkdir coverage
   xcopy /E /I /Y target\site\jacoco\* coverage\
   ```

2. **Sección Post-build Actions**:
   - Agregar "Publish HTML reports":
     - HTML directory to archive: `coverage`
     - Index page[s]: `index.html`
     - Report title: `JaCoCo Coverage Report`
     - Keep past HTML reports: ☑

---

### OPCIÓN C: Cambiar la Configuración del Publicador (SIN copiar archivos)

Si prefieres NO copiar archivos, simplemente apunta al directorio original:

1. En la configuración del job, en "Publish HTML reports":
   - Cambiar "HTML directory to archive" de:
     ```
     coverage
     ```
     a:
     ```
     target/site/jacoco
     ```

2. En el build step, asegúrate de ejecutar:
   ```batch
   .\mvnw.cmd clean test jacoco:report
   ```

---

## Comandos para Prueba Local (Windows)

### 1. Configurar JAVA_HOME (si no está definido):
```batch
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"
```

### 2. Generar el informe:
```batch
.\mvnw.cmd clean test jacoco:report
```

### 3. Verificar que se generó:
```batch
dir target\site\jacoco\index.html
```

### 4. Copiar al directorio coverage (opcional):
```batch
copy-jacoco-report.bat
```

### 5. Abrir el informe en el navegador:
```batch
start target\site\jacoco\index.html
```
O si copiaste:
```batch
start coverage\index.html
```

---

## Verificación de la Configuración

### ✓ Checklist Pre-Ejecución:

- [ ] JAVA_HOME está configurado en el nodo Jenkins
- [ ] El agente Jenkins tiene permisos de escritura en el workspace
- [ ] El plugin "HTML Publisher" está instalado en Jenkins
- [ ] El `pom.xml` tiene `<format>HTML</format>` en jacoco-maven-plugin
- [ ] El Jenkinsfile usa la ruta correcta para el wrapper: `.\mvnw.cmd` (Windows)

### ✓ Checklist Post-Ejecución:

- [ ] El directorio `target\site\jacoco` se creó
- [ ] El archivo `target\site\jacoco\index.html` existe
- [ ] El directorio `coverage` se creó (si usas la copia)
- [ ] Los archivos HTML están en `coverage` (si usas la copia)
- [ ] Jenkins muestra el link "JaCoCo Coverage Report" en el build

---

## Estructura de Directorios Esperada

Después de una ejecución exitosa:

```
spring-petclinic-rest/
├── target/
│   ├── site/
│   │   └── jacoco/           ← Generado por Maven
│   │       ├── index.html
│   │       ├── jacoco.xml
│   │       ├── jacoco.csv
│   │       └── [archivos HTML y CSS]
│   └── surefire-reports/     ← Resultados de tests
├── coverage/                  ← Copiado para Jenkins (opcional)
│   ├── index.html
│   └── [archivos HTML y CSS]
├── Jenkinsfile                ← Pipeline definition
├── copy-jacoco-report.bat     ← Script de copia
└── pom.xml                    ← Configuración JaCoCo actualizada
```

---

## Troubleshooting

### Problema: "JAVA_HOME not found"
**Solución**: 
- Configurar JAVA_HOME en el sistema o en el Jenkinsfile:
  ```groovy
  environment {
      JAVA_HOME = 'C:\\Program Files\\Java\\jdk-17'
      PATH = "${JAVA_HOME}\\bin;${env.PATH}"
  }
  ```

### Problema: "Plugin 'jacoco-maven-plugin' not found"
**Solución**: Ejecuta `.\mvnw.cmd validate` para que Maven descargue plugins.

### Problema: El informe está vacío o muestra 0% cobertura
**Solución**: 
- Verifica que los tests se ejecuten correctamente
- Asegúrate de que `prepare-agent` de JaCoCo se ejecute ANTES de los tests
- El `pom.xml` ya tiene esta configuración correcta

### Problema: "xcopy" falla con error
**Solución**: 
- Verifica que `target\site\jacoco` exista antes de copiar
- El script `copy-jacoco-report.bat` ya incluye validación

---

## Comandos Maven Útiles

```batch
REM Limpiar proyecto
.\mvnw.cmd clean

REM Compilar sin tests
.\mvnw.cmd compile

REM Solo tests (sin recompilar todo)
.\mvnw.cmd test

REM Tests + informe JaCoCo
.\mvnw.cmd test jacoco:report

REM Build completo + cobertura
.\mvnw.cmd clean verify

REM Ver el informe de cobertura en consola
.\mvnw.cmd jacoco:check
```

---

## Notas Adicionales

1. **Umbrales de Cobertura**: El `pom.xml` tiene configurado:
   - Cobertura de líneas mínima: 85%
   - Cobertura de branches mínima: 66%
   - El build FALLARÁ si no se alcanzan estos umbrales (goal `jacoco:check`)

2. **Exclusiones**: El informe excluye automáticamente:
   - `**/org/springframework/samples/petclinic/rest/dto/**` (DTOs generados)
   - `**/org/springframework/samples/petclinic/rest/api/**` (APIs generadas)

3. **Formatos Disponibles**:
   - HTML: Para visualización en Jenkins/navegador
   - XML: Para integración con SonarQube/SonarCloud
   - CSV: Para análisis en hojas de cálculo

4. **Compatibilidad**: 
   - Solución probada en Windows con cmd.exe y PowerShell
   - Para Linux/Mac, reemplazar `.\mvnw.cmd` por `./mvnw`
   - Para Linux/Mac, reemplazar `xcopy` por `cp -r`

---

## Contacto y Soporte

Si encuentras problemas:
1. Revisa los logs de consola de Jenkins
2. Verifica que `target\site\jacoco\index.html` se haya generado localmente
3. Confirma que el plugin HTML Publisher esté instalado y actualizado

---

**Última actualización**: 2025-11-16
**Versión JaCoCo**: 0.8.14
**Versión Spring Boot**: 3.5.7

