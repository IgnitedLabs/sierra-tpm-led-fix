$ErrorActionPreference = "Stop"

$passedCount = 0
$failedCount = 0

Write-Host ""
Write-Host "PowerShell Syntax Checks" -ForegroundColor Cyan
Write-Host "------------------------"

$scriptFiles = @(
    "install.ps1",
    "uninstall.ps1",
    "examples/compile.ps1",
    "examples/register.ps1"
)

foreach ($scriptFile in $scriptFiles) {
    if (-not (Test-Path $scriptFile)) {
        Write-Host "  [ MISSING ] $scriptFile" -ForegroundColor Red
        $failedCount++
        continue
    }

    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $scriptFile), [ref]$tokens, [ref]$errors)

    if ($errors -and $errors.Count -gt 0) {
        Write-Host "  [  FAIL  ] $scriptFile" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "             Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red }
        $failedCount++
    } else {
        Write-Host "  [  PASS  ] $scriptFile" -ForegroundColor Green
        $passedCount++
    }
}

if ($failedCount -gt 0) {
    throw "PowerShell syntax validation failed ($failedCount file(s) with errors)"
}

Write-Host ""
Write-Host "C# Compilation" -ForegroundColor Cyan
Write-Host "--------------"

$cscCandidates = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

$csc = $cscCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) {
    Write-Host "  [  FAIL  ] csc.exe not found in .NET Framework locations" -ForegroundColor Red
    throw "C# compiler not found"
}

Write-Host "  Compiler : $csc"
Write-Host "  Source   : SierraLED.cs"

New-Item -ItemType Directory -Path ".ci-out" -Force | Out-Null
& $csc /nologo /optimize /target:winexe /out:".ci-out\SierraLED.exe" "SierraLED.cs"

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [  FAIL  ] SierraLED.cs" -ForegroundColor Red
    throw "C# compilation failed"
}

Write-Host "  [  PASS  ] SierraLED.cs" -ForegroundColor Green
$passedCount++

Write-Host ""
Write-Host "Results: $passedCount passed, $failedCount failed" -ForegroundColor Cyan
Write-Host ""
