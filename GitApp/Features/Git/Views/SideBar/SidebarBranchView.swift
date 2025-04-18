//
//  SidebarBranchView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//


import SwiftUI
struct SidebarBranchView: View {
    let branch: Branch
    let isExpanded: Bool
    let hasSubbranches: Bool

    var body: some View {
        HStack(spacing: 6) {
            if hasSubbranches {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Image(systemName: "arrow.triangle.branch")
                .foregroundColor(.blue)

            Text(branch.name)
                .lineLimit(1)

            if branch.isCurrent {
                Spacer()
                Text("HEAD")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
}