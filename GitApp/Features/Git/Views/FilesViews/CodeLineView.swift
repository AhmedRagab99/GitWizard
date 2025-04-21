//
//  CodeLineView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
struct CodeLineView: View {
    let line: String
    let lineNumber: Int
    let type: LineType

    enum LineType {
        case added, removed, normal

        var background: Color {
            switch self {
            case .added: return SyntaxTheme.added
            case .removed: return SyntaxTheme.removed
            case .normal: return .clear
            }
        }

        var textColor: Color {
            switch self {
            case .added: return SyntaxTheme.addedText
            case .removed: return SyntaxTheme.removedText
            case .normal: return .clear
            }
        }

        var indicator: String {
            switch self {
            case .added: return "+"
            case .removed: return "-"
            case .normal: return " "
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Line number
            Text("\(lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(SyntaxTheme.lineNumber)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)

            // Change indicator
            Text(type.indicator)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(type.textColor)
                .frame(width: 20)

            // Code content
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(type.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
//        .background(type.background)
    }
}
