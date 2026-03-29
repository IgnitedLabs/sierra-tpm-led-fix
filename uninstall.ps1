# Sierra TPM LED Fix - Uninstaller
# Restores the original BravoLED.exe configuration

# Auto-discover MSFS package path
$msfsPackage = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Microsoft.Limitless*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $msfsPackage) {
    Write-Host "ERROR: MSFS 2024 package not found." -ForegroundColor Red
    exit 1
}

$msfsLocal = Join-Path $msfsPackage.FullName "LocalCache"
$bravoDir = Join-Path $msfsLocal "Packages\Community\BravoLED"
$exeXml = Join-Path $msfsLocal "exe.xml"

# Restore exe.xml
if (Test-Path "$exeXml.backup") {
    Copy-Item "$exeXml.backup" $exeXml -Force
    Write-Host "exe.xml restored from backup" -ForegroundColor Green
} else {
    $nameOpen = '<' + 'Name' + '>'
    $nameClose = '</' + 'Name' + '>'
    $xmlContent = @"
<SimBase.Document Type="SimConnect" version="1,0">
        <Descr>SimConnect</Descr>
        <Filename>SimConnect.xml</Filename>
        <Disabled>False</Disabled>
        <Launch.Addon>
                ${nameOpen}BravoLED${nameClose}
                <Disabled>false</Disabled>
                <Path>$bravoDir\BravoLED.exe</Path>
        </Launch.Addon>
</SimBase.Document>
"@
    Set-Content $exeXml -Value $xmlContent
    Write-Host "exe.xml restored to BravoLED.exe" -ForegroundColor Green
}

# Remove Sierra LED files
Remove-Item "$bravoDir\SierraLED.cs" -Force -ErrorAction SilentlyContinue
Remove-Item "$bravoDir\SierraLED.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$bravoDir\SierraLED.exe" -Force -ErrorAction SilentlyContinue
Write-Host "Sierra LED files removed" -ForegroundColor Green

# Remove desktop shortcut
$desktop = [Environment]::GetFolderPath("Desktop")
Remove-Item "$desktop\Sierra LED Driver.lnk" -Force -ErrorAction SilentlyContinue
Write-Host "Desktop shortcut removed" -ForegroundColor Green

Write-Host ""
Write-Host "Uninstall complete. Original BravoLED configuration restored."
