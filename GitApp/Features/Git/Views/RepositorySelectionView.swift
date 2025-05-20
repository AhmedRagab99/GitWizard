//
//  RepositorySelectionView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import AppKit

struct RepositorySelectionView: View {
    var viewModel: RepositoryViewModel
    @State private var selectedRepository: URL?
    @State private var isShowingFilePicker = false
    @State private var isShowingCloneSheet = false
    @State private var isShowingErrorAlert = false
    @State private var errorMessage = ""

    // Use @Environment instead of creating values directly
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Modern header section
            headerView

            // Repository List - optimized to use lazy loading
            repositoryListView
        }
        .errorAlert(viewModel.errorMessage)
        .sheet(isPresented: $isShowingCloneSheet) {
            CloneRepositoryView(viewModel: viewModel)
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

    // MARK: - Extracted Views
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Git Client")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Button {
                    isShowingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Open")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    isShowingCloneSheet = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                        Text("Clone")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }

    private var repositoryListView: some View {
        List(selection: $selectedRepository) {
            if viewModel.recentRepositories.isEmpty {
                ContentUnavailableView {
                    Label("No Recent Repositories", systemImage: "folder.badge.questionmark")
                } description: {
                    Text("Open a local repository or clone from remote to get started")
                }
            } else {
                Text("Recent Repositories")
                    .font(.headline)
                    .padding(.vertical, 4)

                // Use LazyVStack to reduce memory usage
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
                }
            }
        }
    }

    // MARK: - Helper Methods
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
            // Instead of creating view models directly, use a factory pattern
            openNewWindow(
                with: GitClientView(
                    viewModel: GitViewModelFactory.createViewModel(),
                    url: url
                ),
                id: windowId,
                title: windowId,
                width: (NSScreen.main?.frame.width ?? 600) / 2,
                height: (NSScreen.main?.frame.height ?? 600) / 2
            )
        }
    }
}

// MARK: - Supporting Views
struct RepositoryRowView: View {
    let url: URL
    let isSelected: Bool
    let onOpen: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(url.lastPathComponent)
                .font(.headline)
            Text(url.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

// MARK: - Factory to manage view model lifecycle
enum GitViewModelFactory {
    static func createViewModel() -> GitViewModel {
        return GitViewModel()
    }
}

#Preview {
    RepositorySelectionView(viewModel: RepositoryViewModel())
}
