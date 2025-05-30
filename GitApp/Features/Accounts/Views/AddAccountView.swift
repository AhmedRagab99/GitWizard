import SwiftUI

struct AddAccountView: View {
    @Environment(\.dismiss) var dismiss
    var accountManager: AccountManager

    @State private var accountType: AccountType = .githubCom
    @State private var serverURL: String = ""
    @State private var username: String = "" // Optional: could prefill or ask, but token is key
    @State private var token: String = ""

    @State private var isAdding: Bool = false
    @State private var addError: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text(accountType == .githubCom ? "Add GitHub.com Account" : "Add GitHub Enterprise Account")
                .font(.title2)
                .fontWeight(.semibold)

            Picker("Account Type", selection: $accountType) {
                ForEach(AccountType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom)

            if accountType == .githubEnterprise {
                VStack(alignment: .leading) {
                    Text("Server URL").font(.headline)
                    TextField("https://github.yourcompany.com", text: $serverURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                }
            }

            VStack(alignment: .leading) {
                Text("Personal Access Token").font(.headline)
                SecureField("Enter your token", text: $token)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Link("Create a token on GitHub", destination: URL(string: "https://github.com/settings/tokens/new?scopes=repo,user,gist,workflow")!)
                    .font(.caption)
            }

            if let addError = addError {
                Text(addError)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: addAccount) {
                    if isAdding {
                        ProgressView()
                    } else {
                        Text(accountType == .githubCom ? "Add GitHub.com Account" : "Add Enterprise Account")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(token.isEmpty || (accountType == .githubEnterprise && serverURL.isEmpty) || isAdding)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 450, maxWidth: 500)
        .onDisappear {
            // Clear any lingering error messages from this view specifically when it disappears
            // to prevent it from affecting other parts of the app or a new presentation of this view.
            if addError != nil {
                accountManager.errorMessage = nil
            }
        }
    }

    private func addAccount() {
        isAdding = true
        addError = nil // Clear previous specific error for this view
        accountManager.errorMessage = nil // Clear global error message before new attempt

        Task {
            let success = await accountManager.addAccount(
                type: accountType,
                username: username, // Username will be fetched via token validation
                token: token,
                serverURL: accountType == .githubEnterprise ? serverURL : nil
            )
            // The onChange for accountManager.errorMessage will handle UI updates (dismissal or error display)
            if success {
                dismiss()
            } else {
                // If addAccount returned false, it means errorMessage should be set in accountManager
                addError = accountManager.errorMessage
            }
            isAdding = false
        }
    }
}

struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddAccountView(accountManager: AccountManager())
    }
}
