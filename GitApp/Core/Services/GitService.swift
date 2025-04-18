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

    func runGitCommand(_ arguments:  String..., in directory: URL? = nil) async throws -> (output: String, error: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""

        return (output: output, error: error)
    }

    func isGitRepository(at url: URL) async -> Bool {
        do {
            _ = try await runGitCommand("rev-parse", "--git-dir", in: url)
            return true
        } catch {
            return false
        }
    }

    func getBranches(in directory: URL) async -> [Branch] {
        do {
            let result = try await runGitCommand("branch", "-v", "--format=%(refname:short)|%(objectname)|%(contents:subject)|%(committerdate:iso8601)", in: directory)

            return result.output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .map { line -> Branch in
                    let components = line.components(separatedBy: "|")
                    let name = components[0]
                    let hash = components[1]
                    let message = components[2]
                    let date = ISO8601DateFormatter().date(from: components[3]) ?? Date()

                    return Branch(
                        id: UUID(),
                        name: name,
                        isCurrent: name.hasPrefix("*"),
                        isRemote: name.contains("/"),
                        lastCommit: hash,
                        lastCommitMessage: message,
                        lastCommitDate: date
                    )
                }
        } catch {
            return []
        }
    }

    func getTags(in directory: URL) async -> [Tag] {
        do {
            let result = try await runGitCommand("tag", "-l", "--format=%(refname:short)|%(objectname)|%(contents:subject)|%(creatordate:iso8601)", in: directory)

            return result.output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .map { line -> Tag in
                    let components = line.components(separatedBy: "|")
                    let name = components[0]
                    let hash = components[1]
                    let message = components[2]
                    let date = ISO8601DateFormatter().date(from: components[3]) ?? Date()

                    return Tag(
                        id: UUID(),
                        name: name,
                        commitHash: hash,
                        message: message,
                        date: date
                    )
                }
        } catch {
            return []
        }
    }

    func getCommits(for branch: String, in directory: URL) async throws -> [Commit] {
        let result = try await runGitCommand("log", "--format=%H|%an|%ae|%ad|%s|%P", "--date=format:%Y-%m-%d %H:%M:%S %z", branch, in: directory)

        if result.error.isEmpty {
            return parseCommits(from: result.output)
        } else {
            throw GitError.commandFailed(result.error)
        }
    }

    private func parseCommits(from output: String) -> [Commit] {
        output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { line in
                let components = line.components(separatedBy: "|")
                guard components.count >= 6 else { return nil }

                let hash = components[0].trimmingCharacters(in: .whitespaces)
                let authorName = components[1].trimmingCharacters(in: .whitespaces)
                let authorEmail = components[2].trimmingCharacters(in: .whitespaces)
                let dateString = components[3].trimmingCharacters(in: .whitespaces)
                let message = components[4].trimmingCharacters(in: .whitespaces)
                let parentHashes = components[5].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                // Determine commit type based on message and parent hashes
                let commitType = determineCommitType(message: message, parentHashes: parentHashes)

                // Generate avatar URL based on email (using Gravatar)
                let emailHash = authorEmail.lowercased().md5Hash
                let authorAvatar = "https://www.gravatar.com/avatar/\(emailHash)?d=identicon&s=40"

                // Parse date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                let date = dateFormatter.date(from: dateString) ?? Date()

                return Commit(
                    id: UUID(),
                    hash: hash,
                    authorName: authorName,
                    authorEmail: authorEmail,
                    date: date,
                    message: message,
                    parentHashes: parentHashes,
                    branchNames: [],
                    commitType: commitType,
                    authorAvatar: authorAvatar
                )
            }
            .compactMap { $0 }
    }

    private func determineCommitType(message: String, parentHashes: [String]) -> Commit.CommitType {
        let lowercasedMessage = message.lowercased()

        if parentHashes.count > 1 {
            return .merge
        } else if lowercasedMessage.contains("rebase") {
            return .rebase
        } else if lowercasedMessage.contains("cherry-pick") {
            return .cherryPick
        } else if lowercasedMessage.contains("revert") {
            return .revert
        } else {
            return .normal
        }
    }

    func getCommitDetails(for commitHash: String, in directory: URL) async -> GitViewModel.CommitDetails? {
        do {
            let result = try await runGitCommand("show", "--name-status", "--format=%H|%an|%ae|%ad|%s|%P", commitHash, in: directory)
            let lines = result.output.components(separatedBy: .newlines)

            guard let firstLine = lines.first else { return nil }
            let components = firstLine.components(separatedBy: "|")

            let hash = components[0]
            let authorName = components[1]
            let authorEmail = components[2]
            let date = ISO8601DateFormatter().date(from: components[3]) ?? Date()
            let message = components[4]
            let parentHashes = components[5].components(separatedBy: " ")

            let changedFiles = lines.dropFirst()
                .filter { !$0.isEmpty }
                .map { line -> FileChange in
                    let components = line.components(separatedBy: .whitespaces)
                    let status = components[0]
                    let path = components[1...].joined(separator: " ")

                    return FileChange(
                        id: UUID(),
                        name: (path as NSString).lastPathComponent,
                        status: status,
                        path: path,
                        stagedChanges: [],
                        unstagedChanges: []
                    )
                }

            let diffResult = try await runGitCommand("show", commitHash, in: directory)

            return GitViewModel.CommitDetails(
                hash: hash,
                authorName: authorName,
                authorEmail: authorEmail,
                date: date,
                message: message,
                changedFiles: changedFiles,
                diffContent: diffResult.output,
                parentHashes: parentHashes,
                branchNames: []
            )
        } catch {
            return nil
        }
    }

    func getCurrentBranch(in directory: URL) async -> String? {
        do {
            let result = try await runGitCommand("rev-parse", "--abbrev-ref", "HEAD", in: directory)
            return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    func getRemotes(in directory: URL) async -> [(name: String, url: String)] {
        do {
            let result = try await runGitCommand("remote", "-v", in: directory)
            return result.output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .compactMap { line -> (name: String, url: String)? in
                    let components = line.components(separatedBy: .whitespaces)
                    guard components.count >= 2 else { return nil }
                    return (name: components[0], url: components[1])
                }
        } catch {
            return []
        }
    }

    func getStashes(in directory: URL) async -> [Stash] {
        do {
            let result = try await runGitCommand("stash", "list", in: directory)
            return result.output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .map { line -> Stash in
                    return Stash(
                        description: line,
                        date: Date()
                    )
                }
        } catch {
            return []
        }
    }

    func getDiff(for commitHash: String, file: String, in directory: URL) async -> String? {
        do {
            let result = try await runGitCommand("show", "--format=", "--patch", "\(commitHash):\(file)", in: directory)
            return result.output
        } catch {
            return nil
        }
    }

    func findGitRepositories(in directory: URL) async -> [URL] {
        var repositories: [URL] = []

        if await isGitRepository(at: directory) {
            repositories.append(directory)
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey])
            for url in contents {
                // Check if directory is readable
                guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .isReadableKey]),
                      resourceValues.isDirectory == true,
                      resourceValues.isReadable == true else { continue }

                // Skip hidden directories and .git
                if url.lastPathComponent.hasPrefix(".") { continue }

                // Check if this is a Git repository
                if await isGitRepository(at: url) {
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
            print("Error scanning directory: \(error)")
        }

        return repositories
    }

    func cloneRepository(from url: String, to directory: URL) async -> Bool {
        do {
            cloneStatus = "Cloning repository..."
            cloneProgress = 0.1

            let result = try await runGitCommand("clone", url, in: directory)

            if result.error.isEmpty {
                cloneProgress = 1.0
                cloneStatus = "Clone completed"
                return true
            } else {
                cloneStatus = "Clone failed: \(result.error)"
                return false
            }
        } catch {
            cloneStatus = "Clone failed: \(error.localizedDescription)"
            return false
        }
    }
}
