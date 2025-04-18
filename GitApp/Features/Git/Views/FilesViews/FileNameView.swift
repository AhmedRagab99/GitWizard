//
//  FileNameView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI

struct FileNameView: View {
    let filename: String
    let fileType: FileType

    init(filename: String) {
        self.filename = filename
        self.fileType = FileType(from: filename)
    }

    private var directory: String? {
        let components = filename.components(separatedBy: "/")
        return components.count > 1 ? components.dropLast().joined(separator: "/") : nil
    }

    private var name: String {
        filename.components(separatedBy: "/").last ?? filename
    }

    var body: some View {
        HStack(spacing: 4) {
            // File icon
            Image(systemName: fileType.icon)
                .foregroundColor(fileType.color)
                .font(.system(size: 16))

            // Directory path (if exists)
            if let directory = directory {
                Text(directory + "/")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            }

            // File name
            Text(name)
                .foregroundColor(ModernUI.colors.text)
                .font(.system(size: 14, weight: .medium))

            // File type badge
            Text(fileType.label)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(fileType.color.opacity(0.1))
                .foregroundColor(fileType.color)
                .cornerRadius(4)
        }
    }
}
