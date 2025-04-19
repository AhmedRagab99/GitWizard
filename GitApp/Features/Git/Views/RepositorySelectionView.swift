//
//  RepositorySelectionView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import AppKit

struct RepositorySelectionView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var isShowingFilePicker = false
    @State private var selectedDirectory: URL?
    @State private var selectedRepository: URL?
    @State private var isOpeningRepository = false
    @State private var searchText = ""    

    var filteredRepositories: [URL] {
        if searchText.isEmpty {
            return viewModel.foundRepositories
        } else {
            return viewModel.foundRepositories.filter { url in
                url.lastPathComponent.localizedCaseInsensitiveContains(searchText) ||
                url.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Select Git Repository")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    isShowingFilePicker = true
                }) {
                    Label("Choose Directory", systemImage: "folder")
                        .fileImporter(
                            isPresented: $isShowingFilePicker,
                            allowedContentTypes: [.directory],
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                if let url = urls.first {
                                    selectedDirectory = url
                                    viewModel.searchForRepositories(in: url)
                                }
                            case .failure(let error):
                                viewModel.errorMessage = "Failed to select directory: \(error.localizedDescription)"
                            }
                        }
                        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                            Button("OK") {
                                viewModel.errorMessage = nil
                            }
                        } message: {
                            if let error = viewModel.errorMessage {
                                Text(error)
                            }
                        }
                }
                .buttonStyle(.bordered)
                .disabled(isOpeningRepository)
            }
            .padding(.horizontal)

            if viewModel.isSearchingRepositories {
                ProgressView("Searching for repositories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.foundRepositories.isEmpty {
                VStack(spacing: 12) {
                    TextField("Search repositories...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    List(filteredRepositories, id: \.self) { url in
                        Button {
                            selectedRepository = url
                            openRepository(url)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(url.lastPathComponent)
                                        .font(.headline)
                                }
                                Text(url.path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isOpeningRepository)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Git repositories found")
                        .font(.headline)

                    Text("Choose a directory to search for Git repositories")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .overlay {
            if isOpeningRepository {
                ProgressView("Opening repository...")
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedDirectory = url
                    viewModel.searchForRepositories(in: url)
                }
            case .failure(let error):
                print("Error selecting directory: \(error.localizedDescription)")
            }
        }
    }

    private func openRepository(_ url: URL) {
        isOpeningRepository = true

        Task {
            // Select the repository in the view model
            viewModel.selectRepository(url)

            // Wait a moment for the repository to be loaded
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Create and show the GitClientView window
            if let window = NSApplication.shared.windows.first(where: { $0.title == url.lastPathComponent }) {
                // If window already exists, bring it to front
                window.makeKeyAndOrderFront(nil)
            } else {
                // Create new window
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                    backing: .buffered,
                    defer: false
                )
                window.title = url.lastPathComponent
                window.center()
                window.contentView = NSHostingView(rootView: GitClientView(viewModel: viewModel))
                window.makeKeyAndOrderFront(nil)
            }

            isOpeningRepository = false
        }
    }
}
