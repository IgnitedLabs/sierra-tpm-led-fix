# Sierra TPM LED Driver for MSFS 2024 — Setup Guide

## Overview

The official Honeycomb BravoLED.exe driver (v1.03) does not work correctly with the Sierra TPM Module in MSFS 2024. The gear indicator LEDs remain unresponsive because BravoLED.exe uses the wrong HID protocol for the Sierra hardware. Worse, BravoLED's Feature Report writes actively disable the Sierra's LED controller.

This replacement driver fixes all three issues and runs alongside MSFS via a desktop shortcut.

## Requirements

- Windows 10/11 (64-bit)
- Honeycomb Sierra TPM Module (USB VID 294B / PID 190D)
- Microsoft Flight Simulator 2024 (MS Store / Xbox edition)
- .NET Framework 4.0+ (included with Windows)
- The official BravoLED community package already installed (provides the folder structure and `exe.xml` registration)

## Automatic Installation

Clone or download this repository, open PowerShell, and ensure script execution is allowed:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

Then navigate to the repo directory and run:

```powershell
cd sierra-tpm-led-fix
.\install.ps1
```

The installer auto-detects your MSFS installation paths and will:
1. Copy `SierraLED.cs` and `SierraLED.ps1` to the BravoLED community folder
2. Disable BravoLED.exe in `exe.xml` to prevent it from poisoning the LED controller
3. Create a "Sierra LED Driver" desktop shortcut

## Manual Installation

### Step 1: Find Your MSFS Paths

```powershell
$msfsPackage = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Microsoft.Limitless*" -Directory | Select-Object -First 1
$bravoDir = Join-Path $msfsPackage.FullName "LocalCache\Packages\Community\BravoLED"
$exeXml = Join-Path $msfsPackage.FullName "LocalCache\exe.xml"
Write-Host "BravoLED dir: $bravoDir"
Write-Host "exe.xml: $exeXml"
```

### Step 2: Copy Driver Files

```powershell
Copy-Item SierraLED.cs "$bravoDir\SierraLED.cs"
Copy-Item SierraLED.ps1 "$bravoDir\SierraLED.ps1"
```

### Step 3: Disable BravoLED in exe.xml

BravoLED.exe must be disabled — its Feature Reports actively disable the Sierra's LED controller. Edit `exe.xml` and change `<Disabled>false</Disabled>` inside the `Launch.Addon` block to `<Disabled>true</Disabled>`.

### Step 4: Create Desktop Shortcut

```powershell
$desktop = [Environment]::GetFolderPath("Desktop")
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$desktop\Sierra LED Driver.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$bravoDir\SierraLED.ps1`""
$shortcut.Description = "Sierra TPM LED Driver for MSFS 2024"
$shortcut.Save()
```

### Step 5: Initial Device Reset

If BravoLED.exe has previously run on this system, the Sierra's LED controller will be in a stuck state. Perform a one-time reset:

1. Close MSFS completely
2. Unplug the Sierra TPM USB cable
3. Wait 30 seconds
4. Plug it back in

This is only needed once. As long as BravoLED.exe remains disabled, the device stays clean.

## Usage

1. Start MSFS and load a flight with any aircraft
2. Double-click **"Sierra LED Driver"** on your desktop
3. LEDs activate within a few seconds
4. When you close MSFS, the driver detects it, turns LEDs off, and exits

## LED Behavior

| Gear State | Left LED | Center LED | Right LED |
|---|---|---|---|
| Down and locked | Green | Green | Green |
| In transit | Red | Red | Red |
| Up and stowed | Off | Off | Off |
| No electrical power | Off | Off | Off |

Each gear is indicated independently — during a gear cycle you may see a mix of red and green as each gear locks at different times. Aircraft with fixed gear (like the Cessna 172) will show solid green.

## How It Works

The desktop shortcut launches `powershell.exe` (a Microsoft-signed binary trusted by Windows) which reads `SierraLED.cs`, compiles it in memory via .NET's `Add-Type`, and runs it. This bypasses Windows Application Control which blocks unsigned executables.

The driver then:
1. Connects to the Sierra TPM via HID (Collection 02, Vendor-Defined interface)
2. Auto-discovers and loads `SimConnect_internal.dll` from the MSFS install directory
3. Subscribes to electrical and gear position data
4. Translates gear positions to LED states sent as HID Output Reports (byte[2])
5. Monitors SimConnect for disconnect — when MSFS closes, LEDs are turned off

## Why Not exe.xml?

MSFS 2024 validates executables launched via `exe.xml` against Windows Application Control policies. Unsigned executables are blocked. Since this driver is not code-signed by Honeycomb, MSFS refuses to launch it. The PowerShell approach works because `powershell.exe` is signed by Microsoft and trusted by both MSFS and Windows.

## Restoring the Original

Run the uninstaller from the repo directory:

```powershell
.\uninstall.ps1
```

## Troubleshooting

### LEDs don't respond at all
The Sierra may be in a stuck state from a previous BravoLED session. Unplug the Sierra for 30 seconds and plug it back in.

### LEDs stay on after MSFS closes
The driver detects MSFS exit via SimConnect timeout (~5 seconds). If MSFS crashes abruptly, the cleanup may not run. Unplug and replug the Sierra, or restart MSFS.

### SimConnect not found
The driver auto-searches for `SimConnect_internal.dll` under common install locations (`C:\XboxGames`, `D:\XboxGames`, etc.). If your MSFS is installed elsewhere, check the `FindSimConnect()` method in `SierraLED.cs` and add your install path.

### Aircraft with fixed gear
Aircraft like the Cessna 172 have permanently extended gear. The LEDs will show solid green, which is correct.
