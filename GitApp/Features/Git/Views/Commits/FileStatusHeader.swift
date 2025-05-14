//
//  FileStatusHeader.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//
import SwiftUI

struct FileStatusHeader: View {
    let status: FileStatus
    let count: Int
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
            Text(status.rawValue)
                .font(.subheadline.bold())
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.controlBackgroundColor).opacity(0.95))
    }
}
