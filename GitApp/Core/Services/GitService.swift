import Foundation

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

    func runGitCommand(_ args: String..., in directory: URL) async -> (output: String, error: String)? {
        guard isGitInstalled() else {
            print("Git is not installed. Please install Git first.")
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = directory

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()

            // Start reading output in background
            let outputTask = Task {
                let data = try outputPipe.fileHandleForReading.readToEnd() ?? Data()
                return String(data: data, encoding: .utf8) ?? ""
            }

            let errorTask = Task {
                let data = try errorPipe.fileHandleForReading.readToEnd() ?? Data()
                return String(data: data, encoding: .utf8) ?? ""
            }

            process.waitUntilExit()

            let output = try await outputTask.value
            let error = try await errorTask.value

            if process.terminationStatus != 0 {
                print("Git command failed with status \(process.terminationStatus): \(error)")
                return nil
            }

            return (output, error)
        } catch {
            print("Error running git command: \(error)")
            return nil
        }
    }

    private func isGitInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["git"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    func getBranches(in directory: URL) async -> [Branch] {
        guard let result = await runGitCommand("branch", "-a", in: directory) else { return [] }

        return result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { branchName -> Branch in
                let isCurrent = branchName.hasPrefix("* ")
                let name = isCurrent ? String(branchName.dropFirst(2)) : branchName
                return Branch(name: name, isCurrent: isCurrent)
            }
    }

    func getTags(in directory: URL) async -> [Tag] {
        guard let result = await runGitCommand("tag", "-l", in: directory) else { return [] }

        return result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { Tag(name: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    func getCommits(for branch: String, in directory: URL) async -> [Commit] {
        // Format: %H|%an|%ae|%ad|%s|%P
        guard let result = await runGitCommand("log", branch, "--pretty=format:%H|%an|%ae|%ad|%s|%P", "--date=iso", in: directory) else { return [] }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        // First, collect all commit hashes and basic info
        let commitInfos = result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> (hash: String, author: String, email: String, date: Date, message: String, parents: [String])? in
                let components = line.components(separatedBy: "|")
                guard components.count >= 6 else { return nil }

                let hash = components[0]
                let author = components[1]
                let email = components[2]
                let date = dateFormatter.date(from: components[3]) ?? Date()
                let message = components[4]
                let parents = components[5].components(separatedBy: " ").filter { !$0.isEmpty }

                return (hash, author, email, date, message, parents)
            }

        // Then, fetch additional details for each commit
        var commits: [Commit] = []
        for info in commitInfos {
            let changedFiles = await getChangedFiles(for: info.hash, in: directory)
            let branchNames = await getBranchNames(for: info.hash, in: directory)

            let commit = Commit(
                hash: info.hash,
                message: info.message,
                author: info.author,
                authorEmail: info.email,
                authorAvatar: "person.crop.circle.fill",
                date: info.date,
                changedFiles: changedFiles,
                parentHashes: info.parents,
                branchNames: branchNames,
                commitType: info.parents.count > 1 ? .merge : .normal
            )
            commits.append(commit)
        }

        return commits
    }

    func getChangedFiles(for commitHash: String, in directory: URL) async -> [FileChange] {
        guard let result = await runGitCommand("show", "--name-status", "--pretty=format:", commitHash, in: directory) else { return [] }

        return result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> FileChange? in
                let components = line.components(separatedBy: "\t")
                guard components.count == 2 else { return nil }

                let status = components[0]
                let name = components[1]

                let fileStatus: String
                switch status {
                case "A": fileStatus = "Added"
                case "M": fileStatus = "Modified"
                case "D": fileStatus = "Deleted"
                case "R": fileStatus = "Renamed"
                default: fileStatus = "Unknown"
                }

                return FileChange(name: name, status: fileStatus)
            }
    }

    func getBranchNames(for commitHash: String, in directory: URL) async -> [String] {
        guard let result = await runGitCommand("branch", "-a", "--contains", commitHash, in: directory) else { return [] }

        return result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.replacingOccurrences(of: "* ", with: "") }
    }

    func getDiff(for commitHash: String, file: String, in directory: URL) async -> String? {
        return await runGitCommand("show", commitHash, "--", file, in: directory)?.output
    }

    func getCurrentBranch(in directory: URL) async -> String? {
        guard let result = await runGitCommand("rev-parse", "--abbrev-ref", "HEAD", in: directory) else { return nil }
        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getRemotes(in directory: URL) async -> [(name: String, url: String)] {
        guard let result = await runGitCommand("remote", "-v", in: directory) else { return [] }

        return result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { $0.components(separatedBy: "\t") }
            .compactMap { components -> (name: String, url: String)? in
                guard components.count >= 2 else { return nil }
                return (components[0], components[1].components(separatedBy: " ")[0])
            }
    }

    func getCommitDetails(for hash: String, in directory: URL) async -> GitViewModel.CommitDetails {
        // Get full commit details
        let commitResult = await runGitCommand("show", "--name-status", "--pretty=format:%H|%an|%ae|%ad|%s|%P", hash, in: directory)
        let diffResult = await runGitCommand("show", hash, in: directory)

        let components = commitResult?.output.components(separatedBy: "\n").first?.components(separatedBy: "|") ?? []

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        let changedFiles = commitResult?.output
            .components(separatedBy: "\n")
            .dropFirst()
            .filter { !$0.isEmpty }
            .compactMap { line -> FileChange? in
                let parts = line.components(separatedBy: "\t")
                guard parts.count == 2 else { return nil }
                return FileChange(name: parts[1], status: parts[0])
            } ?? []

        return GitViewModel.CommitDetails(
            hash: components[0],
            author: components[1],
            authorEmail: components[2],
            date: dateFormatter.date(from: components[3]) ?? Date(),
            message: components[4],
            changedFiles: changedFiles,
            diffContent: diffResult?.output,
            parentHashes: components[5].components(separatedBy: " ").filter { !$0.isEmpty },
            branchNames: await getBranchNames(for: hash, in: directory)
        )
    }

    func getStashes(in directory: URL) async -> [Stash] {
        guard let result = await runGitCommand("stash", "list", in: directory) else { return [] }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        return result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> Stash? in
                // Format: stash@{0}: WIP on branch: message
                let components = line.components(separatedBy: ": ")
                guard components.count >= 2 else { return nil }

                let description = components[1]
                return Stash(
                    description: description,
                    date: Date() // Git doesn't provide stash dates in the list command
                )
            }
    }

    func findGitRepositories(in directory: URL) async -> [URL] {
        var repositories: [URL] = []

        // Check if the current directory is a Git repository
        if isGitRepository(at: directory) {
            repositories.append(directory)
            return repositories
        }

        // Search subdirectories
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey, .isReadableKey])
            for url in contents {
                // Check if directory is readable
                guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .isReadableKey]),
                      resourceValues.isDirectory == true,
                      resourceValues.isReadable == true else { continue }

                // Skip hidden directories and .git
                if url.lastPathComponent.hasPrefix(".") { continue }

                // Check if this is a Git repository
                if isGitRepository(at: url) {
                    repositories.append(url)
                } else {
                    // Recursively search subdirectories
                    do {
                        repositories.append(contentsOf: await findGitRepositories(in: url))
                    } catch {
                        // Skip directories we can't access
                        print("Skipping directory due to access error: \(url.path)")
                        continue
                    }
                }
            }
        } catch {
            print("Error searching directories: \(error)")
        }

        return repositories
    }

    func cloneRepository(from url: String, to directory: URL) async -> Bool {
        guard !url.isEmpty else {
            await updateProgress(0.0, status: "Please enter a repository URL")
            return false
        }

        guard isGitInstalled() else {
            await updateProgress(0.0, status: "Git is not installed. Please install Git first.")
            return false
        }

        await updateProgress(0.0, status: "Starting clone...")

        // Check write access
        do {
            let testFile = directory.appendingPathComponent(".git-clone-test")
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
        } catch {
            await updateProgress(0.0, status: "Cannot write to selected directory")
            return false
        }

        // Run clone command
        if let result = await runGitCommand("clone", "--progress", url, in: directory) {
            if result.error.isEmpty {
                let repoName = url.components(separatedBy: "/").last?.replacingOccurrences(of: ".git", with: "") ?? "repository"
                let repoPath = directory.appendingPathComponent(repoName)

                if isGitRepository(at: repoPath) {
                    await updateProgress(1.0, status: "Clone completed successfully")
                    return true
                } else {
                    await updateProgress(0.0, status: "Failed to verify cloned repository")
                    return false
                }
            } else {
                // Parse progress from error output
                if result.error.contains("Cloning into") {
                    await updateProgress(0.1, status: result.error)
                } else if result.error.contains("remote:") {
                    await updateProgress(0.3, status: result.error)
                } else if result.error.contains("Receiving objects:") {
                    let progress = parseProgress(from: result.error)
                    await updateProgress(0.3 + (progress * 0.6), status: result.error)
                } else if result.error.contains("Resolving deltas:") {
                    let progress = parseProgress(from: result.error)
                    await updateProgress(0.9 + (progress * 0.1), status: result.error)
                } else {
                    await updateProgress(0.0, status: "Clone failed: \(result.error)")
                    return false
                }
            }
        }

        return false
    }

    private func parseProgress(from output: String) -> Double {
        // Extract percentage from output like "Receiving objects:  45% (123/456)"
        if let range = output.range(of: "\\d+%", options: .regularExpression) {
            let percentageStr = output[range].replacingOccurrences(of: "%", with: "")
            return Double(percentageStr) ?? 0.0 / 100.0
        }
        return 0.0
    }
}
