//
//  OrganizationRow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//

import SwiftUI

struct OrganizationRow: View {
    let organization: GitHubOrganization

    var body: some View {
        HStack {
            if let avatarURLString = organization.avatarUrl, let avatarURL = URL(string: avatarURLString) {
                AsyncImage(url: avatarURL) { image in image.resizable() }
                placeholder: { Image(systemName: "person.2.crop.square.stack.fill").resizable() }
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "person.2.crop.square.stack.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading) {
                Text(organization.login).font(.headline)
                if let description = organization.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
