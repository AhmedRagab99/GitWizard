//
//  CommitGraphVisualization.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
struct CommitGraphVisualization: View {
    let commit: Commit
    let previousCommit: Commit?
    let nextCommit: Commit?
    @State private var isHovered = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let nodeSize: CGFloat = 14
            let lineWidth: CGFloat = 2

            Canvas { context, size in
                // Draw branch lines
                for (index, _) in commit.parentHashes.enumerated() {
                    let startX = width / 2
                    let startY = height / 2
                    let endY = height

                    let path = Path { p in
                        p.move(to: CGPoint(x: startX, y: startY))
                        if commit.commitType == .merge && index > 0 {
                            // Draw merge line with curve
                            let controlX = startX - 20.0
                            p.addCurve(
                                to: CGPoint(x: startX, y: endY),
                                control1: CGPoint(x: controlX, y: startY),
                                control2: CGPoint(x: controlX, y: endY)
                            )
                        } else {
                            // Draw straight line for main branch
                            p.addLine(to: CGPoint(x: startX, y: endY))
                        }
                    }

                    context.stroke(
                        path,
                        with: .linearGradient(
                            .init(colors: [
                                commit.commitType == .merge ? .purple.opacity(0.3) : .blue.opacity(0.3),
                                commit.commitType == .merge ? .purple.opacity(0.1) : .blue.opacity(0.1)
                            ]),
                            startPoint: .init(x: 0, y: 0),
                            endPoint: .init(x: 0, y: size.height)
                        ),
                        lineWidth: lineWidth
                    )
                }
            }

            // Commit node
            Circle()
                .fill(commitColor)
                .frame(width: nodeSize, height: nodeSize)
                .shadow(color: commitColor.opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(isHovered ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                .position(x: width / 2, y: height / 2)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var commitColor: Color {
        switch commit.commitType {
        case .normal: return .blue
        case .merge: return .purple
        case .rebase: return .orange
        case .cherryPick: return .green
        case .revert: return .red
        }
    }
}

