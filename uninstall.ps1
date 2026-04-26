# Sierra TPM LED Fix - Uninstaller
# Restores the original BravoLED.exe configuration

function Resolve-MsfsPaths {
    # Mirror the installer: only return the Xbox layout when BravoLED is
    # actually present, otherwise fall through to the Steam/UserCfg.opt path.
    $msfsPackage = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Microsoft.Limitless*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($msfsPackage) {
        $xboxBravo = Join-Path $msfsPackage.FullName "LocalCache\Packages\Community\BravoLED"
        if (Test-Path $xboxBravo) {
            return [pscustomobject]@{
                BravoDir = $xboxBravo
                ExeXml   = Join-Path $msfsPackage.FullName "LocalCache\exe.xml"
                Source   = "MS Store/Xbox package"
            }
        }
    }

    $userCfgPath = Join-Path $env:APPDATA "Microsoft Flight Simulator 2024\UserCfg.opt"
    if (-not (Test-Path $userCfgPath)) {
        return $null
    }

    $installedPackagesLine = Select-String -Path $userCfgPath -Pattern 'InstalledPackagesPath' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $installedPackagesLine) {
        return $null
    }

    $installedPackagesPath = [regex]::Match($installedPackagesLine.Line, 'InstalledPackagesPath\s+"([^"]+)"').Groups[1].Value
    if ([string]::IsNullOrWhiteSpace($installedPackagesPath)) {
        return $null
    }

    return [pscustomobject]@{
        BravoDir = Join-Path $installedPackagesPath "Community\BravoLED"
        ExeXml   = Join-Path (Split-Path -Parent $userCfgPath) "exe.xml"
        Source   = "Roaming UserCfg.opt"
    }
}

$msfsPaths = Resolve-MsfsPaths
if (-not $msfsPaths) {
    Write-Host "ERROR: MSFS 2024 install not found." -ForegroundColor Red
    exit 1
}

$bravoDir = $msfsPaths.BravoDir
$exeXml = $msfsPaths.ExeXml

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
