//
//  RepositoryViewModel.swift
//  GitApp
//
//  Created by Ahmed Ragab on 08/05/2025.
//

import SwiftUI
import Combine // Assuming GitService might use Combine or is in a module that exports it. Or create if not exists.

@Observable
class RepositoryViewModel {
    // Repository Management Properties
    var repositoryURL: URL?
    var foundRepositories: [URL] = []
    var isSearchingRepositories = false
    var permissionError: String?
    var isCloning = false
    var cloneProgress: Double = 0.0
    var cloneStatus: String = ""
    var cloneURL: String = ""
    var cloneDirectory: URL?
    var isShowingCloneSheet = false
    var isShowingImportSheet = false
    var isAddingLocalRepo = false
    var isShowingAddLocalSheet = false
    var localRepoPath: URL?
    var localRepoName: String = ""
    var importProgress: ImportProgress?
    var isImporting = false
    var importStatus: String = ""
    var selectedRepository: URL?
    var recentRepositories: [URL] = []
    var errorMessage: String?

    private let gitService = GitService()

    struct ImportProgress: Identifiable {
        let id = UUID()
        var current: Int
        var total: Int
        var status: String
    }

    init() {
        loadRepositoryList()
    }

    func isGitRepository(at: URL) async -> Bool {
        return  await gitService.isGitRepository(at: at)
    }




    func cloneRepository(from url: String, to directory: URL) async throws -> Bool {
        guard !url.isEmpty else {
            errorMessage = "Please enter a repository URL"
            return false
        }

        isCloning = true
        cloneProgress = 0.0
        cloneStatus = "Starting clone..."

        defer {
            isCloning = false
            cloneProgress = 0.0
            cloneStatus = ""
        }

        do {
            let success =  await gitService.cloneRepository(from: url, to: directory)

            if success {
                let repoName = url.components(separatedBy: "/").last?.replacingOccurrences(of: ".git", with: "") ?? "repository"
                let repoPath = directory.appendingPathComponent(repoName)

                addClonedRepository(repoPath)
                repositoryURL = repoPath
                selectedRepository = repoPath

                if !recentRepositories.contains(repoPath) {
                    recentRepositories.insert(repoPath, at: 0)
                    if recentRepositories.count > 10 {
                        recentRepositories.removeLast()
                    }
                    saveRepositoryList()
                }

                cloneProgress = 1.0
                cloneStatus = "Clone completed successfully"
                return true
            }
            return false
        }
    }

    func selectRepository(_ url: URL) {
        selectedRepository = url
        repositoryURL = url
    }

    func removeFromRecentRepositories(_ url: URL) {
        recentRepositories.removeAll { $0 == url }
        saveRepositoryList()
    }

    private func saveRepositoryList() {
        let encoder = JSONEncoder()
        do {
            let clonedData = try encoder.encode(recentRepositories.map { $0.path })

            UserDefaults.standard.set(clonedData, forKey: "clonedRepositories")
        } catch {
            print("Failed to save repository list: \(error)")
        }
    }

     func loadRepositoryList() {
        let decoder = JSONDecoder()
        if let clonedData = UserDefaults.standard.data(forKey: "clonedRepositories")
           {
            do {
                let clonedPaths = try decoder.decode([String].self, from: clonedData)
                recentRepositories = clonedPaths.map { URL(fileURLWithPath: $0) }
            } catch {
                print("Failed to load repository list: \(error)")
            }
        }
    }

    func addClonedRepository(_ url: URL) {
        if !recentRepositories.contains(url) {
            recentRepositories.append(url)
            saveRepositoryList()
        }
    }

    func addImportedRepository(_ url: URL) {
        if !recentRepositories.contains(url) {
            recentRepositories.append(url)

            saveRepositoryList()
        }
    }

}
