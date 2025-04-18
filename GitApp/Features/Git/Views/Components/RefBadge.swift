//
//  RefBadge.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//


import SwiftUI

struct RefBadge: View {
    let name: String

    private var style: (background: Color, foreground: Color, icon: String) {
        if name == "HEAD" {
            return (.blue.opacity(0.2), .blue, "point.3.connected.trianglepath.dotted")
        } else if name == "production" {
            return (.purple.opacity(0.2), .purple, "checkmark.seal.fill")
        } else if name.hasPrefix("origin/") {
            return (.green.opacity(0.2), .green, "arrow.triangle.branch")
        } else {
            return (.secondary.opacity(0.2), .secondary, "tag.fill")
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: style.icon)
                .font(.caption)
            Text(name)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(style.background)
        .foregroundColor(style.foreground)
        .cornerRadius(12)
    }
}
