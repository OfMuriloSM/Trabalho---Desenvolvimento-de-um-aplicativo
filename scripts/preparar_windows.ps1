$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
Write-Host 'Academia App - preparo do projeto Flutter' -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter não encontrado no PATH. Execute flutter doctor antes.'
}
# Se já houver pastas Android, não assume que --org altera o applicationId existente.
$gradle = Join-Path (Get-Location) 'android/app/build.gradle.kts'
if (Test-Path $gradle) {
    $original = Get-Content -Raw $gradle
    if ($original -match 'namespace\s*=\s*"([^"]+)"') {
        $namespaceAtual = $Matches[1]
        if (-not $namespaceAtual.StartsWith('br.app.academia')) {
            Write-Warning "O projeto Android usa namespace '$namespaceAtual'. Confira namespace, applicationId e MainActivity antes de publicar."
        }
    }
}
Write-Host 'Usando scaffolding Android e Web existente sem recriar o projeto...'
if (-not (Test-Path 'android/app/build.gradle.kts') -or -not (Test-Path 'web/index.html')) {
    throw 'O scaffolding Android/Web não foi encontrado. Confira se extraiu o ZIP completo.'
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get falhou.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze falhou.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test falhou.' }
Write-Host 'Pronto! Inicie com:' -ForegroundColor Green
Write-Host 'flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080'
