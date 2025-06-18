import Foundation
import Combine
import os

actor GitService {
    private var cloneProgress: Double = 0.0
    private var cloneStatus: String = ""

    var progress: Double { cloneProgress }
    var status: String { cloneStatus }

    func resetProgress() {
        cloneProgress = 0.0
        cloneStatus = ""
    }

    func updateProgress(_ progress: Double, status: String) {
        cloneProgress = progress
        cloneStatus = status
    }

    func isGitRepository(at url: URL) -> Bool {
        let gitDir = url.appendingPathComponent(".git")
        var isDirectory: ObjCBool = false

        if FileManager.default.fileExists(atPath: gitDir.path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        }

        let headFile = url.appendingPathComponent("HEAD")
        let configFile = url.appendingPathComponent("config")

        return FileManager.default.fileExists(atPath: headFile.path) &&
               FileManager.default.fileExists(atPath: configFile.path)
    }

    // MARK: - Branch Operations
    func getBranches(in directory: URL, isRemote: Bool = false) async throws -> [Branch] {
        try await Process.output(GitBranch(directory: directory, isRemote: isRemote))
    }

    func getCurrentBranch(in directory: URL) async throws -> String? {
        try await Process.output(GitCurrentBranch(directory: directory))
    }

    func switchBranch(to branchName: String, in directory: URL, discardLocalChanges: Bool = false) async throws {
        try await Process.output(GitSwitch(directory: directory, branchName: branchName, discardLocalChanges: discardLocalChanges))
    }

    func checkoutBranch(to branchName: Branch, in directory: URL, discardLocalChanges: Bool = false) async throws {
        try await Process.output(GitCheckoutB(directory: directory, newBranchName: branchName.name, startPoint: branchName.point, discardLocalChanges: discardLocalChanges))
    }

    func deleteBranch(_ branchName: String, in directory: URL, isRemote: Bool = false, forceDelete: Bool = false) async throws {
        try await Process.output(GitBranchDelete(directory: directory, isRemote: isRemote, branchName: branchName, forceDelete: forceDelete))
    }

    // MARK: - Commit Operations
    func getCommits(in directory: URL, branch: String? = nil) async throws -> [Commit] {
        let gitLog = GitLog(directory: directory)
        if let branch = branch {
            gitLog.revisionRange = branch
        }
        return try await Process.output(gitLog)
    }

    func commitChanges(in directory: URL, message: String) async throws {
        try await Process.output(GitCommit(directory: directory, message: message))
    }

    func amendCommit(in directory: URL, message: String) async throws {
        try await Process.output(GitCommitAmend(directory: directory, message: message))
    }

    // MARK: - File Operations
    func getStatus(in directory: URL) async throws -> Status {
        try await Process.output(GitStatus(directory: directory))
    }

    func getDiff(in directory: URL, cached: Bool = false) async throws -> Diff {
        let output = try await Process.output(GitDiff(directory: directory, cached: cached))
        return try Diff(raw: output)
    }

    func addFiles(in directory: URL, pathspec: String? = nil) async throws {
        if let pathspec = pathspec {
            try await Process.output(GitAddPathspec(directory: directory, pathspec: pathspec))
        } else {
            try await Process.output(GitAdd(directory: directory))
        }
    }

    func restoreFiles(in directory: URL) async throws {
        try await Process.output(GitRestore(directory: directory))
    }

    // MARK: - Remote Operations
    func getRemotes(in directory: URL) async throws -> [Branch] {
        return try await Process.output(GitBranch(directory: directory, isRemote: true))
    }

    func getRemoteNames(in directory: URL) async throws -> [String] {
        // Use git remote command to get just the remote names
        let output = try await Process.output(GitRemoteList(directory: directory))
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    func getRemoteURL(in directory: URL, remoteName: String = "origin") async throws -> String {
        // Get the actual URL of a remote repository
        return try await Process.output(GitRemoteGetUrl(directory: directory, remoteName: remoteName))
    }

    func fetch(in directory: URL, remote: String = "origin", fetchAllRemotes: Bool = false, prune: Bool = false, fetchTags: Bool = false) async throws {
        try await Process.output(GitFetch(
            directory: directory,
            remote: remote,
            fetchAllRemotes: fetchAllRemotes,
            prune: prune,
            fetchTags: fetchTags
        ))
    }

    func pull(in directory: URL, remote: String = "origin", remoteBranch: String = "", localBranch: String = "", commitMerged: Bool = false, includeMessages: Bool = false, createNewCommit: Bool = false, rebaseInsteadOfMerge: Bool = false) async throws {
        try await Process.output(GitPull(
            directory: directory,
            remote: remote,
            remoteBranch: remoteBranch,
            localBranch: localBranch,
            commitMerged: commitMerged,
            includeMessages: includeMessages,
            createNewCommit: createNewCommit,
            rebaseInsteadOfMerge: rebaseInsteadOfMerge
        ))
    }

    func push(in directory: URL, refspec: String = "HEAD", pushTags: Bool = false) async throws {
        try await Process.output(GitPush(directory: directory, refspec: refspec, pushTags: pushTags))
    }

    // MARK: - Tag Operations
    func getTags(in directory: URL) async throws -> [Tag] {
        try await Process.output(GitTagList(directory: directory))
    }

    func createTag(in directory: URL, name: String, object: String) async throws {
        try await Process.output(GitTagCreate(directory: directory, tagname: name, object: object))
    }

    // MARK: - Merge Operations
    func merge(
        in directory: URL,
        branchName: String,
        commitMerged: Bool = true,
        includeMessages: Bool = false,
        createNewCommit: Bool = false,
        rebaseInsteadOfMerge: Bool = false
    ) async throws {
        try await Process.output(GitMerge(
            directory: directory,
            branchName: branchName,
            commitMerged: commitMerged,
            includeMessages: includeMessages,
            createNewCommit: createNewCommit,
            rebaseInsteadOfMerge: rebaseInsteadOfMerge
        ))
    }

    func revert(in directory: URL, commit: String, parentNumber: Int? = nil) async throws {
        try await Process.output(GitRevert(directory: directory, parentNumber: parentNumber, commit: commit))
    }

    // MARK: - Stash Operations
    func getStashes(in directory: URL) async throws -> [Stash] {
        try await Process.output(GitStashList(directory: directory))
    }

    // MARK: - Conflict Resolution

    func resolveConflict(in directory: URL, filePath: String, useOurs: Bool) async throws {
        if useOurs {
            _ = try await Process.output(GitCheckoutOurs(directory: directory, filePath: filePath))
        } else {
            _ = try await Process.output(GitCheckoutTheirs(directory: directory, filePath: filePath))
        }
        // After checking out 'ours' or 'theirs', the conflict is resolved for that file.
        // We must then add the file to the index to mark it as resolved.
        try await stage(files: [filePath], in: directory)
    }

    func resolveConflictUsingOurs(filePath: String, in directory: URL) async throws {
        try await Process.output(GitCheckoutOurs(directory: directory, filePath: filePath))
    }

    func resolveConflictUsingTheirs(filePath: String, in directory: URL) async throws {
        try await Process.output(GitCheckoutTheirs(directory: directory, filePath: filePath))
    }

    func markConflictResolved(filePath: String, in directory: URL) async throws {
        try await Process.output(GitAddPathspec(directory: directory, pathspec: filePath))
    }

    func hasConflicts(in directory: URL) async throws -> Bool {
        // Get status and check for conflict markers
        let status = try await getStatus(in: directory)
        return !status.conflicted.isEmpty
    }

    // MARK: - Repository Operations
    func findGitRepositories(in directory: URL) async -> [URL] {
        let fileManager = FileManager.default
        var repositories: [URL] = []

        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey])

            for url in contents {
                if isGitRepository(at: url) {
                    repositories.append(url)
                } else if try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true {
                    let subRepositories = await findGitRepositories(in: url)
                    repositories.append(contentsOf: subRepositories)
                }
            }
        } catch {
            print("Error finding repositories: \(error)")
        }

        return repositories
    }

    func cloneRepository(from url: String, to directory: URL) async -> Bool {
        do {
            cloneStatus = "Cloning repository..."
            cloneProgress = 0.1

            // Extract repository name from URL
            let repoName: String
            if let url = URL(string: url) {
                repoName = url.deletingPathExtension().lastPathComponent
            } else {
                // Fallback: try to extract name from the URL string
                let components = url.components(separatedBy: "/")
                repoName = components.last?.replacingOccurrences(of: ".git", with: "") ?? "repository"
            }

            let destinationPath = directory.appendingPathComponent(repoName).path
            _ = try await Process.output(GitClone(
                directory: directory,
                repositoryURL: url,
                destinationPath: destinationPath
            ))

                cloneProgress = 1.0
                cloneStatus = "Clone completed"
                return true
        } catch {
            cloneStatus = "Clone failed: \(error.localizedDescription)"
            return false
        }
    }

    func stageAllChanges(in url: URL) async throws {
        try await Process.output(GitAdd(directory: url))
    }

    func checkoutCommit(_ hash: String, in directory: URL, discardLocalChanges: Bool = false) async throws {
        try await Process.output(GitCheckout(directory: directory, commitHash: hash, discardLocalChanges: discardLocalChanges))
    }

    func getCommitDetails(_ hash: String, in url: URL) async throws -> CommitDetails {
        let output = try await Process.output(GitShow(directory: url, object: hash))
        return output
    }

    func getLog(in url: URL, limit: Int = 100) async throws -> [Commit] {
        let output = try await Process.output(GitLog(directory: url))
        return output
    }

    func createBranch(_ name: String, in directory: URL) async throws {
        try await Process.output(GitBranchCreate(directory: directory, name: name))
    }

    func checkoutBranch(_ name: String, in url: URL) async throws {
        try await Process.output(GitCheckout(directory: url, commitHash: name))
    }

    func mergeBranch(
        _ name: String,
        in url: URL,
        commitMerged: Bool = true,
        includeMessages: Bool = false,
        createNewCommit: Bool = false,
        rebaseInsteadOfMerge: Bool = false
    ) async throws {
        try await Process.output(GitMerge(
            directory: url,
            branchName: name,
            commitMerged: commitMerged,
            includeMessages: includeMessages,
            createNewCommit: createNewCommit,
            rebaseInsteadOfMerge: rebaseInsteadOfMerge
        ))
    }

    func commit(_ message: String, in url: URL) async throws {
        try await Process.output(GitCommit(directory: url, message: message))
    }

    func stageFile(_ path: String, in url: URL) async throws {
        try await Process.output(GitAddPatch(directory: url, inputs: [path]))
    }

    func unstageFile(_ path: String, in url: URL) async throws {
        _ = try await Process.output(GitReset(directory: url, path: path))
    }

    func resetFile(_ path: String, in url: URL) async throws {
        try await Process.output(GitCheckout(directory: url, commitHash: path))
    }

    func createStash(_ message: String, in url: URL, keepStaged: Bool = false) async throws {
        _ = try await Process.output(GitStash(directory: url, message: message, keepStaged: keepStaged))
    }

    func applyStash(_ index: Int, in url: URL) async throws {
        try await Process.output(GitStashApply(directory: url, index: index))
    }

    func dropStash(_ index: Int, in url: URL) async throws {
        try await Process.output(GitStashDrop(directory: url, index: index))
    }

    func stageChunk(_ chunk: Chunk, in fileDiff: FileDiff, directory: URL) async throws  {
        // Get the file path from the fileDiff
        let filePath = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath

        // Create inputs array with 'y' to stage the chunk when Git prompts
        // We use stageString here which will be 'y' when the chunk should be staged
        var inputs = [chunk.stageString]

        // Add more 'n' responses in case there are multiple chunks in the interactive prompt
        inputs.append(contentsOf: Array(repeating: "n", count: 10))

        // Execute the git add --patch command with the file path
        try await Process.output(GitAddPatch(directory: directory, inputs: inputs, filePath: filePath))
    }

    func unstageChunk(_ chunk: Chunk, in fileDiff: FileDiff, directory: URL) async throws {
        // Get the file path from the fileDiff
        let filePath = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath

        // Create inputs array with 'y' to unstage the chunk when Git prompts
        // We use unstageString here which will be 'y' when the chunk should be unstaged
        var inputs = [chunk.unstageString]

        // Add more 'n' responses in case there are multiple chunks in the interactive prompt
        inputs.append(contentsOf: Array(repeating: "n", count: 10))

        // Execute the git restore --staged --patch command with the file path
        try await Process.output(GitRestorePatch(directory: directory, inputs: inputs, filePath: filePath))
    }

    func resetChunk(_ chunk: Chunk, in fileDiff: FileDiff, directory: URL) async throws {
        // Get the file path from the fileDiff
        let filePath = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath

        // Create inputs array with 'y' to reset the chunk when Git prompts
        var inputs = ["y"]

        // Add more 'n' responses in case there are multiple chunks in the interactive prompt
        inputs.append(contentsOf: Array(repeating: "n", count: 10))

        // Execute the git checkout -p command with the file path
        _ = try await Process.output(GitResetChunk(directory: directory, filePath: filePath, inputs: inputs))
    }

    func unstageAllChanges(in directory: URL) async throws {
        _ = try await Process.output(GitUnstageAll(directory: directory))
    }

    func renameBranch(_ oldName: String, to newName: String, in directory: URL) async throws {
        try await Process.output(GitBranchRename(directory: directory, oldBranchName: oldName, newBranchName: newName))
    }

    // MARK: - Merge Commit Operations

    /// Get the commits that were part of a merge
    /// - Parameters:
    ///   - mergeCommitHash: Hash of the merge commit
    ///   - directory: Repository directory
    /// - Returns: Array of commits that were part of the merge
    func getMergeCommits(_ mergeCommitHash: String, in directory: URL) async throws -> [Commit] {
        // Get the parent hashes from the merge commit
        let details = try await getCommitDetails(mergeCommitHash, in: directory)
        guard details.commit.isMergeCommit, details.commit.parentHashes.count >= 2 else {
            throw GitError.unknownError("Not a merge commit")
        }

        // Get the range of commits between merge parents
        // The first parent is the target branch, second parent is the source branch
        let mainParent = details.commit.parentHashes[0]
        let mergedParent = details.commit.parentHashes[1]

        // Get commits that were part of the merge (commits in second parent that aren't in first parent)
        // Git command equivalent: git log --no-merges firstParent..secondParent
        let gitLog = GitLog(directory: directory)
        gitLog.revisionRange = "\(mainParent)..\(mergedParent)"
        gitLog.noMerges = true

        return try await Process.output(gitLog)
    }

    func abortMerge(in directory: URL) async throws {
        try await Process.output(GitMergeAbort(directory: directory))
    }

    func stage(files: [String], in directory: URL) async throws {
        for file in files {
            try await Process.output(GitAddPathspec(directory: directory, pathspec: file))
        }
    }

    // MARK: - Blame Operations
    func getBlame(in directory: URL, filePath: String) async throws -> [BlameLine] {
        try await Process.output(GitBlame(directory: directory, filePath: filePath))
    }

    // MARK: - Search Operations
    func searchFileContent(in directory: URL, pattern: String) async throws -> [FileSearchResult] {
        try await Process.output(GitGrep(directory: directory, pattern: pattern))
    }

}
