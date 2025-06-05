import Foundation

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case githubCom = "GitHub"
    case githubEnterprise = "GitHub Enterprise"

    var id: String { self.rawValue }
}

struct Account: Identifiable, Codable, Hashable {
    let id: UUID
    var type: AccountType
    var serverURL: String? // Required for GitHub Enterprise
    var username: String
    var token: String // This will be stored in Keychain, not directly in UserDefaults or similar
    var avatarURL: String?
    
    var provider: String {
        return type.rawValue
    }

    init(id: UUID = UUID(), type: AccountType, serverURL: String? = nil, username: String, token: String, avatarURL: String? = nil) {
        self.id = id
        self.type = type
        if type == .githubEnterprise && (serverURL == nil || serverURL?.isEmpty == true) {
            // Potentially throw an error or handle default, but for now, let's ensure it's there
            self.serverURL = "https://github.example.com" // Placeholder, should be validated
        } else {
            self.serverURL = serverURL
        }
        self.username = username
        self.token = token
        self.avatarURL = avatarURL
    }

    // For Hashable and Equatable, primarily relying on ID
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // A display name for the account, useful in UI lists
    var displayName: String {
        return username
    }

    // The effective API endpoint for the account
    var apiEndpoint: URL? {
        switch type {
        case .githubCom:
            return URL(string: "https://api.github.com")
        case .githubEnterprise:
            guard let serverURL = serverURL, let host = URL(string: serverURL)?.host else { return nil }
            return URL(string: "https://\(host)/api/v3")
        }
    }

    // The effective web URL for the account (for linking to profiles, etc.)
    var webURL: URL? {
        switch type {
        case .githubCom:
            return URL(string: "https://github.com/\(username)")
        case .githubEnterprise:
            guard let serverURL = serverURL, let cleanedServerURL = URL(string: serverURL) else { return nil }
            return cleanedServerURL.appendingPathComponent(username)
        }
    }
}
