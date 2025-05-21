import Foundation


struct RepoInfo: Identifiable {
    let id = UUID()
    var name: String = "MyExampleRepo"
    var currentBranch: String = "main"
    var remotes: [Branch] = []
    var remoteURL: String = "" // GitHub repository URL
    // Add other repo details if needed
}
