//
//  BranchTagView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

// Branch Tag View
struct BranchTagView: View {
    let name: String
    let type: BranchType

    enum BranchType {
        case head
        case branch
        case tag
        case production

        var backgroundColor: Color {
            switch self {
            case .head: return .blue.opacity(0.2)
            case .branch: return .secondary.opacity(0.15)
            case .tag: return .green.opacity(0.2)
            case .production: return .purple.opacity(0.2)
            }
        }

        var textColor: Color {
            switch self {
            case .head: return .blue
            case .branch: return .secondary
            case .tag: return .green
            case .production: return .purple
            }
        }
    }

    var body: some View {
        Text(name)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(type.backgroundColor)
            .foregroundColor(type.textColor)
            .clipShape(Capsule())
    }
}
