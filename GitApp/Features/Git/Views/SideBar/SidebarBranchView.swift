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
    @ObservedObject var viewModel: GitViewModel
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            if hasSubbranches {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Image(systemName: branch.isHead ? "point.3.connected.trianglepath.dotted" : "arrow.triangle.branch")
                .foregroundColor(branch.isCurrent ? .blue : .secondary)

            Text(branch.displayName)
                .lineLimit(1)
                .foregroundColor(branch.isCurrent ? .blue : .primary)

            if branch.isCurrent {
                Spacer()
                Text("HEAD")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(branch.isCurrent ? Color.blue.opacity(0.15) : (isHovered ? Color.secondary.opacity(0.1) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(branch.isCurrent ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            Task {
                await viewModel.checkoutBranch(branch)
            }
        }
        .contextMenu {
            Button(action: {
                Task {
                    await viewModel.checkoutBranch(branch)
                }
            }) {
                Label("Checkout", systemImage: "arrow.triangle.branch")
            }

            if !branch.isCurrent {
                Button(action: {
                    // TODO: Implement delete branch
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
