# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NatNetFour2OSC is a Windows C# console application that bridges OptiTrack's NatNet motion capture protocol to Open Sound Control (OSC). It connects to OptiTrack Motive software and streams rigid bodies, skeletons, markers, and force plate data as OSC UDP packets for use in creative/interactive applications (MAX/MSP, Isadora, TouchDesigner, SPARCK, AMBI).

## Build

**Solution:** `NatNetFour2OSC.sln`  
**Project:** `src/NatNetFour2OSC.csproj`  
**Target:** .NET Framework 4.7.2, x64

MSBuild is not on PATH — use the full path:
```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" "NatNetFour2OSC.sln" /p:Configuration=Release /p:Platform=x64 /v:minimal
```

In VS Code, `Ctrl+Shift+B` runs **Build Release x64** via [.vscode/tasks.json](.vscode/tasks.json).  
Output: `bin/x64/NatNetFour2OSC.exe`. No test suite exists.

## Releasing

The single source of truth for the version is `AssemblyVersion` in [src/Properties/AssemblyInfo.cs](src/Properties/AssemblyInfo.cs).

To publish a release:
1. Update `AssemblyVersion` and `AssemblyFileVersion` in `AssemblyInfo.cs` (e.g. `"1.1.0"`)
2. Commit, then push a matching tag: `git tag v1.1.0 && git push --tags`

GitHub Actions ([.github/workflows/release.yml](.github/workflows/release.yml)) will build, zip `bin/x64/`, and publish a GitHub Release automatically. The workflow fails if the tag doesn't match `AssemblyVersion`.

## Running

Minimum required arguments:
```
NatNetFour2OSC.exe --localIP <this-machine-ip> --motiveIP <motive-server-ip> --oscSendIP <osc-dest-ip> --oscSendPort <port>
```

Key optional arguments with their defaults:
| Flag | Default | Purpose |
|------|---------|---------|
| `--oscMode` | `max` | Output format: `max`, `isadora`, `td`, `sparck`, `ambi` |
| `--frameModulo` | `1` | Send every Nth frame (reduces rate) |
| `--oscCtrlPort` | `65111` | Incoming OSC remote control port |
| `--multiCastIP` | `239.255.42.99` | NatNet multicast address |
| `--motiveDataPort` | `1511` | NatNet data port |
| `--bundled` | false | Bundle all OSC messages per frame |
| `--yup2zup` | false | Convert Y-up to Z-up coordinate system |
| `--leftHanded` | false | Convert to left-handed coordinate system |
| `--autoReconnect` | false | Automatically reconnect on stream loss |

## Architecture

The entire application logic lives in a single file: [src/NatNetFour2OSC.cs](src/NatNetFour2OSC.cs)

**Data flow:**
1. CLI args parsed via `CommandLine.dll` into an `Options` object
2. `NatNetML.NatNetClientML` connects to Motive (multicast or unicast)
3. `OnFrameReady` event fires per mocap frame (~120 Hz from Motive)
4. Frame data is filtered by `frameModulo`, then asset data (rigid bodies, skeletons, markers, force plates) is iterated
5. Each asset type is dispatched to a format-specific send method (e.g., `sendRigidBodyMax`, `sendRigidBodyTD`)
6. `SharpOSC` sends UDP packets to the configured destination

**External libraries** (pre-built DLLs in `lib/x64/`):
- `NatNetML.dll` — OptiTrack managed NatNet SDK
- `SharpOSC.dll` — OSC UDP send/receive
- `CommandLine.dll` — CLI argument parsing (NuGet, restored to `packages/`)

**OSC remote control:** A `SharpOSC.UDPListener` on `oscCtrlPort` accepts incoming OSC to change parameters at runtime and send commands to Motive (start/stop recording, set take name, etc.).

**Coordinate transforms:** `System.Numerics.Matrix4x4` and quaternion math handle Y-up↔Z-up and right/left-handed conversions. Optional forward/inverse matrix output is toggled with `--matrix` / `--invMatrix`.

**Dynamic asset discovery:** Asset lists (rigid bodies, skeletons, markers) are rebuilt on each `OnFrameReady` call if the asset count changes, allowing Motive to add/remove assets without restarting.
