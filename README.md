# Disk Speed

A KDE Plasma panel widget showing real-time read and write throughput for up to four drives as vertical bars.

<p align="center">
  <img src="disk-speed.png" alt="Disk Speed">
</p>

<br><br>

<img src="desktop-1.png" alt="Disk Speed">

## Features

- Combined read + write throughput per drive
- Up to 4 drives monitored simultaneously
- Per-drive configurable colours
- Per-drive speed scale (bar fills at your chosen maximum)
- Compact vertical bar layout

## Requirements

- KDE Plasma 6.0+
- `org.kde.ksysguard.sensors` (included with Plasma)

## Installation

```bash
cd ~/.local/share/plasma/plasmoids/
git clone https://github.com/PlasmaDrifter/disk-speed local.widget.disk-speed
```

Then right-click your panel → **Add Widgets** → search for **Disk Speed**.

## Configuration

Right-click the widget → **Configure…**

| Option | Description |
|--------|-------------|
| Drive 1–4 device | Block device name (e.g. `sda`, `nvme0n1`) |
| Drive 1–4 colour | Bar colour for that drive |
| Drive 1–4 max speed | Full-scale throughput (MB/s) for that drive's bar |
| Refresh interval | Update frequency (seconds) |

