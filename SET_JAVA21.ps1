# PowerShell script to set Java 21 for current session
# Run this script: .\SET_JAVA21.ps1
# Or add this to your PowerShell profile for automatic execution

$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
$env:PATH = "C:\Program Files\Java\jdk-21\bin;$env:PATH"

Write-Host "`n=== Java 21 Activated ===" -ForegroundColor Green
Write-Host "JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Cyan
Write-Host "`nJava version:" -ForegroundColor Yellow
java -version
Write-Host "`nMaven Java version:" -ForegroundColor Yellow
.\mvnw.cmd -version | Select-String "Java version"
Write-Host "`nReady to build and run!" -ForegroundColor Green

