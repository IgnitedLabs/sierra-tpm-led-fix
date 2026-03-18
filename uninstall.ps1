# Sierra TPM LED Fix — Uninstaller
# Restores the original BravoLED.exe configuration

$exeXml = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\exe.xml"
$bravoDir = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\Packages\Community\BravoLED"

if (Test-Path "$exeXml.backup") {
    Copy-Item "$exeXml.backup" $exeXml -Force
    Write-Host "exe.xml restored from backup" -ForegroundColor Green
} else {
    $xmlContent = @"
<SimBase.Document Type="SimConnect" version="1,0">
        <Descr>SimConnect</Descr>
        <Filename>SimConnect.xml</Filename>
        <Disabled>False</Disabled>
        <Launch.Addon>
                <n>BravoLED</n>
                <Disabled>false</Disabled>
                <Path>$bravoDir\BravoLED.exe</Path>
        </Launch.Addon>
</SimBase.Document>
"@
    Set-Content $exeXml -Value $xmlContent
    Write-Host "exe.xml restored to BravoLED.exe" -ForegroundColor Green
}

# Remove SierraLED.exe
if (Test-Path "$bravoDir\SierraLED.exe") {
    Remove-Item "$bravoDir\SierraLED.exe" -Force
    Write-Host "SierraLED.exe removed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Uninstall complete. Original BravoLED configuration restored."
