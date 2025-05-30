import Foundation
import Security

enum KeychainError: Error {
    case unhandledError(status: OSStatus)
    case itemNotFound
    case invalidData
    case duplicateItem // Added for handling existing items if needed
}

class KeychainService {

    static let shared = KeychainService()
    private init() {}

    func save(token: String, forAccountName accountName: String, serviceName: String) throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountName,
            kSecAttrService as String: serviceName,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // Good security practice
        ]

        // Delete any existing item before saving a new one to prevent duplicates
        // or update if an item already exists.
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                // This case should ideally be handled by the delete above, but as a fallback:
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unhandledError(status: status)
        }
    }

    func loadToken(forAccountName accountName: String, serviceName: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountName,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            guard let retrievedData = dataTypeRef as? Data,
                  let token = String(data: retrievedData, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return token
        } else if status == errSecItemNotFound {
            return nil // No token found is not an error in this context, just means it doesn't exist
        } else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    func deleteToken(forAccountName accountName: String, serviceName: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountName,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            // If item not found, it's already deleted, so not an error.
            throw KeychainError.unhandledError(status: status)
        }
    }

    // Generic function to save any Codable object
    func saveCodable<T: Codable>(_ item: T, service: String, account: String) throws {
        let data = try JSONEncoder().encode(item)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary) // Remove existing item first

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // Generic function to load any Codable object
    func loadCodable<T: Codable>(service: String, account: String) throws -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            guard let data = dataTypeRef as? Data else {
                throw KeychainError.invalidData
            }
            return try JSONDecoder().decode(T.self, from: data)
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
