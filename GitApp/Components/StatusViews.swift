import SwiftUI

struct StatusBadge: View {
    let status: FileStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: compact ? 10 : 12))

            if !compact {
                Text(status.displayName)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 2 : 4)
        .foregroundColor(.white)
        .background(Capsule().fill(status.color))
    }
}

struct TagView: View {
    var text: String
    var color: Color = .blue
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }

            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundColor(.white)
        .background(Capsule().fill(color))
    }
}

struct CountBadge: View {
    var count: Int
    var prefix: String = ""
    var textColor: Color = .primary
    var backgroundColor: Color = Color(.separatorColor).opacity(0.2)

    var body: some View {
        Text("\(prefix)\(count)")
            .font(.caption2.bold())
            .foregroundStyle(textColor)
            .padding(.horizontal, 6)
            .background(backgroundColor)
            .cornerRadius(5)
    }
}

struct SyncStatusView: View {
    var syncState: SyncState
    var pendingPushCount: Int
    var pendingCommitsCount: Int

    var body: some View {
        HStack(spacing: 12) {
            if syncState.shouldPull {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down")
                    Text("Pull needed")
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }

            if pendingPushCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                    Text("\(pendingPushCount) to push")
                }
                .font(.caption)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
            }

            if pendingCommitsCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "circle.dashed")
                    Text("\(pendingCommitsCount) to commit")
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
}

enum FileStatus: String {
    case modified = "Modified"
    case added = "Added"
    case removed = "Removed"
    case renamed = "Renamed"
    case copied = "Copied"
    case unknown = "Unknown"
    case untracked = "Untracked"
    case ignored = "Ignored"
    case deleted = "Deleted"
    case conflict = "Conflict"

    // File status codes from git
    static func fromGitStatus(_ status: String) -> FileStatus {
        switch status {
        case "M": return .modified
        case "A": return .added
        case "D": return .deleted
        case "R": return .renamed
        case "C": return .copied
        case "?": return .untracked
        case "!": return .ignored
        case "U": return .conflict
        default: return .unknown
        }
    }

    var icon: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.right.circle.fill"
        case .untracked: return "questionmark.circle.fill"
        case .ignored: return "questionmark.circle.fill"
        case .copied: return "doc.on.doc.fill"
        case .removed: return "minus.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        case .conflict: return "exclamationmark.triangle.fill"
        }
    }

    var displayName: String {
        switch self {
            case .added: return "Added"
            case .modified: return "Modified"
            case .deleted: return "Deleted"
            case .renamed: return "Renamed"
            case .untracked: return "Untracked"
            case .ignored: return "Ignored"
            case .copied: return "Copied"
            case .unknown: return "Unknown"
            case .conflict: return "Conflict"
            case .removed: return "Removed"

        }
    }

    var color: Color {
        switch self {
        case .added: return .green
        case .modified: return .blue
        case .deleted: return .red
        case .renamed: return .orange
        case .untracked: return .gray
        case .ignored: return .gray
        case .removed: return .red
        case .copied: return .yellow
        case .unknown: return .purple
        case .conflict: return .purple
        }
    }

    var shortDescription: String {
        switch self {
        case .modified: return "M"
        case .added: return "A"
        case .removed: return "R"
        case .renamed: return "Ren"
        case .copied: return "C"
        case .unknown: return "?"
        case .untracked: return "U"
        case .ignored: return "I"
        case .deleted: return "D"
        case .conflict: return "!"
        }
    }
}

// Simple horizontal progress bar
struct ProgressBar: View {
    var progress: Double
    var color: Color = .blue
    var height: CGFloat = 6
    var showPercentage: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: height)
                        .cornerRadius(height / 2)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(max(0, min(1, progress))), height: height)
                        .cornerRadius(height / 2)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
