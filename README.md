# Disk Speed Monitor Widget

[![KDE Plasma 6](https://img.shields.io/badge/KDE_Plasma-6.0+-3152A0?style=for-the-badge&logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)
[![QML](https://img.shields.io/badge/UI-QML%2FQt6-41CD52?style=for-the-badge&logo=qt&logoColor=white)](https://doc.qt.io/qt-6/qtqml-index.html)
[![Category](https://img.shields.io/badge/I%2FO%20Performance-FF2D55?style=for-the-badge&logo=speedometer&logoColor=white)](https://github.com/PlasmaDrifter)
[![License](https://img.shields.io/badge/License-GPLv2-blue.svg?style=for-the-badge)](LICENSE)

A real-time disk read/write throughput speed gauge for KDE Plasma 6.

---

## Previews

![Disk Speed Monitor Widget Preview](disk-speed.png)

![Disk Speed Monitor Widget Preview](disk.speed3.png)

![Disk Speed Monitor Widget Preview](desktop-1.png)

---

## Features

- **Real-time**: disk Read and Write speed monitoring (MB/s)
- **Supports**: all active storage controllers (NVMe, SSD, HDD)
- **Transparent**: and compact display options
- **Low**: polling overhead

## Requirements

- **Environment**: KDE Plasma 6.0 or higher
- **Framework**: Qt6 QML / Plasma Applet API

## Installation

### Option 1: Git Clone (Recommended)
```bash
mkdir -p ~/.local/share/plasma/plasmoids/
git clone https://github.com/PlasmaDrifter/disk-speed.git ~/.local/share/plasma/plasmoids/local.widget.disk-speed
```

### Option 2: Plasma Package Installer
```bash
kpackagetool6 -i ~/.local/share/plasma/plasmoids/local.widget.disk-speed
```

Then right-click your desktop or panel $\rightarrow$ **Add Widgets...** and search for the widget name.

## Credits & License

- **Author / Maintainer**: PlasmaDrifter
- **License**: Licensed under the [GPLv2](LICENSE).
