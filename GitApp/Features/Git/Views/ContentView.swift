//
//  ContentView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GitViewModel()
    
    var body: some View {
        RepositorySelectionView(
            viewModel: viewModel
        )       
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
