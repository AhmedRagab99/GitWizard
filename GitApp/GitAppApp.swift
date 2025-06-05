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
    @State private var accountManger: AccountManager = AccountManager()
    @State private var themeManager : ThemeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel,accountManger: accountManger, themeManager: themeManager)
        }
    }
}
