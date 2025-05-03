import SwiftUI

// Import all models
import Foundation
import AppKit

struct GitClientView: View {
    @Bindable var viewModel: GitViewModel
    var url: URL
    @State private var selectedWorkspaceItem: WorkspaceSidebarItem = .history
    @State private var showStashSheet = false
    @State private var showDeleteAlert = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var searchText: String = ""

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel, selectedWorkspaceItem: $selectedWorkspaceItem)
        } detail: {
            VStack(spacing: 0) {
                // Main content area
                if selectedWorkspaceItem == .workingCopy {
                    CommitView(viewModel: viewModel)
                } else if selectedWorkspaceItem == .history {
                    HistoryView(viewModel: viewModel)
                } else {
                    // Optionally, add a search view or placeholder
                    Text("Search coming soon...")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Search Bar
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search commits...", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 200)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Divider()
                    .padding(.horizontal, 8)

                // Primary Actions Group
                Group {
                    Button(action: {
                        Task {
                            await viewModel.performPull()
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16))
                            Text("Pull")
                                .font(.caption2)
                        }
                        .frame(width: 45)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.syncState.shouldPull {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 1, y: -1)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task {
                            await viewModel.performPush()
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                            Text("Push")
                                .font(.caption2)
                        }
                        .frame(width: 45)
                        .overlay(alignment: .topTrailing) {
                            if let count = viewModel.syncState.commitsAhead, count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 1, y: -1)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Show commit sheet
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Commit")
                                .font(.caption2)
                        }
                        .frame(width: 45)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.pendingCommitsCount > 0 {
                                Text("\(viewModel.pendingCommitsCount)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 1, y: -1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .padding(.horizontal, 8)

                // Secondary Actions Group
                Group {
                    Button(action: {
                        // Show merge sheet
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 16))
                            Text("Merge")
                                .font(.caption2)
                        }
                        .frame(width: 45)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                            Text("Delete")
                                .font(.caption2)
                        }
                        .frame(width: 45)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showStashSheet) {
            StashSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.selectRepository(url)
        }
        .alert("Delete Branch", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let branch = viewModel.currentBranch {
                    Task {
//                        await viewModel.deleteBranch(branch)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this branch?")
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
    static let normalText = Color.clear
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

// MARK: - Sheets
struct StashSheet: View {
    @Bindable var viewModel: GitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var message: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Stash message", text: $message)
                }
            }
            .navigationTitle("Stash Changes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Stash") {
                        Task {
//                            await viewModel.stash(message: message)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
