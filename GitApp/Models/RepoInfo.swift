import Foundation


struct RepoInfo: Identifiable {
    let id = UUID()
    var name: String = "MyExampleRepo"
    var currentBranch: String = "main"
    var remotes: [Remote] = []
    // Add other repo details if needed
}
