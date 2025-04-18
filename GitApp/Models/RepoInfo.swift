import Foundation

struct RepoInfo: Identifiable {
    let id = UUID()
    var name: String = "MyExampleRepo"
    var currentBranch: String = "main"
    var remotes: [(name: String, url: String)] = []
    // Add other repo details if needed
}
