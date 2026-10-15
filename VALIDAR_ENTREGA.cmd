@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
if /I not "%~1"=="--executar" (
  echo Iniciando verificacao. Aguarde; o resultado sera salvo automaticamente.
  echo Arquivo: "%~dp0RESULTADO_VALIDACAO.txt"
  call "%~f0" --executar > "%~dp0RESULTADO_VALIDACAO.txt" 2>&1
  set "codigo=!errorlevel!"
  type "%~dp0RESULTADO_VALIDACAO.txt"
  echo.
  echo Resultado gravado em RESULTADO_VALIDACAO.txt
  pause
  exit /b !codigo!
)
if not exist "pubspec.yaml" (
  echo [ERRO] Execute este arquivo na pasta raiz do projeto Flutter.
  pause
  exit /b 1
)
echo.
echo ==============================================
echo   ACADEMIA V1 - VALIDACAO PARA ENTREGA
echo ==============================================
echo.
if exist "lib\features\screens.dart" (
  echo [INFO] Encontrado screens.dart da versao antiga.
  if not exist "lib\features\screens.dart.obsoleto.bak" (
    move "lib\features\screens.dart" "lib\features\screens.dart.obsoleto.bak" >nul
  ) else (
    echo [AVISO] Backup ja existe. Renomeie lib\features\screens.dart manualmente.
    pause
    exit /b 1
  )
)
echo [1/5] Encerrando daemons Gradle...
if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --stop
  popd
)
echo [2/5] Limpando caches do projeto...
call flutter clean
if errorlevel 1 goto :falhou
echo [3/5] Baixando dependencias...
call flutter pub get
if errorlevel 1 goto :falhou
echo [4/5] Analisando e testando...
call flutter analyze
if errorlevel 1 goto :falhou
call flutter test
if errorlevel 1 goto :falhou
echo [5/5] Gerando APK debug...
call flutter build apk --debug
if errorlevel 1 goto :falhou
echo.
echo [OK] Analise, testes e compilacao finalizaram sem erros.
echo APK: build\app\outputs\flutter-apk\app-debug.apk
pause
exit /b 0
:falhou
echo.
echo [ERRO] O comando anterior falhou. Copie ou fotografe as ultimas linhas.
pause
exit /b 1
