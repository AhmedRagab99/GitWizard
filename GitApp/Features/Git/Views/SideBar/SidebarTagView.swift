//
//  SidebarTagView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
struct SidebarTagView: View {
    let tag: Tag

    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .foregroundColor(.blue)
            Text(tag.name)
                .lineLimit(1)
        }
    }
}
