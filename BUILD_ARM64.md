# Building Tsugaru ARM64 Handheld

This document describes how to build the ARM64 version of Tsugaru used by the **Tsugaru ARM64 Handheld** project.

The procedure below is based on the build environment actually used to build and test this release.

Tsugaru ARM64 Handheld is an unofficial modified build of Tsugaru and is not an official release by CaptainYS.

---

## 1. Tested Build Environment

The release was built using the following environment.

### Host

* LMDE 7 (Gigi)
* Debian 13 (Trixie) based
* x86_64 host

### Build Tools

* `aarch64-linux-gnu-gcc 14.2.0`
* `aarch64-linux-gnu-g++ 14.2.0`
* CMake 3.31.6
* Ninja 1.12.1

### Target

* AArch64 / ARM64
* GNU/Linux
* Dynamically linked ELF executable

The resulting executable uses:

```text
/lib/ld-linux-aarch64.so.1
```

as its dynamic loader.

---

## 2. Original Tsugaru Source

The original Tsugaru / TOWNSEMU project is developed by:

**CaptainYS (Soji Yamakawa)**

Original project:

https://github.com/captainys/TOWNSEMU

This package does not duplicate the complete original Tsugaru source tree.

Only the source files modified for the ARM64 handheld input implementation are included under:

```text
modified_source/
└── main_cui/
    ├── v90s_connection.cpp
    └── v90s_connection.h
```

The exact upstream Git commit used for the original development tree was not recorded.

The modified files included with this release correspond to the Tsugaru source tree that was used to build and test this release.

Because the upstream project may change over time, compatibility with future versions of the original Tsugaru source tree is not guaranteed.

See the included license and notice files:

```text
LICENSE_Tsugaru.txt
LICENSE_Modifications.txt
THIRD_PARTY_LICENSES.txt
```

---

## 3. ARM64 Handheld Modifications

The following original Tsugaru files were modified:

```text
main_cui/v90s_connection.cpp
main_cui/v90s_connection.h
```

The modifications add configurable Linux controller support using:

```text
/userdata/system/tsugaru/input.cfg
```

The modified input implementation supports:

* Configurable Linux event device
* Configurable A button code
* Configurable B button code
* Configurable START button code
* Configurable SELECT button code
* ABS-type D-pad input
* KEY-type D-pad input
* Configurable D-pad X/Y event codes
* Configurable KEY-type UP/DOWN/LEFT/RIGHT codes
* Reversed X-axis direction
* Reversed Y-axis direction
* Original V90S input-device path as a fallback

If `input.cfg` is unavailable, the original V90S device path is used:

```text
/dev/input/by-path/platform-adc_joystick-event-joystick
```

---

## 4. Apply the Modified Source Files

Obtain the original Tsugaru / TOWNSEMU source tree.

Replace the corresponding files in the source tree with the versions supplied by this project.

Copy:

```text
modified_source/main_cui/v90s_connection.cpp
```

to:

```text
TOWNSEMU/main_cui/v90s_connection.cpp
```

and copy:

```text
modified_source/main_cui/v90s_connection.h
```

to:

```text
TOWNSEMU/main_cui/v90s_connection.h
```

It is recommended that the original files be backed up before replacement.

The supplied modified files were tested with the source tree used for this release. They should not be assumed to be compatible with every future upstream version without checking the differences first.

---

## 5. Required Cross-Compilation Environment

An AArch64 GNU/Linux cross-compilation environment is required.

The tested compilers were:

```text
aarch64-linux-gnu-gcc 14.2.0
aarch64-linux-gnu-g++ 14.2.0
```

CMake and Ninja are also required.

ARM64 ALSA development files are required for the audio backend.

On the tested LMDE 7 system, the ARM64 ALSA library was located at:

```text
/usr/lib/aarch64-linux-gnu/libasound.so
```

The actual files on the tested system were:

```text
/usr/lib/aarch64-linux-gnu/libasound.so
/usr/lib/aarch64-linux-gnu/libasound.so.2
/usr/lib/aarch64-linux-gnu/libasound.so.2.0.0
```

---

## 6. CMake Toolchain File

Create:

```text
toolchain-aarch64.cmake
```

in the working directory containing the Tsugaru source and build directories.

The tested toolchain file is:

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_ASM_COMPILER aarch64-linux-gnu-gcc)

set(CMAKE_C_FLAGS_INIT "")
set(CMAKE_CXX_FLAGS_INIT "")

set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
```

This is the toolchain configuration used by the tested build.

---

## 7. Configure the Build

Assuming the Tsugaru source directory is named:

```text
src
```

and `toolchain-aarch64.cmake` is in the directory above it, create a separate build directory:

```bash
mkdir -p build-arm64
cd build-arm64
```

Configure with CMake:

```bash
cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=../toolchain-aarch64.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DALSALIB=/usr/lib/aarch64-linux-gnu/libasound.so \
  ../src
```

The tested configuration used:

```text
CMAKE_BUILD_TYPE=Release
ALSALIB=/usr/lib/aarch64-linux-gnu/libasound.so
```

If the source directory or ARM64 ALSA library is installed in a different location, adjust the paths accordingly.

---

## 8. Build Tsugaru_CUI_V90S

Build the handheld CUI target:

```bash
ninja Tsugaru_CUI_V90S
```

The target `Tsugaru_CUI_V90S` is defined by:

```text
main_cui/CMakeLists.txt
```

in the source tree used for this release.

After a successful build, the executable should be located at:

```text
main_cui/Tsugaru_CUI_V90S
```

---

## 9. Verify the ARM64 Binary

Check the generated executable:

```bash
file main_cui/Tsugaru_CUI_V90S
```

The tested release reports an executable similar to:

```text
ELF 64-bit LSB pie executable, ARM aarch64,
dynamically linked,
interpreter /lib/ld-linux-aarch64.so.1
```

This confirms that the executable was generated for AArch64 / ARM64.

### Check Runtime Libraries

Because the executable is ARM64 while the build host is x86_64, the host `ldd` command may not provide useful results.

Use the AArch64 `readelf` tool instead:

```bash
aarch64-linux-gnu-readelf -d \
  main_cui/Tsugaru_CUI_V90S | grep NEEDED
```

The tested binary requires:

```text
libasound.so.2
libstdc++.so.6
libm.so.6
libgcc_s.so.1
libc.so.6
```

These are runtime system libraries.

They are not bundled with the Tsugaru ARM64 Handheld package.

---

## 10. Install the Executable

On the handheld, the expected Tsugaru directory is:

```text
/userdata/system/tsugaru
```

Copy the generated executable to:

```text
/userdata/system/tsugaru/Tsugaru_CUI_V90S
```

Copy:

```text
scripts/launch_fmtowns.sh
```

to:

```text
/userdata/system/tsugaru/launch_fmtowns.sh
```

If necessary, make both files executable:

```bash
chmod +x /userdata/system/tsugaru/Tsugaru_CUI_V90S
chmod +x /userdata/system/tsugaru/launch_fmtowns.sh
```

---

## 11. Controller Configuration

The package includes:

```text
scripts/input_test_v9.sh
```

Copy it to:

```text
/userdata/roms/ports/input_test_v9.sh
```

Run `input_test_v9.sh` from the **PORTS** menu in KNULLI.

Follow the controller prompts displayed on screen.

The calibration sequence configures:

```text
SELECT
UP
DOWN
LEFT
RIGHT
A
B
START
L1
R1
L2
R2
```

After successful calibration, the script creates:

```text
/userdata/system/tsugaru/input.cfg
```

An ABS-type configuration may look similar to:

```ini
EVENT="/dev/input/event4"
A_CODE=304
B_CODE=305
SELECT_CODE=314
START_CODE=315
L1_CODE=310
R1_CODE=311
L2_CODE=312
R2_CODE=313
DPAD_TYPE=ABS
DPAD_X_CODE=16
DPAD_Y_CODE=17
DPAD_X_REVERSE=0
DPAD_Y_REVERSE=0
```

The actual values depend on the controller and device.

Do not copy example button codes blindly. Use `input_test_v9.sh` to generate the configuration for the target device.

---

## 12. EmulationStation Configuration

The package includes:

```text
config/es_systems_v90s.cfg
```

Copy it to:

```text
/userdata/system/configs/emulationstation/es_systems_v90s.cfg
```

The configuration registers FM TOWNS `.tsu` files with EmulationStation and launches them through:

```text
/userdata/system/tsugaru/launch_fmtowns.sh
```

Restart EmulationStation or reboot the handheld after installing the configuration.

---

## 13. BIOS

FM TOWNS BIOS files are not included with this project.

The expected BIOS directory is:

```text
/userdata/bios/fmtowns
```

Users must provide their own appropriate BIOS files.

---

## 14. Games and TSU Files

The expected game directory is:

```text
/userdata/roms/fmtowns
```

Each game may be stored in its own subdirectory together with its `.tsu` file and required media images.

Example:

```text
/userdata/roms/fmtowns/GameName/
├── GameName.tsu
├── disc1.cue
└── disc1.bin
```

BIOS files, games, copyrighted software, and game media are not included with this project.

---

## 15. Supported Media Used by the Launcher

The tested package supports the following media formats:

| Media          | Format                  |
| -------------- | ----------------------- |
| Floppy Disk    | `.d88`, `.hdm`          |
| CD-ROM         | `.iso`, `.cue` + `.bin` |
| Hard Disk      | `.h0`                   |
| IC Memory Card | `.icm`                  |

For BIN/CUE CD images, specify the `.cue` file rather than the `.bin` file in the `.tsu` configuration.

Keep the `.cue` and its corresponding `.bin` file or files together.

---

## 16. Multi-Disc Launcher Functions

`launch_fmtowns.sh` adds handheld-oriented media-switching functions.

The launcher recognizes additional TSU entries such as:

```text
-CDNEXT "disc2.cue"
-FD0NEXT "disk2.hdm"
-FD1NEXT "disk2.hdm"
```

These are launcher extensions and are not passed directly to Tsugaru as normal emulator command-line options.

The launcher handles the appropriate media-change commands through Tsugaru's command interface.

---

## 17. Controller Hotkeys

The launcher provides the following combinations:

| Hotkey         | Function        |
| -------------- | --------------- |
| SELECT + START | Exit Tsugaru    |
| SELECT + R1    | Next CD         |
| SELECT + L1    | Previous CD     |
| SELECT + R2    | Next floppy     |
| SELECT + L2    | Previous floppy |

For floppy switching, FD0 is used when multiple FD0 images are defined. Otherwise FD1 is used when multiple FD1 images are defined.

---

## 18. CMOS

The launcher uses:

```text
/userdata/system/tsugaru/cmos.dat
```

for persistent CMOS data.

The file is created as required and is not included in the distribution package.

---

## 19. Tested Hardware

### Powkiddy V90S

Tested with KNULLI.

Verified functions include:

* Controller input
* Controller calibration
* CD-ROM boot
* Floppy disk operation
* CD switching
* FD0 switching
* FD1 switching
* CMOS persistence
* HDD installation and persistence
* IC Memory Card operation
* SELECT + START clean exit

A complete installation was also tested successfully using a newly prepared MicroSD card with a fresh KNULLI installation.

### TRIMUI Brick

Tested with KNULLI.

Verified functions include:

* Controller input
* Device-specific A/B mapping through `input.cfg`
* CD-ROM operation
* CMOS persistence
* SELECT + START clean exit

---

## 20. Other ARM64 Devices

The controller configuration system was designed to reduce hard-coded device assumptions.

`input_test_v9.sh` detects and records controller mappings, while the modified `v90s_connection` implementation reads those mappings at startup.

Other AArch64 Linux handhelds may therefore work, but devices other than those listed above have not necessarily been tested.

### ABS D-pad Limitation

The current ABS D-pad implementation has primarily been tested with digital hat-style axes where:

```text
center = 0
negative = one direction
positive = opposite direction
```

Controllers using analog axes with ranges such as `0..255` or `0..65535`, different center values, or requiring dead zones may require additional input handling.

---

## 21. Source Changes Included in This Project

Comparison between the original development source tree and the final generic-input development tree identified the functional ARM64 handheld changes in:

```text
main_cui/v90s_connection.cpp
main_cui/v90s_connection.h
```

A development version of:

```text
osdependent/gamepad/linux/ysgamepad_linux.c
```

also contained temporary `PADDBG` controller diagnostic output.

That diagnostic modification is not required for the final Generic Input implementation and is therefore not included in the published modified source.

Development backup files such as `.bak` and `.save` files are also excluded.

---

## 22. Licenses

The original Tsugaru project is developed by CaptainYS (Soji Yamakawa).

The original Tsugaru license remains applicable to the original and modified Tsugaru source code as appropriate.

The additional ARM64 handheld integration work created for this package is released under the BSD 3-Clause License:

```text
Copyright (c) 2026 Ca-h9j9n
```

See:

```text
LICENSE_Tsugaru.txt
LICENSE_Modifications.txt
THIRD_PARTY_LICENSES.txt
```

for the applicable notices.

---

## 23. Project Status

Tsugaru ARM64 Handheld is an unofficial community modification intended to make Tsugaru easier to use on ARM64 Linux handheld systems.

It is not an official CaptainYS release.

The project does not include:

* FM TOWNS BIOS files
* Commercial games
* CD images
* Floppy disk images
* HDD images
* IC Memory Card images
* User-generated `input.cfg`
* User-generated `cmos.dat`

Users are responsible for supplying any required BIOS and software in accordance with applicable laws and licenses.

