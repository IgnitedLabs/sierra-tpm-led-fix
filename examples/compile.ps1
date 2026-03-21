# Sierra TPM LED Fix — Compile Step
# Compiles SierraLED.cs into an executable for the BravoLED community package folder
#
# Run with: powershell -ExecutionPolicy Bypass -File examples/compile.ps1

$bravoDir = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\Packages\Community\BravoLED"
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /nologo /optimize /target:winexe /out:"$bravoDir\SierraLED.exe" SierraLED.cs
