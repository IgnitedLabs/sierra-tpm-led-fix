$ErrorActionPreference = "Stop"

Write-Host "Running PowerShell syntax checks..."
$scriptFiles = @(
    "install.ps1",
    "uninstall.ps1"
)

foreach ($scriptFile in $scriptFiles) {
    if (-not (Test-Path $scriptFile)) {
        throw "Missing script: $scriptFile"
    }

    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $scriptFile), [ref]$tokens, [ref]$errors)

    if ($errors -and $errors.Count -gt 0) {
        Write-Host "Syntax errors in ${scriptFile}:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        throw "PowerShell syntax validation failed"
    }
}

Write-Host "PowerShell syntax checks passed" -ForegroundColor Green

Write-Host "Compiling SierraLED.cs..."
$cscCandidates = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

$csc = $cscCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) {
    throw "C# compiler not found in .NET Framework locations"
}

New-Item -ItemType Directory -Path ".ci-out" -Force | Out-Null
& $csc /nologo /optimize /target:winexe /out:".ci-out\SierraLED.exe" "SierraLED.cs"

if ($LASTEXITCODE -ne 0) {
    throw "C# compilation failed"
}

Write-Host "Compilation passed" -ForegroundColor Green
Write-Host "All validation checks passed" -ForegroundColor Green
