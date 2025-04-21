import Foundation

struct Remote: Codable, Identifiable {
    var id = UUID()
    let name: String
    var url: String = ""

    static func parseRemotes(from output: String) -> [Remote] {
        return output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { line in
                let components = line.components(separatedBy: "\t")
                return Remote(name: components[0], url: components[1])
            }
    }
}
