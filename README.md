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

## Requirements

- Windows 10/11 (64-bit)
- Honeycomb Sierra TPM Module
- Microsoft Flight Simulator 2024 (MS Store edition)
- .NET Framework 4.0+ (included with Windows)
- Official BravoLED community package installed (provides folder structure)

## Quick Start

### 1. Set Execution Policy (one-time)

If you haven't run PowerShell scripts before, open PowerShell and run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

### 2. Install

Clone this repo, then run the installer from PowerShell:

```powershell
cd sierra-tpm-led-fix
.\install.ps1
```

This will:
- Auto-discover your MSFS community folder
- Copy the driver files
- Disable BravoLED.exe in `exe.xml` (it breaks Sierra LEDs)
- Create a **"Sierra LED Driver"** shortcut on your desktop

### 3. One-time device reset

If BravoLED.exe has previously run, unplug the Sierra for 30 seconds and plug it back in.

### 4. Fly

1. Start MSFS and load a flight
2. Double-click **"Sierra LED Driver"** on your desktop
3. LEDs activate within a few seconds

The driver runs silently in the background and turns LEDs off when MSFS closes.

## Why a Desktop Shortcut?

MSFS 2024 blocks unsigned executables via Windows Application Control. Since our exe isn't code-signed, MSFS won't launch it. The desktop shortcut runs PowerShell (a Microsoft-signed binary) which compiles and runs the driver code in memory — bypassing the restriction entirely.

BravoLED.exe is disabled in `exe.xml` to prevent it from sending Feature Reports that disable the Sierra's LED controller.

## LED Behavior

| Gear State | LEDs |
|---|---|
| Down and locked | Green |
| In transit | Red |
| Up and stowed | Off |
| No electrical power | Off |

Each gear (left, center, right) is indicated independently.

## Documentation

- [Setup Guide](docs/SETUP.md) — Detailed installation instructions
- [Technical Report](docs/TECHNICAL_REPORT.md) — Root cause analysis

## Disclaimer

- This is an **unofficial** project and is **not affiliated with, endorsed by, or supported by Honeycomb Aeronautical, Microsoft, Asobo Studio, or any related partner**.
- This software is provided **as-is**, without warranty of any kind. You are responsible for testing on your own system before regular use.
- The maintainers are **not responsible** for any direct or indirect damage, malfunction, data loss, flight-sim instability, or peripheral behavior caused by installation or use.
- No proprietary code was copied — the driver is written entirely from scratch based on black-box hardware testing. No DLLs were modified.

## Compatibility and Future Updates

- Compatibility is based on tested software and hardware behavior at the time of development.
- **No guarantee is provided for future compatibility** with MSFS updates, Honeycomb firmware/driver updates, BravoLED package changes, or Windows HID/USB stack changes.
- If official vendor support later resolves these issues, prefer the official solution.

## Credits

This fix was developed through a collaborative reverse-engineering session using **Claude (Anthropic)** as an AI pair-programming assistant. The process involved HID protocol analysis, PE binary inspection of BravoLED.exe, systematic bit-level hardware testing, and iterative driver development — all conducted via conversation-driven debugging with real hardware feedback.

## Legal and Trademarks

- All product names, logos, and brands are property of their respective owners.
- "Honeycomb", "Sierra", "Microsoft Flight Simulator", and related marks are used only for descriptive compatibility purposes.
- This repository distributes only project-authored code and documentation under the license shown below.

## License

MIT
