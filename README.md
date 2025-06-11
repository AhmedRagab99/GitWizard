# 🚀 GitApp - Modern Git Client for macOS

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Xcode](https://img.shields.io/badge/Xcode-16.0+-blue.svg)

A modern, SwiftUI-based Git client that brings the power of Git to your fingertips with a beautiful, intuitive interface.

[Features](#-key-features) • [Architecture](#-architecture) • [Installation](#-getting-started) • 


<img width="1714" alt="Image" src="https://github.com/user-attachments/assets/3858f7fa-73ca-40b5-9fdd-33027febd0b1" />


</div>


## 🎯 Key Features

- Repository Management
- Branch Operations
- Commit History
- File Diff Viewing
- Stash Management
- Tag Management
- Merge Operations
## 🏗 Architecture

The project follows MVVM (Model-View-ViewModel) architecture with a clear separation of concerns:

```mermaid
graph TD
    A[Views] --> B[ViewModels]
    B --> C[Models]
    B --> D[Commands]
    D --> E[Git Operations]
```

## 🛠 Technical Stack

- SwiftUI for UI
- Swift Concurrency (async/await)
- Combine for reactive programming
- Git command-line interface integration
- Modern Swift features and best practices


## 📱 Requirements

- macOS 14.0+
- Xcode 16.0+
- Swift 5.7+

## 🚀 Getting Started

1. Clone the repository
2. Open `GitApp.xcodeproj`
3. Build and run the project

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Contributing
Contributions are welcome! Feel free to open an issue or submit a pull request.

## 🌟 Support
If you find this project helpful, give it a ⭐ on GitHub!
