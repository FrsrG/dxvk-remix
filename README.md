# GTA IV RTX Remix: DLSS Frame Generation shimmer fix

**A GTA IV focused fork of the RTX Remix runtime for smoother looking DLSS 5 Neural Rendering and 2× Frame Generation.**

[**Download the latest release**](https://github.com/FrsrG/dxvk-remix/releases/latest) · [Install guide](#installation) · [What changed](#why-use-it) · [Source and credits](#source-and-credits)

> [!IMPORTANT]
> This is a **runtime patch for [GTA IV RTX Remix Compatibility Mod v1.5.2](https://github.com/xoxor4d/gta4-rtx/releases/tag/v1.5.2)**. The easy setup downloads that original mod and runs its installer when needed. This fork was tested with **GTA IV: The Complete Edition 1.2.0.59**.

## Why use it?

GTA IV with RTX Remix can render at a low base frame rate, making DLSS Frame Generation useful for smoother displayed motion. In the GTA IV runtime, the ray-traced motion buffer contains **pixel-space** motion vectors, but the DLSS Frame Generation call was passing a scale of 1 for each axis. This fork passes the reciprocal motion-buffer dimensions, as required for pixel-space vectors by [NVIDIA's DLSS-G integration guide](https://github.com/NVIDIA-RTX/Streamline/blob/main/docs/ProgrammingGuideDLSS_G.md#70-provide-common-constants).

On the tested RTX 5070 / Ryzen 7 9800X3D setup, this change removed the observed moving-vehicle shimmer with **DLSS 5 Neural Rendering and 2× Frame Generation enabled**. The change improves Frame Generation input quality; **it does not increase the game's native rendered FPS**, and other hardware or scenes may behave differently.

## Download

1. Open the [**latest release**](https://github.com/FrsrG/dxvk-remix/releases/latest).
2. Under **Assets**, download **GTAIV-RTX-Remix-FG-Fix-1.5.2-r2.zip**.
3. Extract the ZIP anywhere outside the game folder and run **Install.cmd**. GitHub's automatically generated “Source code” ZIP is for developers and does **not** contain the compiled DLL.

The release ZIP contains the replacement **.trex/d3d9.dll**, a setup script, an automatic restore script, checksums, and license notices. It downloads the original compatibility mod from its official release when needed. You do not need to download or back up the original files manually.

## Installation

### Easy setup

1. Install **GTA IV: The Complete Edition 1.2.0.59** and close the game.
2. Download the release ZIP above, extract it to a folder such as Downloads, and double-click **Install.cmd**.
3. Select the game's **GTAIV.exe** when prompted. A typical Steam path is **C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto IV\GTAIV\GTAIV.exe**.
4. If the original compatibility mod is not already installed at v1.5.2, setup downloads its official ZIP and installer, verifies their checksums, then opens that installer. Select the **same GTAIV.exe** again, choose a full install if asked, and accept the **required base Remix mod**. Its RTX Remix tailored FusionFix is recommended.
5. To use **DLSS 5 Neural Rendering**, supply **nvngx_dlssnr.dll** yourself as described by the [original mod](https://github.com/xoxor4d/gta4-rtx/releases/tag/v1.5.2). After setup finishes, copy the DLL into the **.trex** folder inside your **GTAIV** game folder, so its path is **GTAIV/.trex/nvngx_dlssnr.dll**. For the typical Steam install, that is **C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto IV\GTAIV\.trex\nvngx_dlssnr.dll**. Do not put it beside **GTAIV.exe** or in the folder where you extracted this release ZIP.
6. Launch through Steam. In the RTX Remix menu (**Alt+X**), enable Neural Rendering and **2× DLSS Frame Generation**.

If v1.5.2 is already installed, setup only saves the previous runtime and applies this fix; it does not redownload the full mod. The setup script saves the previous runtime automatically, and **Restore.cmd** restores it. No manual backup is needed. The official mod download is about 549 MB; its base Remix mod is downloaded separately by the official installer on a fresh setup.

**nvngx_dlssnr.dll** is not included in this package or downloaded by setup.

The setup script downloads only from the official xoxor4d release, checks the release files against pinned SHA-256 values, and creates a local patched installer ZIP. Its [source](installer/Install.ps1) is available for review.

### Manual install (advanced)

If you prefer to install without the setup script, install the [original v1.5.2 compatibility mod](https://github.com/xoxor4d/gta4-rtx/releases/tag/v1.5.2) and its base mod first. Close GTA IV, back up **GTAIV/.trex/d3d9.dll**, then copy **.trex/d3d9.dll** from this release ZIP into the **GTAIV** folder containing **GTAIV.exe**.

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

Close the game and run **Restore.cmd** to put back the runtime saved by setup. For a manual install, restore the backup you made yourself. Reinstalling or updating the original compatibility mod may also replace this DLL; reapply a compatible release of this fork afterward. Do not apply this v1.5.2 patch to a different compatibility-mod release without checking compatibility.

## Troubleshooting

- **Game will not start:** Launch from Steam, confirm that the unmodified v1.5.2 mod works, and check that only **.trex/d3d9.dll** was replaced. Run **Restore.cmd** if needed.
- **Neural Rendering unavailable:** Confirm your supplied DLL is at **GTAIV/.trex/nvngx_dlssnr.dll**, then check the original mod's v1.5.2 instructions.
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
