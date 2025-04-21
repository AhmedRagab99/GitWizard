import Foundation
import CryptoKit

extension String {
    static let formatSeparator = "{separator-44cd166895ac93832525}"
    static let componentSeparator = "{component-separator-44cd166895ac93832525}"
}


extension URL {
    static var testFixture: URL? {
        guard let srcroot = ProcessInfo.processInfo.environment["SRCROOT"] else { return nil }
        return URL(fileURLWithPath: srcroot).appending(path: "TestFixtures").appending(path: "SyntaxHighlight")
    }

    static func gravater(email: String, size: Int=80) -> String? {
        let data = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailHash = data.md5Hash
        let authorAvatar = "https://www.gravatar.com/avatar/\(emailHash)?d=identicon&s=\(size)"

        return authorAvatar
//        return  "https://gravatar.com/avatar/" + hashString + "?d=retro&size=\(size)"
        // https://docs.gravatar.com/api/avatars/images/
    }
}
