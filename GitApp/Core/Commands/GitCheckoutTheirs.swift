import Foundation

struct GitCheckoutTheirs: Git {
    typealias OutputModel = String

    let directory: URL
    let filePath: String

    init(directory: URL, filePath: String) {
        self.directory = directory
        self.filePath = filePath
    }

    var executable: String {
        "git"
    }

    var arguments: [String] {
        ["git", "checkout", "--theirs", filePath]
    }

    func parse(for output: String) throws -> String {
        return output
    }
}
