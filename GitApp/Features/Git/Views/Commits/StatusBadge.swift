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
        Text(status.shortDescription)
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.18))
            .foregroundStyle(status.color)
            .cornerRadius(6)
    }
}

