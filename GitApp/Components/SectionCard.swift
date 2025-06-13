//
//  SectionCard.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//
import SwiftUI

// MARK: - Section Card
struct SectionCard<Content: View>: View {
    let title: String
    let count: Int
    let actionTitle: String
    let action: () -> Void
    let showAction: Bool
    let icon: String
    let iconColor: Color
    let content: Content

    init(title: String, count: Int, actionTitle: String, action: @escaping () -> Void, showAction: Bool, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.count = count
        self.actionTitle = actionTitle
        self.action = action
        self.showAction = showAction
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.title3.bold())
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if showAction {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.systemGray))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.systemGray).opacity(0.2))
            )
            .padding(.bottom, 2)
            content
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
    }
}
