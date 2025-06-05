//
//  AccountRow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//

import SwiftUI

struct AccountRow: View {
    let account: Account
    @Binding var selectedAccountID: Account.ID? // Added binding

    var isSelected: Bool { // Computed property for selection state
        account.id == selectedAccountID
    }

    var body: some View {
        HStack(spacing: 10) { // Adjusted spacing
            if let avatarURLString = account.avatarURL, let avatarURL = URL(string: avatarURLString) {
                AsyncImage(url: avatarURL) {
                    image in image.resizable()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 3) { // Adjusted spacing
                Text(account.username).font(.headline).lineLimit(1)
                Text(account.type.rawValue).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                if account.type == .githubEnterprise, let server = account.serverURL {
                    Text(URL(string: server)?.host ?? "Enterprise")
                        .font(.caption2) // Made smaller
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            Spacer() // Ensure content pushes to leading edge
        }
        .padding(.vertical, 6) // Adjusted padding
        .padding(.horizontal, 8)
        // Use the computed isSelected property
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
}
