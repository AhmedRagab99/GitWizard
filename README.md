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

### Core Components

```mermaid
graph LR
    A[GitApp] --> B[Features]
    A --> C[Core]
    A --> D[Models]
    A --> E[UI]
    A --> F[Resources]
```

## 📁 Project Structure

```
GitApp/
├── Features/
│   └── Git/
│       ├── Views/
│       │   ├── Components/
│       │   ├── Commits/
│       │   ├── FilesViews/
│       │   └── SideBar/
│       └── ViewModels/
├── Core/
│   └── Commands/
│       ├── GitBasicOperations/
│       ├── GitBranch/
│       ├── GitCommit/
│       ├── GitDiff/
│       ├── GitMerge/
│       ├── GitRestore/
│       ├── GitStash/
│       └── GitTags/
├── Models/
└── Resources/
```

## 🔄 Data Flow

```mermaid
sequenceDiagram
    participant V as View
    participant VM as ViewModel
    participant C as Command
    participant G as Git

    V->>VM: User Action
    VM->>C: Execute Command
    C->>G: Git Operation
    G-->>C: Result
    C-->>VM: Update State
    VM-->>V: UI Update
```


## 📦 Core Components

### Models

- `Branch`: Branch information and operations
- `Commit`: Commit data structure
- `Diff`: File difference representation
- `FileDiff`: Detailed file changes
- `Status`: Repository status
- `Stash`: Stash operations
- `Tag`: Tag management

### Commands

- Basic Operations (clone, checkout, reset)
- Branch Management
- Commit Operations
- Diff Generation
- Merge Handling
- Stash Operations
- Tag Management

### ViewModels

- `GitViewModel`: Main Git operations coordinator
- `RepositoryViewModel`: Repository management
- `LogStore`: Commit history management
- `SyncState`: Repository synchronization state



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

