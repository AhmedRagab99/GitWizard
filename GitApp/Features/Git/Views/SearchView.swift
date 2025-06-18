import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: GitViewModel
    @State private var searchQuery: String = ""
    @State private var selectedTab: SearchTab = .commits

    enum SearchTab {
        case commits
        case files
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search header with search field and filters
            searchHeader

            // Tab selection for search results type
            searchTabPicker

            // Search results section
            searchResultsView
        }
        .background(Color(.windowBackgroundColor))
    }

    private var searchHeader: some View {
        VStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search repository", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }

                Button(action: {
                    searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(searchQuery.isEmpty ? 0 : 1)

                Button("Search") {
                    performSearch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchQuery.isEmpty)
            }

            // Search filters
            if selectedTab == .commits {
                Picker("Search in:", selection: $viewModel.searchType) {
                    ForEach(CommitSearchType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private var searchTabPicker: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Commits",
                systemImage: "list.bullet",
                isSelected: selectedTab == .commits,
                action: { selectedTab = .commits }
            )

            TabButton(
                title: "Files",
                systemImage: "doc.text",
                isSelected: selectedTab == .files,
                action: { selectedTab = .files }
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var searchResultsView: some View {
        if viewModel.isSearching {
            loadingView
        } else if !searchQuery.isEmpty {
            switch selectedTab {
            case .commits:
                commitResultsView
            case .files:
                fileResultsView
            }
        } else {
            emptyStateView
        }
    }

    private var loadingView: some View {
        CenteredContentMessage(
            systemImage: "hourglass",
            title: "Searching...",
            message: "Please wait while we search your repository",
            color: .blue
        )
        .padding(.top, 50)
    }

    private var emptyStateView: some View {
        CenteredContentMessage(
            systemImage: "magnifyingglass",
            title: "Search Repository",
            message: "Enter a search term to find commits or file content",
            color: .secondary
        )
        .padding(.top, 50)
    }

    private var commitResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.searchResults.isEmpty {
                    CenteredContentMessage(
                        systemImage: "magnifyingglass.circle",
                        title: "No Results",
                        message: "No matching commits found",
                        color: .orange
                    )
                    .padding(.top, 50)
                } else {
                    Text("\(viewModel.searchResults.count) results found")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding([.horizontal, .top])

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { commit in
                            CommitSearchResultRow(commit: commit)
                                .onTapGesture {
                                    viewModel.selectedCommit = commit
                                }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var fileResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.fileSearchResults.isEmpty {
                    CenteredContentMessage(
                        systemImage: "doc.text.magnifyingglass",
                        title: "No Results",
                        message: "No matching files found",
                        color: .orange
                    )
                    .padding(.top, 50)
                } else {
                    Text("\(viewModel.fileSearchResults.count) results found")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding([.horizontal, .top])

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.fileSearchResults) { result in
                            FileSearchResultRow(result: result)
                                .onTapGesture {
                                    // You might want to open the file or show details
                                }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else { return }

        if selectedTab == .commits {
            viewModel.performSearch(query: searchQuery)
        } else {
            viewModel.searchFileContent(pattern: searchQuery)
        }
    }
}

struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .blue : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct CommitSearchResultRow: View {
    let commit: Commit

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Commit hash
                Text(commit.hash.prefix(7))
                    .font(.system(.caption, design: .monospaced))
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    // Commit message
                    Text(commit.message)
                        .font(.headline)
                        .lineLimit(1)

                    // Author and date
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.secondary)
                            .imageScale(.small)

                        Text(commit.author)
                            .font(.caption)

                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .imageScale(.small)
                            .padding(.leading, 8)

                        Text(dateFormatter.string(from: commit.date))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct FileSearchResultRow: View {
    let result: FileSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // File path and line number
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)

                Text(result.filePath)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)

                Spacer()

                // Line number badge
                Text("Line \(result.lineNumber)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                    .foregroundColor(.secondary)
            }

            // Match content
            Text(result.matchContent)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}



#Preview {
    SearchView(viewModel: GitViewModel(url: URL(fileURLWithPath: "")))
        .frame(width: 700, height: 500)
}
