//
//  GitAppApp.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

@main
struct GitAppApp: App {
    @State private var viewModel = RepositoryViewModel()
    @State private var accountManager = AccountManager()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel, accountManger: accountManager, themeManager: themeManager)
                
        }

        #if os(macOS)
        Settings {
            SettingsView(accountManager: accountManager, themeManager:themeManager, repoViewModel:viewModel)
                
        }
        #endif
    }
}
