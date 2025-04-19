//
//  GitAppApp.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

@main
struct GitAppApp: App {
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        ThemeToggleButton()
                    }
                }
                .themeManager(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
