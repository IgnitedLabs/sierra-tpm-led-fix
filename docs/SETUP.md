# Sierra TPM LED Driver for MSFS 2024 — Setup Guide

## Overview

The official Honeycomb BravoLED.exe driver (v1.03) may not work correctly with the Sierra TPM Module in MSFS 2024. The gear indicator LEDs remain unresponsive because BravoLED.exe uses the wrong HID protocol for the Sierra hardware.

This unoficial replacement driver (SierraLED.exe) fixes the issue and integrates with MSFS the same way BravoLED does — MSFS auto-launches it when you load a flight. No manual steps needed after installation.

## Requirements

- Windows 10/11 (64-bit)
- Honeycomb Sierra TPM Module
- Microsoft Flight Simulator 2024 (MS Store edition)
- .NET Framework 4.0+ (included with Windows)
- Official BravoLED community package installed (provides folder structure)

## Installation

### Step 1: Download SierraLED.cs

Save the `SierraLED.cs` source file to your Downloads folder.

### Step 2: Compile

Open PowerShell and run:

```powershell
$bravoDir = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\Packages\Community\BravoLED"
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /nologo /optimize /target:winexe /out:"$bravoDir\SierraLED.exe" "$env:USERPROFILE\Downloads\SierraLED.cs"
```

Note: The `/target:winexe` flag makes it a silent Windows application with no console window.

### Step 3: Update exe.xml

MSFS uses `exe.xml` to register addon executables. Update it to point to SierraLED.exe instead of BravoLED.exe:

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

### Step 4: Initial Device Reset

If BravoLED.exe has previously run on this system, the Sierra's LED controller may be in a stuck state. Perform a one-time reset:

1. Close MSFS completely
2. Unplug the Sierra TPM USB cable
3. Wait 30 seconds
4. Plug it back in

This is only needed once. After that, as long as BravoLED.exe never runs, the device stays in a clean state.

### Step 5: Fly

Start MSFS and load a flight. MSFS will auto-launch SierraLED.exe. You may see a one-time warning about an unknown binary — dismiss it. The LEDs will activate once the flight loads.

## LED Behavior

| Gear State | Left LED | Center LED | Right LED |
|---|---|---|---|
| Down and locked | Green | Green | Green |
| In transit | Red | Red | Red |
| Up and stowed | Off | Off | Off |
| No electrical power | Off | Off | Off |

Each gear is indicated independently — during a gear cycle you may see a mix of red and green as each gear locks at different times.

## How It Works

1. MSFS reads `exe.xml` at startup and launches `SierraLED.exe` as a background process
2. SierraLED connects to the Sierra TPM via HID
3. SierraLED connects to SimConnect via `SimConnect_internal.dll`
4. It subscribes to `ELECTRICAL TOTAL LOAD AMPS`, `GEAR LEFT POSITION`, `GEAR CENTER POSITION`, and `GEAR RIGHT POSITION`
5. Gear positions are translated to LED states and sent as HID Output Reports
6. When MSFS closes, SierraLED detects the SimConnect disconnect, turns off the LEDs, and exits

## Restoring the Original BravoLED

To revert to the original (non-working) BravoLED setup:

```powershell
$bravoDir = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\Packages\Community\BravoLED"
$exeXml = "$env:LOCALAPPDATA\Packages\Microsoft.Limitless_8wekyb3d8bbwe\LocalCache\exe.xml"

$xmlContent = @"
<SimBase.Document Type="SimConnect" version="1,0">
        <Descr>SimConnect</Descr>
        <Filename>SimConnect.xml</Filename>
        <Disabled>False</Disabled>
        <Launch.Addon>
                <Name>BravoLED</Name>
                <Disabled>false</Disabled>
                <Path>$bravoDir\BravoLED.exe</Path>
        </Launch.Addon>
</SimBase.Document>
"@

Set-Content $exeXml -Value $xmlContent
```

## Troubleshooting

### LEDs don't respond at all
The Sierra may be in a stuck state from a previous BravoLED session. Unplug the Sierra for 30 seconds and plug it back in.

### LEDs stay on after MSFS closes
The driver detects MSFS exit via SimConnect timeout and turns LEDs off. If MSFS crashes abruptly, the driver may not get a chance to clean up. Simply unplug and replug the Sierra, or restart MSFS (the driver will reset the LEDs on next launch).

### "Unknown binary" warning in MSFS
This is expected — our exe is not code-signed by Honeycomb. Dismiss the warning. It does not prevent the driver from working.

### MSFS update overwrites exe.xml
If an MSFS update or BravoLED package update resets exe.xml, repeat Step 3 to re-register SierraLED.exe.

### Different MSFS install path
If MSFS is installed somewhere other than `C:\XboxGames\Microsoft Flight Simulator 2024\`, edit the SimConnect DLL path in `SierraLED.cs` before compiling (search for `SimConnect_internal.dll`).

### Aircraft with fixed gear
Aircraft like the Cessna 172 have permanently extended gear. The LEDs will show solid green, which is correct — the gear is always down and locked.
