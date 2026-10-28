# GTA IV RTX Remix: DLSS Frame Generation shimmer fix

**A GTA IV focused fork of the RTX Remix runtime for smoother looking DLSS 5 Neural Rendering and 2× Frame Generation.**

[**Download the latest release**](https://github.com/FrsrG/dxvk-remix/releases/latest) · [Install guide](#installation) · [What changed](#why-use-it) · [Source and credits](#source-and-credits)

> [!IMPORTANT]
> This is a **runtime patch for [GTA IV RTX Remix Compatibility Mod v1.5.2](https://github.com/xoxor4d/gta4-rtx/releases/tag/v1.5.2)**, not a standalone GTA IV mod or installer. Install the original compatibility mod first. This fork was tested with **GTA IV: The Complete Edition 1.2.0.59**.

## Why use it?

GTA IV with RTX Remix can render at a low base frame rate, making DLSS Frame Generation useful for smoother displayed motion. In the GTA IV runtime, the ray-traced motion buffer contains **pixel-space** motion vectors, but the DLSS Frame Generation call was passing a scale of 1 for each axis. This fork passes the reciprocal motion-buffer dimensions, as required for pixel-space vectors by [NVIDIA's DLSS-G integration guide](https://github.com/NVIDIA-RTX/Streamline/blob/main/docs/ProgrammingGuideDLSS_G.md#70-provide-common-constants).

On the tested RTX 5070 / Ryzen 7 9800X3D setup, this change removed the observed moving-vehicle shimmer with **DLSS 5 Neural Rendering and 2× Frame Generation enabled**. The change improves Frame Generation input quality; **it does not increase the game's native rendered FPS**, and other hardware or scenes may behave differently.

## Download

1. Open the [**latest release**](https://github.com/FrsrG/dxvk-remix/releases/latest).
2. Under **Assets**, download **GTAIV-RTX-Remix-FG-Shimmer-Fix-1.5.2-r1.zip**.
3. Use the ZIP asset for installation. GitHub's automatically generated “Source code” ZIP is for developers and does **not** contain the compiled DLL.

The release ZIP contains the replacement **.trex/d3d9.dll**, an install note, checksums, and license notices. It is a small patch package, not the full compatibility mod.

## Installation

### First-time setup

1. Install **GTA IV: The Complete Edition 1.2.0.59**.
2. Install [**GTA IV RTX Remix Compatibility Mod v1.5.2**](https://github.com/xoxor4d/gta4-rtx/releases/tag/v1.5.2) using its installer or manual instructions. Follow its prompts to install the **required base Remix mod**. Its RTX Remix tailored FusionFix is recommended.
3. If you want **DLSS 5 Neural Rendering**, follow the original mod's instructions for providing **nvngx_dlssnr.dll** yourself. That DLL is not included here.
4. Launch the game through Steam once to confirm the original mod works, then close it.

### Apply this fork

1. Close GTA IV, the Rockstar launcher, and any RTX Remix bridge process.
2. Find the folder containing **GTAIV.exe**. A typical Steam path is **C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto IV\GTAIV**.
3. Back up **.trex/d3d9.dll** from that folder (for example, copy it to **d3d9.dll.before-fg-fix** somewhere safe).
4. Extract the release ZIP **into the folder containing GTAIV.exe**. Allow it to replace **.trex/d3d9.dll**.
5. Launch GTA IV through Steam. In the RTX Remix menu (**Alt+X**), enable Neural Rendering and DLSS Frame Generation at **2×**, then test a moving vehicle.

> [!CAUTION]
> Replace **GTAIV/.trex/d3d9.dll** only. **GTAIV/d3d9.dll** next to GTAIV.exe is the 32-bit bridge; this patch does not replace that file.

For users who set options in **user.conf**, the relevant values are:

~~~ini
rtx.neuralUplift.enable = True
rtx.dlfg.enable = True
rtx.dlfg.maxInterpolatedFrames = 1
~~~

The last value means one generated frame between rendered frames, or **2× Frame Generation**. Keep your existing graphics choices; these lines are not a performance preset.

## Undo or update

Close the game and restore your backed-up **.trex/d3d9.dll**. Reinstalling or updating the original compatibility mod may also replace this DLL; reapply a compatible release of this fork afterward. Do not apply this v1.5.2 patch to a different compatibility-mod release without checking compatibility.

## Troubleshooting

- **Game will not start:** Launch from Steam, confirm that the unmodified v1.5.2 mod works, and check that only **.trex/d3d9.dll** was replaced. Restore your backup if needed.
- **Neural Rendering unavailable:** This fork does not supply **nvngx_dlssnr.dll**; see the original mod's v1.5.2 instructions.
- **Shimmer remains:** Record a short clip of a moving vehicle with Frame Generation on, then briefly off in the same scene. Include your GPU, resolution, DLSS mode, and mod version in an issue. This distinguishes Frame Generation artifacts from artifacts already present in rendered frames.
- **Low native FPS:** Frame Generation raises displayed FPS but cannot make the underlying renderer faster. The [compatibility mod's wiki](https://github.com/xoxor4d/gta4-rtx/wiki/Troubleshooting---Guides) covers game-specific performance and stutter options.

## Source and credits

The change is in [**rtx_dlfg.cpp**](https://github.com/FrsrG/dxvk-remix/blob/fix/dlfg-motion-vector-scale-gta4-1.5.2/src/dxvk/rtx_render/rtx_dlfg.cpp). The release is built from the GTA IV runtime source matching the compatibility mod's v1.5.2 build, with this targeted motion-vector correction.

This project is a fork of [xoxor4d/dxvk-remix](https://github.com/xoxor4d/dxvk-remix), which includes work from [Remix Plus](https://github.com/RemixProjGroup/dxvk-remix) and [NVIDIA RTX Remix](https://github.com/NVIDIAGameWorks/dxvk-remix). The GTA IV integration, assets, and installer come from [xoxor4d/gta4-rtx](https://github.com/xoxor4d/gta4-rtx) and its credited contributors. This fork is not an official NVIDIA or gta4-rtx release. Source license and third-party notices are included in the repository and release package.

Developers can clone this branch with submodules:

~~~powershell
git clone --recurse-submodules --branch fix/dlfg-motion-vector-scale-gta4-1.5.2 https://github.com/FrsrG/dxvk-remix.git
~~~

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) and the [Windows build workflow](.github/workflows/build.yml) for build details.
