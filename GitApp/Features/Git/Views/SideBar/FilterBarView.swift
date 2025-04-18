//
//  FilterBarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
struct FilterBarView: View {
    @Binding var filterText: String
    var onAddClick: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter", text: $filterText)
                    .textFieldStyle(.plain)
            }
            .padding(6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)

            Button(action: onAddClick) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }
}
