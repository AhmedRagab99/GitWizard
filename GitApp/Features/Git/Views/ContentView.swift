//
//  ContentView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = RepositoryViewModel()
    @State private var accountManger: AccountManager = AccountManager()

    var body: some View {
        RepositorySelectionView(viewModel: viewModel,accountManager: accountManger)
    }
}

#Preview {
    ContentView()
}
