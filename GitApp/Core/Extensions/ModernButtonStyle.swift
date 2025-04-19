//
//  ModernButtonStyle.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI



extension View {
    func modernShadow(_ style: ModernUI.shadow) -> some View {
        self.shadow(
            color: .black.opacity(0.1),
            radius: style.radius,
            x: 0,
            y: style.offset
        )
    }
}

// Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    let variant: Variant
    let size: Size

    enum Variant {
        case primary
        case secondary
        case tertiary
    }

    enum Size {
        case small
        case medium
        case large
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(padding)
            .background(background(for: configuration))
            .foregroundStyle(foreground(for: configuration))
            .clipShape(RoundedRectangle(cornerRadius: ModernUI.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: ModernUI.cornerRadius)
                    .stroke(border(for: configuration), lineWidth: 1)
            )
            .modernShadow(.small)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var padding: EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .medium:
            return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .large:
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }
    }

    private func background(for configuration: Configuration) -> Color {
        if configuration.isPressed {
            return pressedBackground
        }

        switch variant {
        case .primary:
            return .accentColor
        case .secondary:
            return ModernUI.colors.secondaryBackground
        case .tertiary:
            return .clear
        }
    }

    private func foreground(for configuration: Configuration) -> Color {
        if configuration.isPressed {
            return pressedForeground
        }

        switch variant {
        case .primary:
            return .white
        case .secondary, .tertiary:
            return Color(.labelColor)
        }
    }

    private func border(for configuration: Configuration) -> Color {
        if configuration.isPressed {
            return pressedBorder
        }

        switch variant {
        case .primary:
            return .clear
        case .secondary, .tertiary:
            return ModernUI.colors.border
        }
    }

    private var pressedBackground: Color {
        switch variant {
        case .primary:
            return .accentColor.opacity(0.8)
        case .secondary:
            return ModernUI.colors.secondaryBackground.opacity(0.8)
        case .tertiary:
            return .clear
        }
    }

    private var pressedForeground: Color {
        switch variant {
        case .primary:
            return .white.opacity(0.8)
        case .secondary, .tertiary:
            return Color(.labelColor).opacity(0.8)
        }
    }

    private var pressedBorder: Color {
        switch variant {
        case .primary:
            return .clear
        case .secondary, .tertiary:
            return ModernUI.colors.border.opacity(0.8)
        }
    }
}

extension ButtonStyle where Self == ModernButtonStyle {
    static func modern(_ variant: ModernButtonStyle.Variant = .primary, size: ModernButtonStyle.Size = .medium) -> ModernButtonStyle {
        ModernButtonStyle(variant: variant, size: size)
    }
}

