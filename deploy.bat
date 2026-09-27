@echo off
echo ========================================================
echo   Updating Onion Final App on Vercel
echo   Target: https://onion-final-app.vercel.app
echo ========================================================

echo.
echo [1/3] Navigating to Flutter web application...
cd /d "%~dp0onion-main\onion_app"

echo.
echo [2/3] Building Flutter Web production release bundle...
call flutter build web --release --no-tree-shake-icons
if errorlevel 1 (
    echo.
    echo [ERROR] Flutter web build failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Deploying to Vercel (Production)...
cd build\web
call npx vercel --prod --yes

echo.
echo ========================================================
echo   SUCCESS! Your update is live at:
echo   https://onion-final-app.vercel.app
echo ========================================================
pause
