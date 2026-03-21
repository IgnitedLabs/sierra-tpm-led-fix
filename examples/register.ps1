# Sierra TPM LED Fix — Register with MSFS
# Updates exe.xml to launch SierraLED.exe instead of BravoLED.exe when MSFS starts
#
# Run with: powershell -ExecutionPolicy Bypass -File examples/register.ps1

$bravoDir = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\Packages\Community\BravoLED"
$exeXml = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\exe.xml"

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
