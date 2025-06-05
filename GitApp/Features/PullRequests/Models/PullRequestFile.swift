import Foundation

/// Represents a file changed in a pull request.
struct PullRequestFile: Codable, Identifiable, Hashable {
    // If the API provides a unique ID for the file entry, use it.
    // Otherwise, filename can serve as a unique identifier within a single PR's file list.
    // For Hashable and Identifiable, we might need to ensure `filename` or `sha` is unique enough.
    var id: String { sha ?? filename } // Prefer SHA if available, fallback to filename.

    let sha: String? // Blob SHA of the file.
    let filename: String // Path of the file.
    let status: String // e.g., "added", "modified", "removed", "renamed".
    let additions: Int
    let deletions: Int
    let changes: Int // Total changes (additions + deletions)
    let blobUrl: String? // URL to the file content (blob).
    let rawUrl: String? // URL to the raw file content.
    let contentsUrl: String? // API URL for file contents.
    let patch: String? // The diff patch for the file.

    // For renamed files
    let previousFilename: String?

    enum CodingKeys: String, CodingKey {
        case sha
        case filename
        case status
        case additions
        case deletions
        case changes
        case blobUrl = "blob_url"
        case rawUrl = "raw_url"
        case contentsUrl = "contents_url"
        case patch
        case previousFilename = "previous_filename"
    }

    /// Maps the string status to a more structured enum if needed.
    enum FileStatus: String {
        case added, modified, removed, renamed, copied, changed, unchanged
    }

    var fileStatus: FileStatus {
        FileStatus(rawValue: status) ?? .changed // Default to .changed if unknown
    }
}
