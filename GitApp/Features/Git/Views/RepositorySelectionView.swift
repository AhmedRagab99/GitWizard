//
//  RepositorySelectionView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

struct RepositorySelectionView: View {
    @ObservedObject var viewModel: GitViewModel
    @Binding var isShowingFilePicker: Bool
    @Binding var selectedDirectory: URL?

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isSearchingRepositories {
                ProgressView("Searching for repositories...")
            } else if !viewModel.foundRepositories.isEmpty {
                List(viewModel.foundRepositories, id: \.self) { url in
                    Button {
                        viewModel.selectRepository(url)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(url.lastPathComponent)
                                .font(.headline)
                            Text(url.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button("Search Another Directory") {
                    isShowingFilePicker = true
                }
            } else {
                VStack(spacing: 16) {
                    Text("Welcome to Git Client")
                        .font(.title)

                    Text("Choose a directory to find Git repositories")
                        .foregroundColor(.secondary)

                    Button("Choose Directory") {
                        isShowingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}
