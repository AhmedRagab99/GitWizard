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
    @State private var showCreateBranchSheet = false
    @State private var newBranchName = ""
    @State private var stashMessage = ""
    @State private var keepStaged = false
    @State private var showPushSheet = false
    

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
                // Primary Actions Group
                Group {
                    Button(action: {
                        Task {
                            await viewModel.performPull()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 20))
                            Text("Pull")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.syncState.shouldPull {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task {
                            showPushSheet = true
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 20))
                            Text("Push")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .overlay(alignment: .topTrailing) {
                            if  viewModel.pendingPushCount > 0 {
                                let count = viewModel.pendingPushCount
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Show commit sheet
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Commit")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.pendingCommitsCount > 0 {
                                Text("\(viewModel.pendingCommitsCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showCreateBranchSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.square.on.square")
                                .font(.system(size: 20))
                            Text("New Branch")
                                .font(.caption)
                        }
                        .frame(width: 80)
                    }
                    .buttonStyle(.plain)

                    Button(action: { showStashSheet = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 20))
                            Text("Stash")
                                .font(.caption)
                        }
                        .frame(width: 60)
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
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 20))
                            Text("Merge")
                                .font(.caption)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                            Text("Delete")
                                .font(.caption)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showPushSheet) {
            PushSheet(
                isPresented: $showPushSheet,
                branches: viewModel.branches,
                currentBranch: viewModel.currentBranch,
                onPush: { selectedBranches, pushTags in
                    Task {
                        for branch in selectedBranches {
                            await viewModel.push(branch: branch, pushTags: pushTags)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showStashSheet) {
            CreateStashSheet(
                isPresented: $showStashSheet,
                onStash: { message, keepStaged in
                    Task {
                        await viewModel.createStash(message: message, keepStaged: keepStaged)
                    }
                }
            )
        }
        .sheet(isPresented: $showCreateBranchSheet) {
            CreateBranchSheet(
                isPresented: $showCreateBranchSheet,
                currentBranch: viewModel.currentBranch?.name ?? "",
                onCreate: { branchName, commitSource, specifiedCommit, checkout in
                    Task {
                        await viewModel.createBranch(named: branchName, checkout: checkout)
                    }
                }
            )
        }
        .onAppear {
            viewModel.selectRepository(url)

        }
        .alert("Delete Branch", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
//                if let branch = viewModel.currentBranch {
//                    Task {
//                        await viewModel.deleteBranch(branch)
//                    }
//                }
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

struct PushSheet: View {
    @Binding var isPresented: Bool
    var branches: [Branch]
    var currentBranch: Branch?
    var onPush: (_ branches: [Branch], _ pushTags: Bool) -> Void

    @State private var selectedBranches: Set<String> = []
    @State private var pushAllTags: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Push to repository:")
                    .font(.headline)
                Spacer()
                Text("origin")
                    .font(.body)
                    .padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.secondaryLabelColor)))
            }
            .padding(.bottom, 4)

            Text("Branches to push")
                .font(.subheadline)
                .padding(.bottom, 2)

            TableHeader()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(branches, id: \.name) { branch in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { selectedBranches.contains(branch.name) },
                                set: { isOn in
                                    if isOn { selectedBranches.insert(branch.name) }
                                    else { selectedBranches.remove(branch.name) }
                                }
                            )) {
                                Text("")
                            }
                            .labelsHidden()
                            .frame(width: 30)
                            Text(branch.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(branch.name) // For remote branch, adjust as needed
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Image(systemName: "minus.square")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .background(currentBranch?.name == branch.name ? Color.accentColor.opacity(0.08) : Color.clear)
                    }
                }
            }
            .frame(height: 120)

            Toggle("Select All", isOn: Binding(
                get: { selectedBranches.count == branches.count },
                set: { isOn in
                    if isOn { selectedBranches = Set(branches.map { $0.name }) }
                    else { selectedBranches.removeAll() }
                }
            ))
            .padding(.vertical, 4)

            Toggle("Push all tags", isOn: $pushAllTags)
                .padding(.vertical, 4)

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("OK") {
                    let selected = branches.filter { selectedBranches.contains($0.name) }
                    onPush(selected, pushAllTags)
                    isPresented = false
                }
                .disabled(selectedBranches.isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .shadow(radius: 20)
        .onAppear {
            if let current = currentBranch {
                selectedBranches = [current.name]
            }
        }
    }
}

private struct TableHeader: View {
    var body: some View {
        HStack {
            Text("").frame(width: 30)
            Text("Local branch").font(.caption).frame(maxWidth: .infinity, alignment: .leading)
            Text("Remote branch").font(.caption).frame(maxWidth: .infinity, alignment: .leading)
            Text("Track?").font(.caption).frame(width: 40)
        }
        .padding(.vertical, 2)
        .background(Color(.secondaryLabelColor))
    }
}
