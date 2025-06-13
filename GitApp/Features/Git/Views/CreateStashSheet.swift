//
//  CreateStashSheet.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//

import SwiftUI

struct CreateStashSheet: View {
    @Binding var isPresented: Bool
    var onStash: (_ message: String, _ keepStaged: Bool) -> Void
    @State private var message: String = ""
    @State private var keepStaged: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SheetHeader(
                title: "Create Stash",
                subtitle: "Save your changes temporarily without committing",
                icon: "archivebox",
                iconColor: .orange
            )

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("This will stash all the changes in your working copy and return it to a clean state.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)

                    FormSection(title: "Stash Message") {
                        TextField("Optional message", text: $message)
                            .textFieldStyle(.roundedBorder)
                    }

                    FormSection(title: "Options", showDivider: false) {
                        Toggle("Keep staged changes", isOn: $keepStaged)
                            .toggleStyle(.checkbox)
                    }
                }
            }

            SheetFooter(
                cancelAction: { isPresented = false },
                confirmAction: {
                    onStash(message, keepStaged)
                    isPresented = false
                },
                confirmText: "Create Stash"
            )
        }
        .padding(24)
        .frame(minWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
    }
}
