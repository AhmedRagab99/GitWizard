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
            // Status icon
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
                .imageScale(.medium)

            // Status name with indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)

                Text(status.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary.opacity(0.9))
            }

            // File count with background
            Text("\(count)")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(status.color.opacity(0.15))
                )
                .foregroundStyle(status.color)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor).opacity(0.95))
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
}
