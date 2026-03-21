<p align="center">
        <img src="ignitedlabs-icon.png" alt="IgnitedLabs" width="120" />
</p>

# Sierra TPM LED Fix

Unofficial community driver for **Honeycomb Sierra TPM Module** gear indicator LEDs in **Microsoft Flight Simulator 2024**.

The official `BravoLED.exe` (v1.03) may not work correctly with Sierra TPM LED control due to HID report mapping differences.

This project addresses three observed issues:

1. **Wrong report type** — BravoLED sends Feature Reports; Sierra needs Output Reports
2. **Wrong byte offset** — BravoLED writes LED data to byte[1]; Sierra reads byte[2]
3. **Feature Reports disable LEDs** — BravoLED's writes actively brick the LED controller until power-cycled

## Disclaimer

- This is an **unofficial** project and is **not affiliated with, endorsed by, or supported by Honeycomb Aeronautical, Microsoft, Asobo Studio, or any related partner**.
- This software is provided **as-is**, without warranty of any kind.
- You are responsible for testing on your own system before regular use.
- The maintainers are **not responsible** for any direct or indirect damage, malfunction, data loss, flight-sim instability, or peripheral behavior caused by installation or use.

## Compatibility and Future Updates

- Compatibility is based on the currently tested software and hardware behavior at the time of development.
- **No guarantee is provided for future compatibility** with:
        - Microsoft Flight Simulator updates
        - Honeycomb firmware or driver updates
        - changes in BravoLED package behavior
        - Windows HID/USB stack changes
- Future vendor updates may break this workaround at any time.
- If official vendor support later resolves these issues, prefer the official solution.

## Legal and Trademarks

- All product names, logos, and brands are property of their respective owners.
- "Honeycomb", "Sierra", "Microsoft Flight Simulator", and related marks are used only for descriptive compatibility purposes.
- This repository distributes only project-authored code and documentation under the license shown below.

## Requirements

- Windows 10/11 (64-bit)
- Honeycomb Sierra TPM Module
- Microsoft Flight Simulator 2024 (MS Store edition)
- .NET Framework 4.0+ (included with Windows)
- Official BravoLED community package installed (provides folder structure)

## Quick Start

### 1. Compile

```powershell
$bravoDir = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\Packages\Community\BravoLED"
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /nologo /optimize /target:winexe /out:"$bravoDir\SierraLED.exe" SierraLED.cs
```

### 2. Register with MSFS

```powershell
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
```

### 3. One-time device reset

If BravoLED.exe has previously run on this system, the Sierra's LED controller may be in a stuck state. Perform a one-time reset:

1. Close MSFS completely
2. Unplug the Sierra TPM USB cable
3. Wait 30 seconds
4. Plug it back in

### 4. Fly

Start MSFS, load a flight. LEDs work automatically.

## LED Behavior

| Gear State | LEDs |
|---|---|
| Down and locked | Green |
| In transit | Red |
| Up and stowed | Off |
| No electrical power | Off |

Each gear (left, center, right) is indicated independently.

## How It Works

MSFS auto-launches SierraLED.exe via `exe.xml`. It connects to SimConnect using `SimConnect_internal.dll`, subscribes to gear position and electrical data, and sends HID Output Reports to the Sierra's Collection 02 interface. When MSFS closes, LEDs are turned off and the driver exits.

## Support Scope

- This is a best-effort community project.
- Issues and pull requests may be limited or curated by maintainers.
- No SLA, no guaranteed turnaround, and no long-term compatibility commitment is implied.

## Documentation

- [Setup Guide](docs/SETUP.md) — Detailed installation instructions
- [Technical Report](docs/TECHNICAL_REPORT.md) — Root cause analysis

## License

MIT

