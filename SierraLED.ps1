# Sierra TPM LED Driver for MSFS 2024
# Launch via desktop shortcut or: powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File SierraLED.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$csFile = Join-Path $scriptDir "SierraLED.cs"

if (-not (Test-Path $csFile)) {
    Write-Host "ERROR: SierraLED.cs not found in $scriptDir" -ForegroundColor Red
    exit 1
}

# Auto-discover SimConnect_internal.dll
$simConnectPath = $null
$searchRoots = @("C:\XboxGames", "D:\XboxGames", "E:\XboxGames", "C:\Program Files", "D:\Program Files")
foreach ($root in $searchRoots) {
    if (Test-Path $root) {
        $found = Get-ChildItem $root -Filter "SimConnect_internal.dll" -Recurse -Depth 4 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $simConnectPath = $found.FullName; break }
    }
}

if (-not $simConnectPath) {
    Write-Host "ERROR: SimConnect_internal.dll not found" -ForegroundColor Red
    exit 1
}

# Read C# source and inject the correct SimConnect path
$csCode = Get-Content $csFile -Raw
$csCode = $csCode -replace 'C:\\XboxGames\\Microsoft Flight Simulator 2024\\Content\\SimConnect_internal\.dll', ($simConnectPath -replace '\\', '\\')

try {
    Add-Type -TypeDefinition $csCode -ReferencedAssemblies System.Runtime.InteropServices
} catch {
    Write-Host "ERROR: Failed to compile: $_" -ForegroundColor Red
    exit 1
}

[SierraLEDDriver]::Main(@())
