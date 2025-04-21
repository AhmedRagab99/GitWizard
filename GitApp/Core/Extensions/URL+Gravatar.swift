import Foundation
import CommonCrypto
extension URL {
    static func gravater(email: String) -> URL? {
        let emailHash = email.lowercased().md5Hash
        return URL(string: "https://www.gravatar.com/avatar/\(emailHash)?d=identicon&s=40")
    }
}

extension String {
    var md5Hash: String {
        let data = Data(utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
