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

## 2. Original Tsugaru Source and Compatibility

The original Tsugaru / TOWNSEMU project is developed by **CaptainYS (Soji Yamakawa)**.

Original project:
https://github.com/captainys/TOWNSEMU

### Tested Source Version

This project was developed and tested using the following original source archive:

**`TOWNSEMU-20250513.zip`**

The ARM64 handheld modifications are provided separately in this repository:

```text
modified_source/main_cui/
├── main_v90s.cpp
├── headless_connection.cpp
├── headless_connection.h
├── v90s_connection.cpp
└── v90s_connection.h
```

The additional build configuration is provided as `modified_source/v90s_cmake.patch`.

The reproducible build requires six source files and the supplied CMake patch, as listed below.

### Compatibility Warning

The supplied modified source files were developed for the source tree based on `TOWNSEMU-20250513.zip`.

**Compatibility with the current upstream TOWNSEMU source or later releases is not guaranteed.**

For the intended build procedure, start with `TOWNSEMU-20250513.zip`, copy the five handheld source files into `src/main_cui/`, replace `src/cpputil/cpputil.h` with the supplied version, and apply `modified_source/v90s_cmake.patch` to the original CMake configuration.

Do not assume that applying the six supplied source files and CMake patch to an arbitrary newer TOWNSEMU source tree will produce a working build.

The ZIP source was verified against upstream Git tag `v20250513` (commit `c1a860b625c1b873fcfcafc8d8c3f5548332e4e1`).

For source compatibility, use `TOWNSEMU-20250513.zip` as the development baseline rather than assuming compatibility with the latest upstream source.

See the included license and notice files for applicable terms.

---

### Reproducible ARM64 Build (October 2026)

The original `TOWNSEMU-20250513.zip` source was compared
with upstream Git tag `v20250513`, commit
`c1a860b625c1b873fcfcafc8d8c3f5548332e4e1`.

The reproducible build requires these seven additions:

- `modified_source/main_cui/main_v90s.cpp`
- `modified_source/main_cui/headless_connection.cpp`
- `modified_source/main_cui/headless_connection.h`
- `modified_source/main_cui/v90s_connection.cpp`
- `modified_source/main_cui/v90s_connection.h`
- `modified_source/cpputil/cpputil.h`
- `modified_source/v90s_cmake.patch`

The five handheld source files and CMake patch were verified
to compile successfully for AArch64 Linux.
The supplied cpputil.h contains the signed-byte handling fix
verified during V90S hardware testing.

The newly rebuilt executable has not yet been
tested on handheld hardware.

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

Extract `TOWNSEMU-20250513.zip` and place the source
directory alongside `modified_source/` as follows:

```text
work/
├── TOWNSEMU-20250513/
└── modified_source/
```

Copy `modified_source/` from the downloaded
Tsugaru ARM64 Handheld repository into `work/`.

Run the following copy command from `work/`.

Copy the five handheld source files into `TOWNSEMU-20250513/src/main_cui/`.

```bash
cp modified_source/main_cui/* TOWNSEMU-20250513/src/main_cui/
```

Apply the V90S-tested `cpputil.h` to fix ARM64 signed-byte handling:

```bash
cp modified_source/cpputil/cpputil.h TOWNSEMU-20250513/src/cpputil/cpputil.h
```



### Apply the CMake Patch

From the `TOWNSEMU-20250513` directory, run:

```bash
patch -p1 < ../modified_source/v90s_cmake.patch
```

This adds the `Tsugaru_CUI_V90S` target to `src/main_cui/CMakeLists.txt`.

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

### Reproduced ARM64 Build (October 2026)

From the `work/` directory, configure with:

```bash
cmake -S TOWNSEMU-20250513/src -B build-arm64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64
```


### Alternative: Original Ninja Build Procedure

Note: This alternative Ninja procedure was not re-tested during
the October 2026 reproducibility verification. The verified
procedure uses Unix Makefiles, as documented above.


The following procedure documents the earlier Ninja-based build.
Use a separate build directory and do not mix CMake generators.

From the `work/` directory, with `TOWNSEMU-20250513/` and `toolchain-aarch64.cmake` available, create a separate Ninja build directory:

```bash
mkdir -p build-arm64-ninja
cd build-arm64-ninja
```

Configure with CMake:

```bash
cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=../toolchain-aarch64.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DALSALIB=/usr/lib/aarch64-linux-gnu/libasound.so \
  ../TOWNSEMU-20250513/src
```

The tested configuration used:

```text
CMAKE_BUILD_TYPE=Release
ALSALIB=/usr/lib/aarch64-linux-gnu/libasound.so
```

If the source directory or ARM64 ALSA library is installed in a different location, adjust the paths accordingly.

---

## 8. Build Tsugaru_CUI_V90S

### Reproduced ARM64 Build

From the `work/` directory, run:

```bash
cmake --build build-arm64 --target Tsugaru_CUI_V90S -j4
```

The resulting executable is located at:

```text
build-arm64/main_cui/Tsugaru_CUI_V90S
```


### Alternative: Ninja Build

For a build directory configured with Ninja, run:

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
file build-arm64/main_cui/Tsugaru_CUI_V90S
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
  build-arm64/main_cui/Tsugaru_CUI_V90S | grep NEEDED
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

Important: The October 2026 rebuilt executable has been verified
as an ARM64 binary, but has not yet been tested on actual handheld
hardware. Back up the currently working executable before replacing it.


Before installing the rebuilt executable, run the following on
the handheld to preserve the currently working version:

```bash
cp -pn /userdata/system/tsugaru/Tsugaru_CUI_V90S \
  /userdata/system/tsugaru/Tsugaru_CUI_V90S.backup
```

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

Before running it, make the script executable:

```bash
chmod +x /userdata/roms/ports/input_test_v9.sh
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

The `launch_fmtowns.sh` launcher reads the generated `input.cfg`
and uses its controller settings when starting Tsugaru.
The supplied `v90s_connection.cpp` and `v90s_connection.h`
implement the corresponding configurable input handling.


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

For the example above, `GameName.tsu` contains one line:

```text
-CD "disc1.cue"
```

Media filenames are resolved relative to the game directory.
Use double quotes around filenames, especially when they contain spaces.

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

The hardware test results below apply to the previously released
Tsugaru ARM64 Handheld package.

The executable reproduced from the May 2025 upstream source in
October 2026 has passed cross-compilation and binary verification,
but has not yet been tested on these handheld devices.


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

The reproducible ARM64 build uses six supplied source files:

```text
modified_source/main_cui/main_v90s.cpp
modified_source/main_cui/headless_connection.cpp
modified_source/main_cui/headless_connection.h
modified_source/main_cui/v90s_connection.cpp
modified_source/main_cui/v90s_connection.h
modified_source/cpputil/cpputil.h
```

It also requires the CMake configuration patch:

```text
modified_source/v90s_cmake.patch
```

These files are applied to the verified May 2025 upstream source tree.

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

