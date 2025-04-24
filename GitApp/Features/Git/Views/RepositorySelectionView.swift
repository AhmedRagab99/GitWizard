//
//  RepositorySelectionView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import AppKit

struct RepositorySelectionView: View {
     var viewModel: GitViewModel
    @State private var selectedRepository: URL?
    @State private var isShowingFilePicker = false
    @State private var isShowingCloneSheet = false
    @State private var isShowingErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Modern header section
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

                // Repository List
                List(selection: $selectedRepository) {
                    if viewModel.recentRepositories.isEmpty {
                        ContentUnavailableView {
                            Label("No Recent Repositories", systemImage: "folder.badge.questionmark")
                        } description: {
                            Text("Open a local repository or clone from remote to get started")
                        }
                    } else {
                        Section("Recent Repositories") {
                            ForEach(viewModel.recentRepositories, id: \.self) { url in
                                NavigationLink(value: url) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(url.lastPathComponent)
                                            .font(.headline)
                                        Text(url.path)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(url == viewModel.selectedRepository ?
                                            Color.accentColor.opacity(0.15) :
                                            Color.clear)
                                )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.removeFromRecentRepositories(url)
                                        if url == selectedRepository {
                                            selectedRepository = nil
                                        }
                                    } label: {
                                        Label("Remove from Recent", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.removeFromRecentRepositories(url)
                                        if url == selectedRepository {
                                            selectedRepository = nil
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } detail: {
            if let selectedRepo = selectedRepository {
                GitClientView(viewModel: viewModel)
            } else {
                ContentUnavailableView {
                    Label("No Repository Selected", systemImage: "folder.badge.questionmark")
                } description: {
                    Text("Select a repository from the sidebar or open a new one")
                }
            }
        }
        .sheet(isPresented: $isShowingCloneSheet) {
            CloneRepositoryView(viewModel: viewModel)
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        do {
                            try await viewModel.openRepository(at: url)
                            selectedRepository = url
                        } catch {
                            errorMessage = error.localizedDescription
                            isShowingErrorAlert = true
                        }
                    }
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                isShowingErrorAlert = true
            }
        }
        .alert("Error", isPresented: $isShowingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadRecentRepositories()
            }
        }
        .onChange(of: selectedRepository) { newValue in
            if let url = newValue {
                viewModel.selectRepository(url)
            }
        }
    }
}

#Preview {
    RepositorySelectionView(viewModel: GitViewModel())
}
