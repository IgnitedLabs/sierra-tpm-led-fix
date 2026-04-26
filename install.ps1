# Sierra TPM LED Fix - Installer
# Run from the repo directory in PowerShell

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-MsfsPaths {
    # Prefer the MS Store/Xbox layout, but only if BravoLED is actually present
    # there. A stale Microsoft.Limitless* folder (Xbox uninstalled but folder
    # left behind) must NOT short-circuit the Steam fallback below.
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
        # Xbox folder exists but no BravoLED community pkg — fall through.
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
    Write-Host "ERROR: MSFS 2024 install not found in either:" -ForegroundColor Red
    Write-Host "  $env:LOCALAPPDATA\Packages\Microsoft.Limitless*"
    Write-Host "  $env:APPDATA\Microsoft Flight Simulator 2024\UserCfg.opt"
    exit 1
}

$bravoDir = $msfsPaths.BravoDir
$exeXml = $msfsPaths.ExeXml

if (-not (Test-Path $bravoDir)) {
    Write-Host "ERROR: BravoLED community package not found at:" -ForegroundColor Red
    Write-Host "  $bravoDir"
    Write-Host "Resolved via: $($msfsPaths.Source)"
    Write-Host "Install the official Honeycomb LED driver first."
    exit 1
}

if (-not (Test-Path (Join-Path $scriptDir "SierraLED.cs"))) {
    Write-Host "ERROR: SierraLED.cs not found. Run this from the repo directory." -ForegroundColor Red
    exit 1
}

# Backup original exe.xml
if ((Test-Path $exeXml) -and -not (Test-Path "$exeXml.backup")) {
    Copy-Item $exeXml "$exeXml.backup"
    Write-Host "Backed up exe.xml"
}

if (-not (Test-Path $exeXml)) {
    $exeXmlDir = Split-Path -Parent $exeXml
    if (-not (Test-Path $exeXmlDir)) {
        New-Item -ItemType Directory -Path $exeXmlDir -Force | Out-Null
    }
}

# Copy driver files
Copy-Item (Join-Path $scriptDir "SierraLED.cs") "$bravoDir\SierraLED.cs" -Force
Copy-Item (Join-Path $scriptDir "SierraLED.ps1") "$bravoDir\SierraLED.ps1" -Force
Write-Host "Driver files copied to $bravoDir"

# Disable BravoLED in exe.xml
$nameOpen = '<' + 'Name' + '>'
$nameClose = '</' + 'Name' + '>'
$xmlContent = @"
<SimBase.Document Type="SimConnect" version="1,0">
        <Descr>SimConnect</Descr>
        <Filename>SimConnect.xml</Filename>
        <Disabled>False</Disabled>
        <Launch.Addon>
                ${nameOpen}BravoLED${nameClose}
                <Disabled>true</Disabled>
                <Path>$bravoDir\BravoLED.exe</Path>
        </Launch.Addon>
</SimBase.Document>
"@
Set-Content $exeXml -Value $xmlContent
Write-Host "BravoLED disabled in exe.xml"

# Create desktop shortcut
$desktop = [Environment]::GetFolderPath("Desktop")
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$desktop\Sierra LED Driver.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$bravoDir\SierraLED.ps1`""
$shortcut.Description = "Sierra TPM LED Driver for MSFS 2024"
$shortcut.Save()
Write-Host "Desktop shortcut created: 'Sierra LED Driver'"

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:"
Write-Host "  1. Start MSFS and load a flight"
Write-Host "  2. Double-click 'Sierra LED Driver' on your desktop"
Write-Host "  3. LEDs will activate within a few seconds"
Write-Host ""
Write-Host "If BravoLED.exe ran previously, unplug Sierra for 30 seconds first."
