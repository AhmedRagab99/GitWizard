//
//  UpdateTokenView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//
import SwiftUI

struct UpdateTokenView: View {
    @Environment(\.dismiss) var dismiss
    let account: Account
     var accountManager: AccountManager

    @State private var newToken: String = ""
    @State private var isUpdating: Bool = false
    @State private var updateError: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Update Token for \(account.username)")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading) {
                Text("New Personal Access Token").font(.headline)
                SecureField("Enter new token", text: $newToken)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Link("Create a token on GitHub", destination: URL(string: "https://github.com/settings/tokens/new?scopes=repo,user,gist,workflow")!)
                    .font(.caption)
            }

            if let updateError = updateError {
                Text(updateError)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: performUpdate) {
                    if isUpdating {
                        ProgressView()
                    } else {
                        Text("Update Token")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newToken.isEmpty || isUpdating)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 450, maxWidth: 500)
        .onChange(of: accountManager.errorMessage) { oldValue, newValue in
            if isUpdating { // Only update error if it pertains to the current update operation
                updateError = newValue
                if newValue == nil { // If error becomes nil, it means success
                    dismiss()
                }
                isUpdating = false // Reset updating state
            }
        }
        .onDisappear {
            if updateError != nil {
                accountManager.errorMessage = nil
            }
        }
    }

    private func performUpdate() {
        isUpdating = true
        updateError = nil
        accountManager.errorMessage = nil // Clear global error

        Task {
            await accountManager.updateAccountToken(accountID: account.id, newToken: newToken)
            // onChange for accountManager.errorMessage will handle UI update
        }
    }
}
