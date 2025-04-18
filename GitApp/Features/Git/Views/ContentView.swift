//
//  ContentView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GitViewModel()
    @State private var isShowingFilePicker = false
    @State private var selectedDirectory: URL?
    var body: some View {
        RepositorySelectionView(
            viewModel: viewModel,
            isShowingFilePicker: $isShowingFilePicker,
            selectedDirectory: $selectedDirectory
        )
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
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
    }
}

#Preview {
    ContentView()
}
