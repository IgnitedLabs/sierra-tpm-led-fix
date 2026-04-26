# Sierra TPM LED Driver for MSFS 2024
# Launch via desktop shortcut or: powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File SierraLED.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$csFile = Join-Path $scriptDir "SierraLED.cs"

if (-not (Test-Path $csFile)) {
    Write-Host "ERROR: SierraLED.cs not found in $scriptDir" -ForegroundColor Red
    exit 1
}

# Auto-discover SimConnect_internal.dll across MS Store/Xbox AND Steam installs.
# Steam usually lives under "Program Files (x86)\Steam\steamapps\common", but
# Steam libraries can be on any drive — enumerate libraryfolders.vdf to cover all.
$simConnectPath = $null
$searchRoots = New-Object System.Collections.Generic.List[string]
$searchRoots.Add("C:\XboxGames")
$searchRoots.Add("D:\XboxGames")
$searchRoots.Add("E:\XboxGames")
$searchRoots.Add("C:\Program Files\WindowsApps")
$searchRoots.Add("D:\Program Files\WindowsApps")
$searchRoots.Add("C:\Program Files")
$searchRoots.Add("D:\Program Files")

# Steam: enumerate every configured library
$steamRoot = $null
foreach ($p in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
    if ($p) {
        $candidate = Join-Path $p "Steam"
        if (Test-Path $candidate) { $steamRoot = $candidate; break }
    }
}
if ($steamRoot) {
    $searchRoots.Add((Join-Path $steamRoot "steamapps\common"))
    $vdf = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $vdfText = Get-Content $vdf -Raw -ErrorAction SilentlyContinue
        if ($vdfText) {
            foreach ($m in [regex]::Matches($vdfText, '"path"\s+"([^"]+)"')) {
                $libPath = $m.Groups[1].Value -replace '\\\\', '\'
                $libCommon = Join-Path $libPath "steamapps\common"
                if (Test-Path $libCommon) { $searchRoots.Add($libCommon) }
            }
        }
    }
}

foreach ($root in $searchRoots) {
    if (-not (Test-Path $root)) { continue }
    # Xbox install uses 'Microsoft Flight Simulator 2024'; Steam install dir is
    # 'MSFS2024'. Accept either, case-insensitive.
    $found = Get-ChildItem $root -Filter "SimConnect_internal.dll" -Recurse -Depth 5 -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -imatch 'Flight Simulator|MSFS' } |
        Select-Object -First 1
    if ($found) { $simConnectPath = $found.FullName; break }
}

if (-not $simConnectPath) {
    Write-Host "ERROR: SimConnect_internal.dll not found" -ForegroundColor Red
    Write-Host "Searched:" -ForegroundColor Yellow
    foreach ($r in $searchRoots) { Write-Host "  $r" }
    exit 1
}

# Pass the resolved DLL path to the C# layer via env var. SierraLED.cs's
# FindSimConnect() reads SIERRA_SIMCONNECT_DLL first before doing its own search.
$env:SIERRA_SIMCONNECT_DLL = $simConnectPath

$csCode = Get-Content $csFile -Raw

try {
    Add-Type -TypeDefinition $csCode -ReferencedAssemblies System.Runtime.InteropServices
} catch {
    Write-Host "ERROR: Failed to compile: $_" -ForegroundColor Red
    exit 1
}

[SierraLEDDriver]::Main(@())
