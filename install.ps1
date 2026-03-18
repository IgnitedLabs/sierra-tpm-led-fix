# Sierra TPM LED Fix — Installer
# Run this script from the repo directory in PowerShell

$ErrorActionPreference = "Stop"

$bravoDir = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\Packages\Community\BravoLED"
$exeXml = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\exe.xml"
$srcFile = Join-Path $PSScriptRoot "SierraLED.cs"

# Check prerequisites
if (-not (Test-Path $bravoDir)) {
    Write-Host "ERROR: BravoLED community package not found at:" -ForegroundColor Red
    Write-Host "  $bravoDir"
    Write-Host "Install the official Honeycomb LED driver first, then run this script."
    exit 1
}

if (-not (Test-Path $srcFile)) {
    Write-Host "ERROR: SierraLED.cs not found. Run this script from the repo directory." -ForegroundColor Red
    exit 1
}

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    Write-Host "ERROR: .NET Framework compiler not found at:" -ForegroundColor Red
    Write-Host "  $csc"
    exit 1
}

# Backup original exe.xml
if ((Test-Path $exeXml) -and -not (Test-Path "$exeXml.backup")) {
    Copy-Item $exeXml "$exeXml.backup"
    Write-Host "Backed up exe.xml to exe.xml.backup"
}

# Compile
Write-Host "Compiling SierraLED.exe..."
& $csc /nologo /optimize /target:winexe /out:"$bravoDir\SierraLED.exe" $srcFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Compilation failed" -ForegroundColor Red
    exit 1
}
Write-Host "  OK" -ForegroundColor Green

# Update exe.xml
Write-Host "Updating exe.xml..."
$xmlContent = @"
<SimBase.Document Type="SimConnect" version="1,0">
        <Descr>SimConnect</Descr>
        <Filename>SimConnect.xml</Filename>
        <Disabled>False</Disabled>
        <Launch.Addon>
                <Name>SierraLED</Name>
                <Disabled>false</Disabled>
                <Path>$bravoDir\SierraLED.exe</Path>
        </Launch.Addon>
</SimBase.Document>
"@
Set-Content $exeXml -Value $xmlContent
Write-Host "  OK" -ForegroundColor Green

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "If BravoLED.exe ran previously, unplug the Sierra for 30 seconds and replug."
Write-Host "Then start MSFS, load a flight, and the LEDs will work automatically."
