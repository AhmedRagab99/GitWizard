//
//  AccountRow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//

import SwiftUI

struct AccountRow: View {
    let account: Account
    @Binding var selectedAccountID: Account.ID?
    var onEditToken: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var isSelected: Bool {
        account.id == selectedAccountID
    }

    var body: some View {
        ListRow(
            isSelected: isSelected,
            padding: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8),
            onTap: { selectedAccountID = account.id },
            cornerRadius: 8,
            shadowRadius: 1
        ) {
            HStack(spacing: 10) {
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
                VStack(alignment: .leading, spacing: 3) {
                    Text(account.username).font(.headline).lineLimit(1)
                    Text(account.type.rawValue).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                    if account.type == .githubEnterprise, let server = account.serverURL {
                        Text(URL(string: server)?.host ?? "Enterprise")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
        .withContextMenu(type: .custom(items: [
            ContextMenuItems.MenuItem(label: "Update Token", icon: "key.fill", action: {
                onEditToken?()
            }),
            ContextMenuItems.MenuItem(label: "Copy Username", icon: "doc.on.clipboard", action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(account.username, forType: .string)
            }),
            ContextMenuItems.MenuItem(label: "Delete Account", icon: "trash", action: {
                onDelete?()
            }, role: .destructive)
        ]))
    }
}
