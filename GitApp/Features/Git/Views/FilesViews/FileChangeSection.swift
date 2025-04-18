//
//  FileChangeSection.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

struct FileChangeSection: View {
    let fileChange: FileChange
    let diffContent: String?
    @Binding var expandedFile: FileChange?
    @State private var isLoading = false

    private var isExpanded: Bool {
        expandedFile?.id == fileChange.id
    }

    private var statusColor: Color {
        switch fileChange.status {
        case "Added": return .green
        case "Modified": return .yellow
        case "Deleted": return .red
        case "Renamed": return .blue
        default: return .gray
        }
    }

    private func parseLines(_ content: String) -> [(line: String, type: CodeLineView.LineType)] {
        return content.components(separatedBy: .newlines).map { line in
            if line.hasPrefix("+") {
                return (String(line.dropFirst()), .added)
            } else if line.hasPrefix("-") {
                return (String(line.dropFirst()), .removed)
            } else {
                return (line, .normal)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            Button(action: {
                withAnimation(ModernUI.animation) {
                    if isExpanded {
                        expandedFile = nil
                    } else {
                        expandedFile = fileChange
                        isLoading = true
                        // Simulate loading delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
                }
            }) {
                HStack(spacing: ModernUI.spacing) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(ModernUI.colors.secondaryText)
                        .frame(width: 20)

                    Image(systemName: fileChange.status == "Added" ? "plus.circle.fill" :
                            fileChange.status == "Modified" ? "pencil.circle.fill" :
                            fileChange.status == "Deleted" ? "minus.circle.fill" :
                            "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(statusColor)

                    FileNameView(filename: fileChange.name)

                    Spacer()

                    Text(fileChange.status)
                        .font(.caption)
                        .foregroundColor(ModernUI.colors.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, ModernUI.padding)
                .background(isExpanded ? ModernUI.colors.selection : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding()
                        Spacer()
                    }
                    .background(ModernUI.colors.secondaryBackground)
                } else if let diffContent = diffContent {
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(parseLines(diffContent).enumerated()), id: \.offset) { index, line in
                                CodeLineView(
                                    line: line.line,
                                    lineNumber: index + 1,
                                    type: line.type
                                )
                            }
                        }
                        .padding(.vertical, ModernUI.padding)
                    }
                    .background(ModernUI.colors.secondaryBackground)
                    .transition(.opacity)
                }
            }
        }
        .background(ModernUI.colors.background)
        .cornerRadius(ModernUI.cornerRadius)
        .modernShadow(.small)
    }
}

