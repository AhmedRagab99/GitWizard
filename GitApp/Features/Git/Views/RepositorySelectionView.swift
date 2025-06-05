//
//  RepositorySelectionView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import AppKit

// Assuming RepositoryViewModel and AccountManager are defined elsewhere and are Observable
// If RepositoryViewModel is an @Observable class, this is fine.
// If AccountManager is an ObservableObject, it should be @ObservedObject or @StateObject.
// For this example, I'll assume they are correctly set up.

// Assuming these view models are correctly defined:
// import YourAppModule // Or ensure they are in the same module

enum RepositorySourceTab: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case accounts = "Accounts"

    var id: String { self.rawValue }
}

struct RepositorySelectionView: View {
    @State var viewModel: RepositoryViewModel
    @Bindable var accountManager :AccountManager
    @State private var selectedRepository: URL?
    @State private var isShowingFilePicker = false
    @State private var isShowingCloneSheet = false
    @State private var isShowingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedTab: RepositorySourceTab = .recent

    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal)
                .padding(.bottom, 10)

            Picker("Source", selection: $selectedTab) {
                ForEach(RepositorySourceTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 12)

            Group {
                if selectedTab == .recent {
                    repositoryListView
                } else {
                    AccountRepositoriesListView(
                        viewModel: viewModel,
                        accountManager: accountManager,
                        onCloneInitiated: { account, repo in
                            viewModel.cloneURL = repo.cloneUrl ?? ""
                            isShowingCloneSheet = true
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .errorAlert(viewModel.errorMessage ?? errorMessage)
        .sheet(isPresented: $isShowingCloneSheet) {
            CloneRepositoryView(viewModel: viewModel, accountManager: accountManager, initialCloneURL: viewModel.cloneURL)
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Error", isPresented: $isShowingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadRepositoryList()
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repositories")
                .font(.system(size: 28, weight: .bold))
                .padding(.top)

            HStack(spacing: 12) {
                Button {
                    isShowingFilePicker = true
                } label: {
                    Label("Open Local", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)

                Button {
                    viewModel.cloneURL = ""
                    isShowingCloneSheet = true
                } label: {
                    Label("Clone Remote", systemImage: "icloud.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }

    private var repositoryListView: some View {
        Group {
            if viewModel.recentRepositories.isEmpty {
                ContentUnavailableView {
                    Label("No Recent Repositories", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Open a local repository or clone one from your accounts to see it here.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedRepository) {
                    ForEach(viewModel.recentRepositories, id: \.self) { url in
                        RepositoryRowView(
                            url: url,
                            isSelected: url == selectedRepository,
                            onOpen: {
                                handleWindow(with: url)
                            },
                            onRemove: {
                                viewModel.removeFromRecentRepositories(url)
                                if url == selectedRepository {
                                    selectedRepository = nil
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedRepository = url
                viewModel.addImportedRepository(url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            isShowingErrorAlert = true
        }
    }

    private func handleWindow(with url: URL) {
        let windowId = url.lastPathComponent
        if isWindowVisible(id: windowId) {
            bringWindowToFront(id: windowId)
        } else {
            openNewWindow(
                with: GitClientView(
                    viewModel: GitViewModel(),
                    url: url,
                    accountManager: accountManager,
                    repoViewModel: viewModel
                ),
                id: windowId,
                title: windowId,
                width: (NSScreen.main?.frame.width ?? 600) / 2,
                height: (NSScreen.main?.frame.height ?? 600) / 2
            )
        }

        print("Attempting to open window for: \(url.path) with ID: \(windowId)")
    }
}

struct RepositoryRowView: View {
    let url: URL
    let isSelected: Bool
    let onOpen: () -> Void
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 25, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(url.lastPathComponent.replacingOccurrences(of: ".git", with: ""))
                    .font(.headline)
                    .fontWeight(.medium)
                Text(url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.init(nsColor: .selectedContentBackgroundColor).opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onOpen()
        }
        .contextMenu {
            Button {
                onOpen()
            } label: {
                Label("Open Repo", systemImage: "folder")
            }

            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove from Recent", systemImage: "trash")
            }
        }
    }
}

