# Sierra TPM LED Compatibility Report — MSFS 2024

## Summary

The Honeycomb Sierra TPM Module gear indicator LEDs do not function in Microsoft Flight Simulator 2024 when using BravoLED.exe v1.03. Through reverse engineering and systematic hardware testing, we identified three root causes and built a working replacement driver.

## Device Information

| Property | Value |
|---|---|
| Product | Honeycomb Sierra TPM Module |
| USB VID/PID | 294B / 190D |
| HID Interface | Collection 02 (Vendor-Defined) |
| Output Report | ID 101 (0x65), 63 bytes |
| Feature Report | ID 101 (0x65), 64 bytes |

## Root Causes

### Issue 1: Wrong HID Report Type

BravoLED.exe sends LED data using `HidD_SetFeature()` (Feature Reports, 64 bytes). The Sierra TPM requires `HidD_SetOutputReport()` (Output Reports, 63 bytes). Feature Reports are accepted by the Sierra without error but have no effect on the LEDs.

BravoLED.exe dynamically loads `hid.dll` via `LoadLibrary`/`GetProcAddress` and resolves `HidD_SetFeature`. This is correct for the Bravo Throttle Quadrant but incorrect for the Sierra.

### Issue 2: Wrong LED Data Byte Offset

BravoLED.exe places LED control bits in **byte[1]** of the HID report buffer (first data byte after the Report ID). On the Sierra TPM, LED control bits must be in **byte[2]** (second data byte after the Report ID).

### Issue 3: Feature Reports Disable the LED Controller

This is the most critical finding. Sending any Feature Report to the Sierra TPM actively disables its LED controller. Once a Feature Report is sent, subsequent Output Reports are silently accepted but produce no visible LED change. The device remains in this disabled state until it is power-cycled (USB unplug for 30+ seconds) or reset via the Windows PnP device manager.

Since BravoLED.exe continuously sends Feature Reports while running, it actively prevents the LEDs from ever working — even if the report type and byte offset were corrected in a subsequent write.

## Correct Sierra LED Protocol

### Report Structure

| Byte | Purpose |
|---|---|
| 0 | Report ID: always 101 (0x65) |
| 1 | Unused (must be 0x00) |
| 2 | LED control bits (see below) |
| 3–62 | Unused (zeros) |

Report type: **Output Report** via `HidD_SetOutputReport()`, 63 bytes total.

### LED Bit Mapping (byte[2])

| Bit | Hex | LED |
|---|---|---|
| 0 | 0x01 | Left GREEN |
| 1 | 0x02 | Left RED |
| 2 | 0x04 | Center GREEN |
| 3 | 0x08 | Center RED |
| 4 | 0x10 | Right GREEN |
| 5 | 0x20 | Right RED |
| 6–7 | — | Unused |

### Common Patterns

| Pattern | Byte[2] Value | Meaning |
|---|---|---|
| All green | 0x15 | Gear down and locked |
| All red | 0x2A | Gear in transit |
| All off | 0x00 | Gear up / no electrical power |
| All LEDs on | 0x3F | Both colors, all positions |

## Bravo vs Sierra Comparison

| Property | Bravo Throttle Quadrant | Sierra TPM |
|---|---|---|
| API Function | `HidD_SetFeature` | `HidD_SetOutputReport` |
| Report Size | 64 bytes | 63 bytes |
| LED Data Byte | byte[1] | byte[2] |
| Feature Reports | Used for LED control | **Disable LED controller** |
| Bit Mapping | Same bit assignments | Same bit assignments |

## Recommendations for BravoLED.exe

To add Sierra TPM support, BravoLED.exe needs these changes:

1. **Device detection**: At startup, check the connected device PID.
   - PID 1901 = Bravo Throttle Quadrant → use existing Feature Report protocol
   - PID 190D = Sierra TPM → use Output Report protocol (see below)

2. **For Sierra devices**:
   - Use `HidD_SetOutputReport()` instead of `HidD_SetFeature()`
   - Send 63-byte buffers instead of 64-byte buffers
   - Place LED control bits in byte[2] instead of byte[1]
   - **Never send Feature Reports** — they disable the LED controller

3. **Important**: If the device has been in a session where Feature Reports were sent, a device power cycle or PnP reset is required before Output Reports will take effect. Consider adding a `HidD_FlushQueue()` or PnP reset at startup as a recovery mechanism.

## SimConnect Integration Notes

BravoLED.exe does not use the SimConnect SDK DLL. It loads `SimConnect_internal.dll` from the MSFS Content directory and connects via raw TCP/pipe (WS2_32.dll). The data structure offsets for `SIMCONNECT_RECV_SIMOBJECT_DATA` are:

| Offset | Type | Field |
|---|---|---|
| 0 | DWORD | dwSize |
| 4 | DWORD | dwVersion |
| 8 | DWORD | dwID (8 = SIMOBJECT_DATA, 3 = QUIT) |
| 40 | FLOAT64 | First data variable |
| 48 | FLOAT64 | Second data variable |
| 56 | FLOAT64 | Third data variable |
| 64 | FLOAT64 | Fourth data variable |

Note: dwID=2 is the OPEN confirmation message, not QUIT. The first message received after `SimConnect_Open` will always be dwID=2.

The `SIMCONNECT_PERIOD_SIM_FRAME` constant is 3 (not 5 as in some documentation).

## Methodology

All findings were derived from black-box testing: HID descriptor analysis, PE binary reverse engineering of BravoLED.exe (to identify the dynamic `HidD_SetFeature` loading pattern), USB protocol testing with systematic bit-mapping of all 63 report bytes, and SimConnect raw message capture. No proprietary source code was accessed.

