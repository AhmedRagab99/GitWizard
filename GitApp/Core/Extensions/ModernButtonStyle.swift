//
//  ModernButtonStyle.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI



extension View {
    func modernShadow(_ style: ModernUI.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    let style: Style
    @Environment(\.isEnabled) private var isEnabled

    enum Style {
        case primary, secondary, ghost

        var background: Color {
            switch self {
            case .primary: return ModernUI.colors.accent
            case .secondary: return ModernUI.colors.secondaryBackground
            case .ghost: return .clear
            }
        }

        var foreground: Color {
            switch self {
            case .primary: return .white
            case .secondary, .ghost: return ModernUI.colors.text
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(style.background.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(style.foreground)
            .cornerRadius(ModernUI.cornerRadius)
            .opacity(isEnabled ? 1 : 0.5)
            .modernShadow(configuration.isPressed ? .small : .medium)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

