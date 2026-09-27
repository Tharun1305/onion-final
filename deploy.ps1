Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Updating Onion Final App on Vercel" -ForegroundColor Cyan
Write-Host "  Target: https://onion-final-app.vercel.app" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$appDir = Join-Path $PSScriptRoot "onion-main\onion_app"
$webBuildDir = Join-Path $appDir "build\web"

Write-Host "`n[1/3] Building Flutter Web production release bundle..." -ForegroundColor Yellow
Set-Location $appDir
flutter build web --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Flutter build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/3] Deploying to Vercel (Production)..." -ForegroundColor Yellow
Set-Location $webBuildDir
npx vercel --prod --yes

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host "  SUCCESS! Your update is live at:" -ForegroundColor Green
    Write-Host "  https://onion-final-app.vercel.app" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
} else {
    Write-Host "`n[ERROR] Deployment failed!" -ForegroundColor Red
}
