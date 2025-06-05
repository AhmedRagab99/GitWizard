//
//  ContentView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

struct ContentView: View {
    var viewModel: RepositoryViewModel
    var accountManger: AccountManager
    var themeManager: ThemeManager

    var body: some View {
        RepositorySelectionView(viewModel: viewModel,accountManager: accountManger,themeManger: themeManager)
    }
}
