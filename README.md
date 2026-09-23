# Tsugaru ARM64 Handheld

Unofficial ARM64 handheld build of **Tsugaru**, the FM TOWNS / Marty emulator developed by CaptainYS (Soji Yamakawa).

This project adds controller support and a launcher designed for ARM64 Linux handheld systems such as the **Powkiddy V90S** and **TRIMUI Brick** running **KNULLI**.

> **This is an unofficial modified build and is not an official release by CaptainYS.**

Original Tsugaru project:

https://github.com/captainys/TOWNSEMU

---

# English

## Overview

This project provides an ARM64 build of Tsugaru with additional input handling for Linux handheld game systems.

This modified build reads controller settings from `input.cfg`, allowing the same emulator binary and launcher to be used on different handheld devices.

Controller configuration is generated automatically by `input_test_v9.sh`.

Tested configurations:

* Powkiddy V90S + KNULLI
* TRIMUI Brick + KNULLI

The same Tsugaru binary and launcher are used on both systems. Only the device-specific `input.cfg` differs.

---

## Features

* ARM64 / AArch64 Tsugaru CUI build
* Linux evdev controller input
* Automatic controller calibration
* Per-device `input.cfg`
* ABS D-pad support
* KEY D-pad support
* Reversed D-pad axis support
* Clean emulator shutdown with controller hotkey
* Multi-CD switching
* Multi-floppy switching for FD0 / FD1
* CMOS persistence
* HDD support
* IC Memory Card support
* EmulationStation integration

---

## Repository Structure

```text
Tsugaru-ARM64-Handheld/
├── README.md
├── BUILD_ARM64.md
├── LICENSE_Tsugaru.txt
├── LICENSE_Modifications.txt
├── THIRD_PARTY_LICENSES.txt
│
├── bin/
│   └── Tsugaru_CUI_V90S
│
├── scripts/
│   ├── input_test_v9.sh
│   └── launch_fmtowns.sh
│
├── config/
│   └── es_systems_v90s.cfg
│
└── modified_source/
    └── main_cui/
        ├── v90s_connection.cpp
        └── v90s_connection.h
```

For instructions on building the ARM64 executable from source, see:

**[BUILD_ARM64.md](BUILD_ARM64.md)**

---

## Release Package Contents

The downloadable release package contains the files required for normal installation:

```text
Tsugaru_ARM64_Handheld/
├── Tsugaru_CUI_V90S
├── launch_fmtowns.sh
├── input_test_v9.sh
├── es_systems_v90s.cfg
├── README.md
├── BUILD_ARM64.md
├── LICENSE_Tsugaru.txt
├── LICENSE_Modifications.txt
└── THIRD_PARTY_LICENSES.txt
```

`input.cfg` and `cmos.dat` are not included.

These files are generated on the user's system.

---

## Quick Start

### 1. Install Tsugaru

Copy:

```text
Tsugaru_CUI_V90S
launch_fmtowns.sh
```

to:

```text
/userdata/system/tsugaru/
```

### 2. Install the Controller Setup Utility

Copy:

```text
input_test_v9.sh
```

to:

```text
/userdata/roms/ports/input_test_v9.sh
```

Launch `input_test_v9.sh` from the **PORTS menu on the handheld** and complete the controller calibration.

### 3. Install the EmulationStation Configuration

Copy:

```text
es_systems_v90s.cfg
```

to:

```text
/userdata/system/configs/emulationstation/es_systems_v90s.cfg
```

### 4. Install the FM TOWNS BIOS/ROM

Place the BIOS/ROM files in:

```text
/userdata/bios/fmtowns/
```

### 5. Install Games

Place games and `.tsu` files under:

```text
/userdata/roms/fmtowns/
```

### 6. Restart

Restart EmulationStation or reboot the handheld.

---

## Supported Media Formats

| Media            | Supported Format        |
| ---------------- | ----------------------- |
| Floppy Disk (FD) | `.d88`, `.hdm`          |
| CD-ROM           | `.iso`, `.cue` + `.bin` |
| Hard Disk (HDD)  | `.h0`                   |
| IC Memory Card   | `.icm`                  |

Using the correct media type and file extension is important.

An incorrect or unsupported image may fail to mount or prevent the software from booting correctly.

### Floppy Disk

Supported formats:

```text
.d88
.hdm
```

Example:

```text
-FD0 "disk1.hdm"
-FD1 "disk2.d88"
```

### CD-ROM — BIN/CUE

Specify the `.cue` file in the `.tsu` file:

```text
-CD "disc1.cue"
```

Keep the `.cue` file and its corresponding `.bin` file or files together in the same game directory.

Do not specify the `.bin` file directly when using BIN/CUE.

### CD-ROM — ISO

```text
-CD "disc1.iso"
```

### Hard Disk

```text
-HD0 "game.h0"
```

### IC Memory Card

```text
-ICM "game.icm"
```

---

## Installation Details

Create the following directory:

```text
/userdata/system/tsugaru/
```

Copy:

```text
Tsugaru_CUI_V90S
launch_fmtowns.sh
```

to this directory.

Make the files executable if necessary:

```sh
chmod +x /userdata/system/tsugaru/Tsugaru_CUI_V90S
chmod +x /userdata/system/tsugaru/launch_fmtowns.sh
```

The launcher expects the emulator binary at:

```text
/userdata/system/tsugaru/Tsugaru_CUI_V90S
```

---

## BIOS

Place the FM TOWNS BIOS/ROM files in:

```text
/userdata/bios/fmtowns/
```

BIOS/ROM files are **not included** in this project.

Please use BIOS/ROM files that you are legally permitted to use.

---

## Controller Setup

Copy:

```text
input_test_v9.sh
```

to:

```text
/userdata/roms/ports/input_test_v9.sh
```

Then use the handheld itself to run the calibration utility:

1. Start KNULLI / EmulationStation.
2. Open the **PORTS** section.
3. Select `input_test_v9.sh`.
4. Launch it like a normal PORTS application.
5. Follow the on-screen instructions.

For normal controller setup, SSH access or Linux terminal commands are not required.

The calibration program asks you to press the following controls in order:

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

After calibration, the following file is generated automatically:

```text
/userdata/system/tsugaru/input.cfg
```

Example:

```ini
EVENT="/dev/input/event3"
A_CODE=305
B_CODE=304
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

Controller codes and event device numbers may differ between handhelds.

Do not copy `input.cfg` from another handheld unless its input mapping is known to be identical.

Run `input_test_v9.sh` from PORTS on each device.

---

## Game Directory

Games are stored under:

```text
/userdata/roms/fmtowns/
```

Each game can be placed in its own directory.

Example:

```text
/userdata/roms/fmtowns/GameName/
├── GameName.tsu
├── disc1.cue
├── disc1.bin
├── disc2.cue
├── disc2.bin
├── disk1.hdm
└── disk2.hdm
```

---

## TSU Files

A `.tsu` file defines the media images mounted when Tsugaru starts.

Use **one option per line**.

It is recommended to enclose filenames in double quotation marks.

Example:

```text
-FD0 "disk1.hdm"
-FD1 "disk2.d88"
-CD "disc1.cue"
-HD0 "game.h0"
-ICM "game.icm"
```

Each option is written on a separate line.

---

## Multi-CD Support

Multiple CD images can be registered in the `.tsu` file.

Example:

```text
-CD "disc1.cue"
-CDNEXT "disc2.cue"
-CDNEXT "disc3.cue"
```

`-CDNEXT` is an extension handled by `launch_fmtowns.sh`.

It is not a standard Tsugaru command-line option.

While Tsugaru is running:

```text
SELECT + R1 = Next CD
SELECT + L1 = Previous CD
```

---

## Multi-Floppy Support

### FD0

```text
-FD0 "disk1.hdm"
-FD0NEXT "disk2.hdm"
-FD0NEXT "disk3.hdm"
```

### FD1

```text
-FD1 "disk1.d88"
-FD1NEXT "disk2.d88"
-FD1NEXT "disk3.d88"
```

`-FD0NEXT` and `-FD1NEXT` are extensions handled by `launch_fmtowns.sh`.

They are not standard Tsugaru command-line options.

While Tsugaru is running:

```text
SELECT + R2 = Next FD
SELECT + L2 = Previous FD
```

If multiple FD0 images are registered, these hotkeys control FD0.

If FD0 has only one image and FD1 has multiple images, these hotkeys control FD1.

---

## Exit Hotkey

Press:

```text
SELECT + START
```

to quit Tsugaru cleanly.

The launcher sends the quit command through the Tsugaru command FIFO and waits for the emulator to exit normally.

This allows persistent state such as CMOS data to be saved correctly.

---

## CMOS

The launcher uses:

```text
/userdata/system/tsugaru/cmos.dat
```

Tsugaru creates this file when necessary.

`cmos.dat` is user-specific and is not included in this distribution.

---

## EmulationStation Integration

Copy:

```text
es_systems_v90s.cfg
```

to:

```text
/userdata/system/configs/emulationstation/es_systems_v90s.cfg
```

The configuration registers `.tsu` files as FM TOWNS games.

Configuration:

```xml
<?xml version="1.0"?>
<systemList>
  <system>
    <name>fmtowns</name>
    <fullname>Fujitsu FM-TOWNS</fullname>
    <path>/userdata/roms/fmtowns</path>
    <extension>.tsu</extension>
    <command>/userdata/system/tsugaru/launch_fmtowns.sh %ROM%</command>
    <platform>fmtowns</platform>
    <theme>fmtowns</theme>
  </system>
</systemList>
```

After copying the configuration file, restart EmulationStation or reboot the handheld.

---

## Controller Hotkeys

| Combination      | Action       |
| ---------------- | ------------ |
| `SELECT + START` | Quit Tsugaru |
| `SELECT + R1`    | Next CD      |
| `SELECT + L1`    | Previous CD  |
| `SELECT + R2`    | Next FD      |
| `SELECT + L2`    | Previous FD  |

---

## Tested Devices

### Powkiddy V90S

Tested with KNULLI.

Verified:

* Controller input
* CD boot
* Floppy boot
* CD switching
* FD0 / FD1 switching
* CMOS persistence
* HDD installation and persistence
* IC Memory Card
* `SELECT + START` clean shutdown

### TRIMUI Brick

Tested with KNULLI.

Verified:

* Controller input
* CD boot
* Device-specific A/B mapping
* CMOS persistence
* `SELECT + START` clean shutdown

The physical A/B button codes differ between the V90S and TRIMUI Brick.

`input_test_v9.sh` and the generated device-specific `input.cfg` handle this difference.

---

## Other ARM64 Devices

Other ARM64 Linux handhelds may work if:

* the CPU and OS support AArch64 Linux executables;
* the required runtime libraries are available;
* the controller is exposed through Linux evdev;
* `input_test_v9.sh` can detect the controller.

Other devices have not necessarily been tested.

Run `input_test_v9.sh` from PORTS before using Tsugaru on a new device.

### ABS D-pad Limitation

The current ABS D-pad implementation has primarily been tested with digital hat-style axes where the center value is `0`, with negative and positive values representing opposite directions.

Controllers using analog axes with ranges such as `0..255` or `0..65535`, different center values, or requiring dead zones may require additional input handling.

---

## Runtime Dependencies

The ARM64 binary dynamically requires system libraries including:

```text
libasound.so.2
libstdc++.so.6
libm.so.6
libgcc_s.so.1
libc.so.6
```

These libraries are not included in this package and must be provided by the target Linux system.

---

## Building from Source

Build instructions for the ARM64 version are provided in:

**[BUILD_ARM64.md](BUILD_ARM64.md)**

The repository includes only the Tsugaru source files modified for the ARM64 handheld input implementation under:

```text
modified_source/main_cui/
├── v90s_connection.cpp
└── v90s_connection.h
```

The complete original Tsugaru source tree is not duplicated in this repository.

Obtain the original Tsugaru source from the upstream project and follow `BUILD_ARM64.md` to apply the modified files and build the ARM64 executable.

---

## Video Guide

A video guide covering installation, controller calibration, `.tsu` configuration, and usage is planned for the following YouTube channel:

https://www.youtube.com/@user-h9j9n

The video guide will demonstrate:

* File installation
* Starting `input_test_v9.sh` from PORTS
* Controller calibration
* Supported media formats
* `.tsu` configuration
* Starting FM TOWNS games from EmulationStation
* Controller hotkeys
* CD / FD switching

A direct link to the tutorial video may be added here after publication.

---

## Important Notes

This package does **not** include:

* FM TOWNS BIOS/ROM files
* Commercial games
* CD images
* Floppy disk images
* HDD images
* IC Memory Card images
* User CMOS data

Users are responsible for obtaining and using BIOS, ROM and software images in accordance with applicable laws and licenses.

---

## License

### Original Tsugaru

Tsugaru is developed by **CaptainYS (Soji Yamakawa)**.

Original project:

https://github.com/captainys/TOWNSEMU

The original Tsugaru project is distributed under the **BSD 3-Clause License**.

See:

```text
LICENSE_Tsugaru.txt
THIRD_PARTY_LICENSES.txt
```

for the original Tsugaru license and related notices.

### ARM64 Handheld Modifications

ARM64 handheld modifications and additional scripts:

**Copyright (c) 2026 Ca-h9j9n**

Licensed under the **BSD 3-Clause License**.

This includes the original modifications and additional files created for this ARM64 handheld package, including:

* ARM64 handheld input modifications
* `launch_fmtowns.sh`
* `input_test_v9.sh`
* Related handheld integration and configuration work

See:

```text
LICENSE_Modifications.txt
```

for the complete license text.

The license for these modifications does not replace or modify the license of the original Tsugaru project or other applicable component licenses.

This ARM64 handheld package is an unofficial modified build and is not an official release by CaptainYS.

---

## Credits

### Tsugaru

Developed by:

**CaptainYS (Soji Yamakawa)**

Original project:

https://github.com/captainys/TOWNSEMU

Many thanks to CaptainYS for developing and releasing Tsugaru as open-source software.

### ARM64 Handheld Modifications

**Ca-h9j9n**

ARM64 handheld input support, launcher, controller calibration, and handheld integration.

This software was created using AI.

---

# 日本語

## 概要

**Tsugaru ARM64 Handheld** は、CaptainYS（Soji Yamakawa）氏が開発しているFM TOWNS / Martyエミュレータ「津軽（Tsugaru）」を、ARM64 Linux携帯ゲーム機で使用するために調整した非公式ビルドです。

オリジナルTsugaru：

https://github.com/captainys/TOWNSEMU

このバージョンでは携帯ゲーム機のコントローラーをLinuxのevdevから読み込み、機種ごとの入力コードを `input.cfg` から取得します。

そのため、対応機種では**同じTsugaruバイナリと同じランチャー**を使用し、コントローラーの違いを `input.cfg` で吸収できます。

実機動作確認済み：

* Powkiddy V90S + KNULLI
* TRIMUI Brick + KNULLI

> **本パッケージは非公式の改変版であり、CaptainYS氏による公式リリースではありません。**

---

## 主な機能

* ARM64 / AArch64版 Tsugaru CUI
* Linux evdevコントローラー入力
* コントローラー自動設定
* 機種ごとの `input.cfg`
* ABSタイプ方向キー対応
* KEYタイプ方向キー対応
* X/Y軸反転対応
* コントローラーからの安全な終了
* 複数CD交換
* FD0 / FD1 複数フロッピー交換
* CMOS保存
* HDD対応
* ICメモリカード対応
* EmulationStation対応

---

## GitHubリポジトリ構成

```text
Tsugaru-ARM64-Handheld/
├── README.md
├── BUILD_ARM64.md
├── LICENSE_Tsugaru.txt
├── LICENSE_Modifications.txt
├── THIRD_PARTY_LICENSES.txt
│
├── bin/
│   └── Tsugaru_CUI_V90S
│
├── scripts/
│   ├── input_test_v9.sh
│   └── launch_fmtowns.sh
│
├── config/
│   └── es_systems_v90s.cfg
│
└── modified_source/
    └── main_cui/
        ├── v90s_connection.cpp
        └── v90s_connection.h
```

ARM64版のビルド方法については：

**[BUILD_ARM64.md](BUILD_ARM64.md)**

を参照してください。

---

## リリースパッケージ構成

通常のインストールに必要なファイルをリリースパッケージに収録します。

```text
Tsugaru_ARM64_Handheld/
├── Tsugaru_CUI_V90S
├── launch_fmtowns.sh
├── input_test_v9.sh
├── es_systems_v90s.cfg
├── README.md
├── BUILD_ARM64.md
├── LICENSE_Tsugaru.txt
├── LICENSE_Modifications.txt
└── THIRD_PARTY_LICENSES.txt
```

`input.cfg` と `cmos.dat` は配布ファイルには含まれません。

これらは使用する機器上で生成されます。

---

## クイックスタート

### 1. Tsugaru本体を配置

```text
Tsugaru_CUI_V90S
launch_fmtowns.sh
```

を、

```text
/userdata/system/tsugaru/
```

へコピーします。

### 2. コントローラー設定ツールを配置

```text
input_test_v9.sh
```

を、

```text
/userdata/roms/ports/input_test_v9.sh
```

へコピーします。

携帯ゲーム機本体の **PORTSメニューから `input_test_v9.sh` を起動**して、コントローラー設定を行います。

### 3. EmulationStation設定を配置

```text
es_systems_v90s.cfg
```

を、

```text
/userdata/system/configs/emulationstation/es_systems_v90s.cfg
```

へコピーします。

### 4. BIOSを配置

FM TOWNS BIOS/ROMを、

```text
/userdata/bios/fmtowns/
```

へ配置します。

### 5. ゲームを配置

ゲームと `.tsu` ファイルを、

```text
/userdata/roms/fmtowns/
```

以下へ配置します。

### 6. 再起動

EmulationStationを再起動するか、本体を再起動します。

---

## 対応メディア形式

| メディア          | 対応形式                    |
| ------------- | ----------------------- |
| フロッピーディスク（FD） | `.d88`, `.hdm`          |
| CD-ROM        | `.iso`, `.cue` + `.bin` |
| ハードディスク（HDD）  | `.h0`                   |
| ICメモリカード      | `.icm`                  |

### TSU記述例

`.tsu` ファイルには、起動時に使用するメディアイメージを記述します。

**1オプションにつき1行**で記述します。

ファイル名はダブルクォートで囲むことを推奨します。

```text
-FD0 "disk1.hdm"
-FD1 "disk2.d88"
-CD "disc1.cue"
-HD0 "game.h0"
-ICM "game.icm"
```

各オプションの後で改行して、次のメディアを指定します。

BIN/CUE形式では `.bin` ではなく `.cue` を指定してください。

---

## コントローラー設定

`input_test_v9.sh` を、

```text
/userdata/roms/ports/input_test_v9.sh
```

へ配置します。

携帯ゲーム機本体で：

1. KNULLI / EmulationStationを起動します。
2. **PORTS** を開きます。
3. `input_test_v9.sh` を選択します。
4. 起動します。
5. 画面の指示に従ってボタンを押します。

設定順：

```text
SELECT
↑
↓
←
→
A
B
START
L1
R1
L2
R2
```

設定完了後、

```text
/userdata/system/tsugaru/input.cfg
```

が自動生成されます。

機種によってボタンコードやinput event番号は異なる場合があります。

原則として他機種の `input.cfg` をコピーせず、使用する機器ごとにPORTSから `input_test_v9.sh` を実行してください。

---

## 複数CD交換

```text
-CD "disc1.cue"
-CDNEXT "disc2.cue"
-CDNEXT "disc3.cue"
```

`-CDNEXT` は `launch_fmtowns.sh` が処理する独自拡張で、Tsugaru本体の標準コマンドラインオプションではありません。

```text
SELECT + R1 = 次のCD
SELECT + L1 = 前のCD
```

---

## 複数FD交換

FD0：

```text
-FD0 "disk1.hdm"
-FD0NEXT "disk2.hdm"
-FD0NEXT "disk3.hdm"
```

FD1：

```text
-FD1 "disk1.d88"
-FD1NEXT "disk2.d88"
-FD1NEXT "disk3.d88"
```

`-FD0NEXT` と `-FD1NEXT` は `launch_fmtowns.sh` が処理する独自拡張です。

```text
SELECT + R2 = 次のFD
SELECT + L2 = 前のFD
```

FD0に複数枚登録されている場合はFD0を交換します。

FD0が1枚だけでFD1に複数枚登録されている場合はFD1を交換します。

---

## Tsugaruの終了

ゲーム中に、

```text
SELECT + START
```

を押すとTsugaruを正常終了します。

ランチャーからTsugaruのコマンドFIFOへ終了コマンドを送信し、Tsugaruを正常終了させます。

これによりCMOSなどの状態を保存した状態で終了できます。

---

## ホットキー一覧

| 操作               | 機能        |
| ---------------- | --------- |
| `SELECT + START` | Tsugaru終了 |
| `SELECT + R1`    | 次のCD      |
| `SELECT + L1`    | 前のCD      |
| `SELECT + R2`    | 次のFD      |
| `SELECT + L2`    | 前のFD      |

---

## 動作確認済み機種

### Powkiddy V90S

KNULLIで確認。

確認済み：

* コントローラー操作
* CD起動
* FD起動
* CD交換
* FD0 / FD1交換
* CMOS保存
* HDDへのインストールおよび保存
* ICメモリカード
* `SELECT + START` による正常終了

### TRIMUI Brick

KNULLIで確認。

確認済み：

* コントローラー操作
* CD起動
* 機種固有のA/Bボタン設定
* CMOS保存
* `SELECT + START` による正常終了

V90SとTRIMUI Brickでは物理A/Bボタンのコードが異なります。

`input_test_v9.sh` と機種ごとに生成される `input.cfg` によって、この違いを吸収します。

---

## その他のARM64機器

以下の条件を満たすARM64 Linux機器では動作する可能性があります。

* AArch64 Linux実行ファイルを実行できる
* 必要なランタイムライブラリが存在する
* コントローラーがLinux evdevとして認識される
* `input_test_v9.sh` がコントローラーを検出できる

すべてのARM64機器での動作を保証するものではありません。

### ABS方向キーについて

現在のABS方向キー実装は、主に中央値 `0`、負値と正値で各方向を示すデジタルhatタイプの軸で検証しています。

`0..255` や `0..65535` などのアナログ軸、異なる中央値、デッドゾーン処理が必要なコントローラーでは追加対応が必要になる可能性があります。

---

## 必要なシステムライブラリ

ARM64バイナリでは、以下を含むシステムライブラリを動的に使用します。

```text
libasound.so.2
libstdc++.so.6
libm.so.6
libgcc_s.so.1
libc.so.6
```

これらのライブラリは本パッケージには含まれません。

対象Linuxシステム側のライブラリを使用します。

---

## ARM64版のビルド

ビルド手順については：

**[BUILD_ARM64.md](BUILD_ARM64.md)**

を参照してください。

GitHubリポジトリには、ARM64携帯ゲーム機対応のため変更したTsugaruソース：

```text
modified_source/main_cui/
├── v90s_connection.cpp
└── v90s_connection.h
```

を収録しています。

オリジナルTsugaruの完全なソースツリーは、このリポジトリには複製していません。

オリジナルTsugaruソースを取得し、`BUILD_ARM64.md` の手順に従って変更ファイルを適用してARM64版をビルドしてください。

---

## 動画ガイド

インストール方法、コントローラー設定、`.tsu` ファイルの設定、使用方法などを紹介する動画を、以下のYouTubeチャンネルで公開予定です。

https://www.youtube.com/@user-h9j9n

専用の紹介・解説動画を公開した場合は、その動画への直接リンクをここへ追加する予定です。

---

## 配布物に含まれないもの

本パッケージには以下のデータを含みません。

* FM TOWNS BIOS/ROM
* 市販ゲーム
* CDイメージ
* フロッピーディスクイメージ
* HDDイメージ
* ICメモリカードイメージ
* ユーザーのCMOSデータ

BIOS、ROM、ソフトウェアイメージ等については、それぞれ適用される法律・ライセンスに従って利用してください。

---

## ライセンス

### オリジナルTsugaru

Tsugaruの原作者は **CaptainYS（Soji Yamakawa）氏**です。

オリジナルプロジェクト：

https://github.com/captainys/TOWNSEMU

オリジナルのTsugaruプロジェクトは **BSD 3-Clause License** で公開されています。

以下を参照してください。

```text
LICENSE_Tsugaru.txt
THIRD_PARTY_LICENSES.txt
```

### ARM64携帯ゲーム機向け変更部分

ARM64携帯ゲーム機向け変更部分および追加スクリプト：

**Copyright (c) 2026 Ca-h9j9n**

**BSD 3-Clause License**

対象には、本ARM64携帯ゲーム機向けパッケージのために作成した以下の変更・追加ファイルが含まれます。

* ARM64携帯ゲーム機向け入力対応
* `launch_fmtowns.sh`
* `input_test_v9.sh`
* その他の携帯ゲーム機向け統合・設定部分

完全なライセンス文については：

```text
LICENSE_Modifications.txt
```

を参照してください。

この変更部分に対するライセンスは、オリジナルTsugaruやその他の適用されるコンポーネントのライセンスを置き換えたり変更したりするものではありません。

本ARM64携帯ゲーム機向けパッケージは非公式の改変ビルドであり、CaptainYS氏による公式リリースではありません。

---

## Credits / 謝辞

### Tsugaru / 津軽

開発：

**CaptainYS (Soji Yamakawa)**

オリジナルプロジェクト：

https://github.com/captainys/TOWNSEMU

Many thanks to CaptainYS for developing and releasing Tsugaru as open-source software.

素晴らしいFM TOWNSエミュレータ「津軽」を開発し、オープンソースとして公開されているCaptainYS氏に感謝いたします。

### ARM64 Handheld Modifications / ARM64携帯ゲーム機向け変更

**Ca-h9j9n**

ARM64 handheld input support, launcher, controller calibration, and handheld integration.

ARM64携帯ゲーム機向け入力対応、ランチャー、コントローラー設定ツール、および携帯ゲーム機向け統合。

このソフトウェアはAIを使用して作成されています。


---

## Support / サポートについて

This is a personal hobby project. Issues and reports are welcome, but responses may be delayed as this repository is not monitored regularly.

これは個人の趣味で開発・公開しているプロジェクトです。  
Issueや不具合報告は歓迎しますが、GitHubを常時確認しているわけではないため、返信や対応には時間がかかる場合があります。
