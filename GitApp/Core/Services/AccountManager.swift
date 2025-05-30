import Foundation
import Combine

// Define a key for storing account metadata (excluding tokens) in UserDefaults
private let userDefaultsAccountsKey = "gitapp_accounts_metadata"

@Observable
@MainActor
class AccountManager {
    var accounts: [Account] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let keychainService = KeychainService.shared
    private let serviceName = "com.yourapp.gitapp.tokens"

    init() {
        loadAccountsMetadata()
    }

    // MARK: - Account List Management (Metadata only in UserDefaults)
    private func loadAccountsMetadata() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsAccountsKey) else {
            self.accounts = []
            return
        }
        do {
            let decodedAccounts = try JSONDecoder().decode([Account].self, from: data)
            // Tokens are not stored in metadata; they should be loaded from Keychain on demand
            // or when an account is explicitly used.
            self.accounts = decodedAccounts.map { account in
                var mutableAccount = account
                // Clear token from metadata version, it will be loaded from keychain when needed
                mutableAccount.token = ""
                return mutableAccount
            }
        } catch {
            print("Failed to decode accounts metadata: \(error)")
            self.accounts = []
            // Optionally, clear corrupted data from UserDefaults
            // UserDefaults.standard.removeObject(forKey: userDefaultsAccountsKey)
        }
    }

    private func saveAccountsMetadata() {
        // Before saving, ensure tokens are not part of the metadata being saved to UserDefaults
        let metadataAccounts = accounts.map { account -> Account in
            var tempAccount = account
            tempAccount.token = "" // Ensure token is not saved to UserDefaults
            return tempAccount
        }
        do {
            let data = try JSONEncoder().encode(metadataAccounts)
            UserDefaults.standard.set(data, forKey: userDefaultsAccountsKey)
        } catch {
            print("Failed to encode accounts metadata: \(error)")
            // Handle error appropriately, maybe show an alert to the user
        }
    }

    // MARK: - CRUD Operations for Accounts

    func addAccount(type: AccountType, username: String, token: String, serverURL: String? = nil) async {
        isLoading = true
        errorMessage = nil
        var accountUsername = username

        do {
            // 1. Verify token and fetch user details to get the correct username and avatar
            let apiEndpoint: URL
            let actualServerURL: String?

            switch type {
            case .githubCom:
                apiEndpoint = URL(string: "https://api.github.com/user")!
                actualServerURL = nil
            case .githubEnterprise:
                guard let enterpriseURLString = serverURL, !enterpriseURLString.isEmpty,
                      let enterpriseBaseURL = URL(string: enterpriseURLString),
                      let host = enterpriseBaseURL.host else {
                    throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid GitHub Enterprise server URL."])
                }
                apiEndpoint = URL(string: "https://\(host)/api/v3/user")!
                actualServerURL = enterpriseURLString
            }

            var request = URLRequest(url: apiEndpoint)
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Failed to verify token with GitHub. Status: \(statusCode)"])
            }

            let githubUser = try JSONDecoder().decode(GitHubUser.self, from: data)
            accountUsername = githubUser.login // Use the login from GitHub as the canonical username

            // 2. Check for duplicates based on username and type/serverURL
            if accounts.contains(where: { acc in
                acc.username.lowercased() == accountUsername.lowercased() &&
                acc.type == type &&
                (type == .githubEnterprise ? acc.serverURL?.lowercased() == actualServerURL?.lowercased() : true)
            }) {
                throw NSError(domain: "AccountManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "This account (\(accountUsername) for \(type.rawValue)) already exists."])
            }

            // 3. Create Account object
            let newAccount = Account(type: type, serverURL: actualServerURL, username: accountUsername, token: "", avatarURL: githubUser.avatarUrl) // Token placeholder

            // 4. Save token to Keychain
            try keychainService.save(token: token, forAccountName: keychainAccountName(for: newAccount), serviceName: serviceName)

            // 5. Add to accounts array and save metadata
            accounts.append(newAccount)
            saveAccountsMetadata()

        } catch {
            self.errorMessage = "Error adding account: \(error.localizedDescription)"
            print("Error adding account: \(error)")
        }
        isLoading = false
    }

    func updateAccountToken(accountID: UUID, newToken: String) async {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else {
            errorMessage = "Account not found for update."
            return
        }
        isLoading = true
        errorMessage = nil
        var accountToUpdate = accounts[index]

        do {
            // Verify the new token and fetch user details to ensure it's valid
            let apiEndpoint: URL
            switch accountToUpdate.type {
            case .githubCom:
                apiEndpoint = URL(string: "https://api.github.com/user")!
            case .githubEnterprise:
                guard let serverURL = accountToUpdate.serverURL, let host = URL(string: serverURL)?.host else {
                    throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid GitHub Enterprise server URL for token update."])
                }
                apiEndpoint = URL(string: "https://\(host)/api/v3/user")!
            }

            var request = URLRequest(url: apiEndpoint)
            request.setValue("token \(newToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Failed to verify new token. Status: \(statusCode)"])
            }
            let githubUser = try JSONDecoder().decode(GitHubUser.self, from: data)

            // Update Keychain
            try keychainService.save(token: newToken, forAccountName: keychainAccountName(for: accountToUpdate), serviceName: serviceName)

            // Update account details if necessary (e.g., avatar URL might change)
            accountToUpdate.avatarURL = githubUser.avatarUrl
            // Note: username should ideally not change for an existing account with the same ID.
            // If the token belongs to a *different* user, that's a more complex scenario (e.g., should it be a new account?)
            // For simplicity, we assume token updates are for the *same* user identity.

            accounts[index] = accountToUpdate
            saveAccountsMetadata() // Save updated metadata (e.g., new avatarURL)

        } catch {
            self.errorMessage = "Error updating token: \(error.localizedDescription)"
            print("Error updating token: \(error)")
        }
        isLoading = false
    }

    func deleteAccount(accountID: UUID) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        let accountToDelete = accounts[index]

        do {
            try keychainService.deleteToken(forAccountName: keychainAccountName(for: accountToDelete), serviceName: serviceName)
            accounts.remove(at: index)
            saveAccountsMetadata()
        } catch {
            self.errorMessage = "Error deleting account: \(error.localizedDescription)"
            print("Error deleting account: \(error)")
        }
    }

    func getToken(for account: Account) -> String? {
        // This is a synchronous call to keychain, consider if async is needed for your UI responsiveness
        // For simplicity, keeping it sync here as it's often called when account is already known/selected.
        do {
            return try keychainService.loadToken(forAccountName: keychainAccountName(for: account), serviceName: serviceName)
        } catch {
            print("Failed to load token for \(account.username): \(error.localizedDescription)")
            // Potentially set errorMessage or handle specific keychain errors
            return nil
        }
    }

    // Helper to generate a unique name for storing in Keychain
    private func keychainAccountName(for account: Account) -> String {
        if account.type == .githubEnterprise, let serverHost = URL(string: account.serverURL ?? "")?.host {
            return "\(account.username)@\(serverHost)"
        }
        return "\(account.username)@\(account.type.rawValue)" // e.g., user@GitHub.com
    }

    // MARK: - Fetching Repositories for an Account

    func fetchRepositories(for account: Account) async throws -> [GitHubRepository] {
        guard let token = getToken(for: account), !token.isEmpty else {
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: "Missing token for account \(account.username)."])
        }

        guard let baseApiUrl = account.apiEndpoint else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint for account \(account.username)."])
        }

        // GitHub API endpoint for listing authenticated user's repositories
        // Supports pagination, but for simplicity, fetching first page (up to 100 repos by default).
        // Add `?per_page=100&page=X` for pagination.
        let reposUrl = baseApiUrl.appendingPathComponent("user/repos?type=owner&sort=updated&per_page=100")

        var request = URLRequest(url: reposUrl)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            // You might want to parse the error message from GitHub API if available in `data`
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch repositories. Status: \(statusCode)"])
        }

        let repositories = try JSONDecoder().decode([GitHubRepository].self, from: data)
        return repositories
    }

    func fetchUserDetails(for account: Account) async throws -> GitHubUser {
        guard let token = getToken(for: account), !token.isEmpty else {
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: "Missing token for account \(account.username)."])
        }

        guard let userApiUrl = account.apiEndpoint?.appendingPathComponent("user") else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid user API endpoint for account \(account.username)."])
        }

        var request = URLRequest(url: userApiUrl)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user details. Status: \(statusCode)"])
        }

        let user = try JSONDecoder().decode(GitHubUser.self, from: data)
        return user
    }
}
