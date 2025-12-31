# ValetBar 🐦

[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/language-Swift_6.2-orange.svg?style=flat-square&logo=swift)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/ryzenixx/valetbar-macos?style=flat-square&color=green)](https://github.com/ryzenixx/valetbar-macos/releases)

**ValetBar** is the ultimate companion for [Laravel Valet](https://laravel.com/docs/valet) users. It lives in your macOS menu bar, providing instant access to your local development environment status, site proxies, and service controls—all wrapped in a stunning, native SwiftUI interface.

---

## ✨ Features

- **Menu Bar Control Center**: Check the status of Valet, Nginx, PHP, and DnsMasq at a glance.
- **One-Click Actions**: Start, Stop, and Restart your Valet services instantly.
- **Smart Proxy List**: View all your parked sites (`.test` domains) with their SSL status.
- **Instant Navigation**: Click any proxy to open it directly in your browser.
- **Modern UI**: Built with SwiftUI, featuring native translucency and animations.
- **Auto-Updates**: Integrated **Sparkle 2** engine ensures you're always on the latest version.

## 🚀 Installation

### Recommended
Download the latest version from the [Releases Page](https://github.com/ryzenixx/valetbar-macos/releases/latest).

1. Download **ValetBar.dmg**.
2. Drag **ValetBar** to your `Applications` folder.
3. Launch the app. 🤵

### Requirements
- macOS 13.0 (Ventura) or later.
- Laravel Valet installed and configured (`valet install`).

---

---

## 🏗 Architecture

- **Language**: Swift
- **UI Framework**: SwiftUI (MenuBarExtra)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Concurrency**: Swift Async/Await (CLI operations)

### Key Components
- **`ValetCLI`**: A specialized wrapper to execute `valet` commands securely.
- **`UpdaterController`**: Bridges Sparkle's update mechanism with SwiftUI.
- **`MenuBarView`**: The main interface, designed with a focus on usability and aesthetics.

---

## 📄 License

ValetBar is open-source software licensed under the [MIT license](LICENSE).

---

<p align="center">
  Built with ❤️ by Mael Duret
</p>
