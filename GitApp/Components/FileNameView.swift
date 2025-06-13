import SwiftUI
import Foundation

struct FileNameView: View {
    let filePath: String
    let status: FileStatus

    private var fileName: String {
        filePath.components(separatedBy: "/").last ?? filePath
    }

    private var fileExtension: String {
        fileName.components(separatedBy: ".").last ?? ""
    }

    private var statusColor: Color {
        status.color
    }

    private var statusIcon: String {
        status.icon
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.body)
                    .lineLimit(1)

                if !fileExtension.isEmpty {
                    Text(fileExtension.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
