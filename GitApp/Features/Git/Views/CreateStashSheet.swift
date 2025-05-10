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
        VStack(alignment: .leading, spacing: 20) {
            Text("This will stash all the changes in your working copy and return it to a clean state.")
                .font(.body)
            VStack(alignment: .leading, spacing: 8) {
                Text("Message:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Optional", text: $message)
                    .textFieldStyle(.roundedBorder)
            }
            Toggle(isOn: $keepStaged) {
                Text("Keep staged changes")
            }
            .toggleStyle(.checkbox)
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Stash") {
                    onStash(message, keepStaged)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .shadow(radius: 20)
    }
}
