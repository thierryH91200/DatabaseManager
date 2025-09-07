
![Swift](https://img.shields.io/badge/Swift-5.7-orange) ![macOS](https://img.shields.io/badge/macOS-14-blue) ![License](https://img.shields.io/badge/License-MIT-green)
    <a href="https://github.com/thierryH91200/DataBaseManager/releases/latest" alt="Downloads">
          <img src="https://img.shields.io/github/downloads/thierryH91200/DataBaseManager/total.svg" /></a>


# DatabaseManager

Modern manager for SwiftData databases on macOS.

<a href="README.md">English</a> | <a href="README_fr.md">Français</a>

<p align="center">
  <img src="Doc/Capture1_en.png" alt="Welcome" width="800">
  <br>
  <em>Welcome</em>
</p>

<p align="center">
  <img src="Doc/Capture2_en.png" alt="Main" width="800">
  <br>
  <em>Main</em>
</p>

## Overview

**DatabaseManager** is a macOS application that allows you to create, open, and manage databases using SwiftData. It provides a modern SwiftUI interface, a list of recent files, and tools to manipulate `Person` entities (name, age, creation date). It’s designed for developers and power users who need a lightweight way to inspect and edit SwiftData stores.

## Features

- Create a new SwiftData database
- Open existing databases from disk
- Quick access to recent files
- Add, edit, and delete `Person` records
- View details: name, age, creation date
- Reset user preferences (to default state)
- Dark Mode and macOS-native UI
- Keyboard shortcuts for common actions (optional, configurable)

## Requirements

- macOS 13.0+ (Ventura) or later
- Xcode 15+
- Swift 5.9+
- SwiftData (enabled in your target if you build the app from source)

## Installation

### Option A — Build from source

1. Clone this repository:
   ```sh
   git clone <repo-url>
   cd DatabaseManager
