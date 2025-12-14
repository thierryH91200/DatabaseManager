# DatabaseManager

Modern manager for SwiftData databases on macOS.

<a href="README.md">English</a> | <a href="README_fr.md">Français</a>

<p align="center">
<img src="Doc/Capture1_en.png" alt="Transactions">
<p align="center">
<em>Welcome</em>
</p>
</p>

<p align="center">
<img src="Doc/Capture2_en.png" alt="Transactions">
<p align="center">
<em>Main</em>
</p>
</p>

## Overview

**DatabaseManager** is a macOS application that allows you to create, open, and manage databases in the SwiftData format. The app offers a modern interface (SwiftUI), recent files management, and manipulation of Person entities (name, age, creation date).

## Features

- Create a new SwiftData database
- Open existing databases
- List of recent files
- Add, edit, delete people
- Display detailed information (name, age, date)
- Reset user preferences
- Dark mode support

## Installation

1. Clone this repository:
   ```sh
   git clone <repo-url>


If you want to change the database,
it’s important to define the schema as you see fit.
It is defined
in the file “DatabaseManagerApp”


'final class AppSchema {
    static let shared = AppSchema()
      
    let schema = Schema([Person.self])
    
    private init() {}
}'

and to create a CRUD in your ModelManager.

Everything that is part of the “MainAppp” folder belongs to your application;
the rest is part of the database manager.
