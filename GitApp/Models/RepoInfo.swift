import Foundation

struct Remote: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: String
}

struct RepoInfo: Identifiable {
    let id = UUID()
    var name: String = "MyExampleRepo"
    var currentBranch: String = "main"
    var remotes: [Remote] = []
    // Add other repo details if needed
}
