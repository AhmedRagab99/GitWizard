//
//  StatusBadge.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//

import SwiftUI

// MARK: - Status Badge
struct StatusBadge: View {
    let status: FileStatus
    var body: some View {
        HStack(spacing: 4) {
            // Show the icon in badge for extra clarity
            Image(systemName: status.icon)
                .font(.system(size: 10))

            Text(status.shortDescription)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(status.color.opacity(0.18))
        .foregroundStyle(status.color)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(status.color.opacity(0.3), lineWidth: 1)
        )
        .help("File Status: \(status.rawValue)")
    }
}

