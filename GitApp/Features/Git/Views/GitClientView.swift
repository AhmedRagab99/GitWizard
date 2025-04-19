import SwiftUI

// Import all models
import Foundation
import AppKit

struct GitClientView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var selectedTab: Tab = .history

    enum Tab {
        case history
        case changes
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top section - Sidebar and content
            HStack(spacing: 0) {
                // Sidebar
                SidebarView(viewModel: viewModel)
                    .frame(minWidth: 250, maxWidth: 300)

                // Main content
                VStack(spacing: 0) {
                    // Tab bar
                    HStack {
                        Button(action: { selectedTab = .history }) {
                            Label("History", systemImage: "clock")
                                .foregroundStyle(selectedTab == .history ? .tertiary : .secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: { selectedTab = .changes }) {
                            Label("Changes", systemImage: "list.bullet")
                                .foregroundStyle(selectedTab == .changes ? .tertiary : .secondary)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding()
                    .background(ModernUI.colors.background)

                    // Content area
                    if selectedTab == .history {
                        HistoryView(viewModel: viewModel)
                    } else {
                        ChangesView(viewModel: viewModel)
                    }
                }
            }

            // Bottom section - Commit details
            if let commit = viewModel.selectedCommit {
                VStack(spacing: 0) {
                    Divider()
                    CommitDetailView(commit: commit, details: viewModel.commitDetails, viewModel: viewModel)
                }
                .frame(height: 300)
            }
        }
        .background(ModernUI.colors.background)
    }
}

// Syntax Highlighting Colors
enum SyntaxTheme {
    static let added = Color.green.opacity(0.1)
    static let removed = Color.red.opacity(0.1)
    static let lineNumber = Color.gray.opacity(0.5)
    static let addedText = Color.green
    static let removedText = Color.red
    static let normalText = Color(.labelColor)
}

// Modern UI Constants
enum ModernUI {
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 8
    static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    enum colors {
        static let background = Color(.windowBackgroundColor)
        static let secondaryBackground = Color(.controlBackgroundColor)
        static let selection = Color(.selectedContentBackgroundColor)
        static let border = Color(.separatorColor)
        static let secondaryText = Color(.secondaryLabelColor)
    }

    enum shadow {
        case small, medium, large

        var radius: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 8
            }
        }
        var colors: Color {
            switch self {
                case .small: return Color.black.opacity(0.1)
                case .medium: return Color.black.opacity(0.2)
            case .large: return Color.black.opacity(0.3)
            }
        }
       

        var offset: CGFloat {
            switch self {
            case .small: return 1
            case .medium: return 2
            case .large: return 4
            }
        }
    }
}
//
//extension View {
//    func modernShadow(_ style: ModernUI.shadow) -> some View {
//        self.shadow(
//            color: .black.opacity(0.1),
//            radius: style.radius,
//            x: 0,
//            y: style.offset
//        )
//    }
//}
