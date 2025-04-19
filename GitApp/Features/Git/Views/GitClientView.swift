import SwiftUI

// Import all models
import Foundation
import AppKit


struct GitClientView: View {
    @ObservedObject  var viewModel: GitViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } content: {
                TabView {
                    HistoryView(viewModel: viewModel)
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }

                    ChangesView(viewModel: viewModel)
                        .tabItem {
                            Label("Changes", systemImage: "list.bullet")
                        }
                }
        } detail: {
            if let commit = viewModel.selectedCommit {
                CommitDetailView(commit: commit, details: viewModel.commitDetails)
            } else {
                Text("Select a commit to view details")
                    .foregroundColor(.secondary)
            }
        }
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
    static let cornerRadius: CGFloat = 8
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 12
    static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    static let colors = (
        background: Color(.windowBackgroundColor),
        secondaryBackground: Color(.controlBackgroundColor),
        accent: Color.blue,
        text: Color(.labelColor),
        secondaryText: Color(.secondaryLabelColor),
        border: Color(.separatorColor),
        selection: Color.blue.opacity(0.15)
    )

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let small = ShadowStyle(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = ShadowStyle(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
