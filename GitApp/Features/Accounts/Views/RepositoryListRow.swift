//
//  RepositoryListRow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//
import SwiftUI

struct RepositoryListRow: View {
    let repository: GitHubRepository
    var isSelected: Bool
    var showOwner: Bool = true
    var ownerLogin: String? = nil
    var repoViewModel : RepositoryViewModel
    @State private var showingCloneErrorAlert = false
    @State private var cloneErrorMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: repository.isPrivate ? "lock.fill" : "folder.fill")
                .font(.title3)
                .foregroundColor(repository.isPrivate ? .orange : .accentColor)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(repository.name)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .accentColor : .primary)

                if showOwner {
                    Text(ownerLogin ?? repository.owner?.login ?? "Unknown Owner") // Safe unwrap
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let description = repository.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    if let stars = repository.stargazersCount, stars > 0 {
                        Label("\(stars)", systemImage: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                    if let forks = repository.forksCount, forks > 0 {
                        Label("\(forks)", systemImage: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundColor(.green.opacity(0.8))
                    }
                    if let lang = repository.language, !lang.isEmpty {
                        Label(lang, systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(languageColor(lang).opacity(0.8)) // Using the helper
                    }
                }
                .padding(.top, 2)
            }
            Spacer()

            // Buttons
            HStack(spacing: 8) {
                Button {
                    // Action to open in browser
                    if let url = URL(string: repository.htmlUrl) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "safari")
                }
                .buttonStyle(.borderless)
                .help("Open in browser")

                Button {
                    // Action to clone
                    guard let cloneUrl = repository.cloneUrl else {
                        cloneErrorMessage = "Clone URL is not available for this repository."
                        showingCloneErrorAlert = true
                        return
                    }
                    // Present a panel to choose the directory
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = false
                    panel.prompt = "Choose Clone Destination"
                    panel.message = "Select a folder to clone '\(repository.name)' into."

                    if panel.runModal() == .OK {
                        if let destinationDirectory = panel.url {
                            Task {
                                do {
                                    let success = try await repoViewModel.cloneRepository(from: cloneUrl, to: destinationDirectory)
                                    if !success {
                                        cloneErrorMessage = repoViewModel.errorMessage ?? "Failed to clone repository."
                                        showingCloneErrorAlert = true
                                    }
                                } catch {
                                    cloneErrorMessage = "Error during cloning: \(error.localizedDescription)"
                                    showingCloneErrorAlert = true
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)
                .help("Clone repository")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .alert("Clone Error", isPresented: $showingCloneErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cloneErrorMessage)
        }
    }

    // Basic language to color mapping (can be expanded or moved to a global helper)
    private func languageColor(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "html": return .pink
        case "css": return .purple
        case "c#", "csharp": return .green
        case "c++", "cpp": return .pink
        case "ruby": return .red
        case "go": return .cyan
        case "typescript": return .blue
        case "php": return .purple
        case "scala": return .red
        case "kotlin": return Color(red: 0.6, green: 0.3, blue: 0.8) // A violet-ish color
        case "rust": return Color(red: 0.7, green: 0.3, blue: 0.1)
        default: return .gray
        }
    }
}
