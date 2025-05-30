import Foundation

struct GitRemoteGetUrl: Git {
    typealias OutputModel = String

    let directory: URL
    let remoteName: String

    var arguments: [String] {
        return ["git", "remote", "get-url", remoteName]
    }

    func parse(for output: String) -> String {
        // Remove any trailing newlines and whitespace
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
