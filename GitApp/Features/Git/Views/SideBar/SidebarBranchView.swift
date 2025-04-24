//
//  SidebarBranchView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//


import SwiftUI
import Foundation



struct SidebarBranchView: View {
    let branch: Branch
    let isExpanded: Bool
    let hasSubbranches: Bool
    @Bindable var viewModel: GitViewModel
    @State private var isHovered = false

    private let selectedBackgroundColor = Color(red: 0.32, green: 0.48, blue: 0.96)
    private let hoverBackgroundColor = Color(.unemphasizedSelectedContentBackgroundColor)

    var body: some View {
        HStack(spacing: 6) {

            Image(systemName: branch.isCurrent ? "point.3.connected.trianglepath.dotted" : "arrow.triangle.branch")
                .foregroundColor(branch.isCurrent ? .white : .secondary)
                .frame(width: 16)

            Text(branch.name)
                .lineLimit(1)
                .foregroundColor(branch.isCurrent ? .white : .primary)

            if branch.isCurrent {
                Spacer()
                Text("HEAD")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(branch.isCurrent ? selectedBackgroundColor : (isHovered ? hoverBackgroundColor : Color.clear))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            checkoutBranch()
        }
        .contextMenu {
            Button(action: checkoutBranch) {
                Label("Checkout", systemImage: "arrow.triangle.branch")
            }

            Button(action: pullBranch) {
                Label("Pull from origin", systemImage: "arrow.down")
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

    private func checkoutBranch() {
        Task { @MainActor in
            await viewModel.checkoutBranch(branch)
        }
    }

    private func pullBranch() {
        Task { @MainActor in
            await viewModel.pull()
        }
    }
}
