import Foundation

struct GitReset: Git {
    typealias OutputModel = String
    var arguments: [String] {
        var args = ["git", "reset"]
        if let path = path {
            args.append(path)
        }
        return args
    }
    var directory: URL
    let path: String?

    func parse(for stdOut: String) throws -> String {
        return stdOut
    }
}
