//
//  AccountDetailView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//

import SwiftUI

struct AccountDetailView: View {
    let account: Account
    var accountManager: AccountManager
    var repoViewModel : RepositoryViewModel
    @Binding var repositories: [GitHubRepository]
    @Binding var isLoadingRepos: Bool
    @Binding var repoFetchError: String? 
    var onUpdateToken: (Account) -> Void

    @State private var userDetails: GitHubUser? = nil
    @State private var isLoadingUserDetails: Bool = false

    // New state for organizations
    @State private var organizations: [GitHubOrganization] = []
    @State private var isLoadingOrganizations: Bool = false
    @State private var organizationFetchError: String? = nil

    // New state for repositories of a selected organization
    @State private var selectedOrganization: GitHubOrganization? = nil
    @State private var organizationRepositories: [GitHubRepository] = []
    @State private var isLoadingOrgRepos: Bool = false
    @State private var orgRepoFetchError: String? = nil

    @State private var currentDetailTab: DetailTab = .accountDetails
    @State private var selectedRepository: GitHubRepository? = nil // To hold the selected repo

    enum DetailTab {
        case accountDetails, repositories
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                if let avatarURLString = userDetails?.avatarUrl ?? account.avatarURL, let avatarURL = URL(string: avatarURLString) {
                    AsyncImage(url: avatarURL) {
                        image in image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .padding(.top, 4)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .padding(.top, 4)
                }

                VStack(alignment: .leading) {
                    Text(userDetails?.name ?? account.username).font(.title).fontWeight(.bold)
                    Text("@\(account.username)").font(.title3).foregroundColor(.secondary)
                    if let profileURL = account.webURL {
                        Link("View on GitHub", destination: profileURL)
                    }
                }
                Spacer()
            }
            .padding(.bottom)

            Picker("Detail View", selection: $currentDetailTab) {
                Text("Account").tag(DetailTab.accountDetails)
                Text("Repositories").tag(DetailTab.repositories)
            }
            .pickerStyle(.segmented)
            .padding(.bottom)

            if currentDetailTab == .accountDetails {
                accountDetailsTab
            } else {
                repositoriesAndOrgsTab // Renamed from repositoriesTab
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.textBackgroundColor)) // Use a suitable background
        .onFirstAppear {
            fetchInitialData()
        }
        .onChange(of: account) { _, newAccount in
             fetchInitialData(for: newAccount)
        }
    }

    private func fetchInitialData(for acc: Account? = nil) {
        let targetAccount = acc ?? account
        fetchUserDetails(for: targetAccount)
        // Repositories for the user are typically fetched by the parent view (AccountsListView)
        // and passed via binding. If not, uncomment and adapt:
        // fetchUserRepositories(for: targetAccount)
        fetchOrganizations(for: targetAccount)
    }

    private func fetchUserDetails(for accountToFetch: Account) {
        isLoadingUserDetails = true
        Task {
            do {
                self.userDetails = try await accountManager.fetchUserDetails(for: accountToFetch)
            } catch {
                // Handle error appropriately
                print("Error fetching user details: \(error)")
            }
            isLoadingUserDetails = false
        }
    }

    private func fetchOrganizations(for accountToFetch: Account) {
        isLoadingOrganizations = true
        organizationFetchError = nil
        Task {
            do {
                self.organizations = try await accountManager.fetchOrganizations(for: accountToFetch)
            } catch {
                self.organizationFetchError = error.localizedDescription
            }
            isLoadingOrganizations = false
        }
    }

    private func fetchUserRepositories(for accountToFetch: Account) {
        // This is already handled by the parent view, passed via @Binding repositories
        // If you want this view to also trigger it, you can call the parent's fetch function
        // or duplicate the logic here, ensuring isLoadingRepos and repoFetchError are updated.
        // For now, we rely on the parent binding.
    }

    private func fetchRepos(for org: GitHubOrganization, accountToFetch: Account) {
        selectedOrganization = org
        isLoadingOrgRepos = true
        orgRepoFetchError = nil
        organizationRepositories = [] // Clear previous org's repos
        Task {
            do {
                let fetchedRepos = try await accountManager.fetchRepositories(for: accountToFetch, organizationLogin: org.login)
                self.organizationRepositories = fetchedRepos
            } catch {
                self.orgRepoFetchError = error.localizedDescription
            }
            isLoadingOrgRepos = false
        }
    }

    @ViewBuilder
    var accountDetailsTab: some View {
        Form {
            Section(header: Text("Account Information")) {
                LabeledContent("Username", value: account.username)
                LabeledContent("Type", value: account.type.rawValue)
                if account.type == .githubEnterprise, let serverURL = account.serverURL {
                    LabeledContent("Server", value: serverURL)
                }
                if let email = userDetails?.email {
                    LabeledContent("Email", value: email)
                }
                if let company = userDetails?.company {
                    LabeledContent("Company", value: company)
                }
                if let location = userDetails?.location {
                    LabeledContent("Location", value: location)
                }
                LabeledContent("Status") {
                    Text("Online").foregroundColor(.green) // Placeholder
                }
            }

            Section {
                Button("Update Token...") {
                    onUpdateToken(account)
                }
            }
        }
        .formStyle(.grouped)
        .overlay {
            if isLoadingUserDetails {
                VStack {
                    ProgressView("Loading Account Details...")
                    Spacer()
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    var repositoriesAndOrgsTab: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Section("Your Repositories") {
                    if isLoadingRepos {
                        ProgressView().padding()
                    } else if let error = repoFetchError {
                        Text("Error: \(error)").foregroundColor(.red).padding()
                    } else if repositories.isEmpty {
                        Text("No repositories found.").padding()
                    } else {
                        ForEach(repositories) { repo in
                            RepositoryListRow(repository: repo,
                                              isSelected: selectedRepository?.id == repo.id,
                                              showOwner: false,
                                              repoViewModel: repoViewModel)
                            .contentShape(Rectangle()) // Make the whole row tappable
                            .onTapGesture {
                                selectedRepository = repo
                                // Potentially scroll to a detail view or update a detail section
                            }
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)

                Section("Organizations") {
                    if isLoadingOrganizations {
                        ProgressView().padding()
                    } else if let error = organizationFetchError {
                        Text("Error: \(error)").foregroundColor(.red).padding()
                    } else if organizations.isEmpty {
                        Text("No organizations found or you are not a member of any.").padding()
                    } else {
                        ForEach(organizations) { org in
                            DisclosureGroup(
                                isExpanded: .init( // Two-way binding for expansion state
                                    get: { selectedOrganization?.id == org.id },
                                    set: { isExpanding in
                                        if isExpanding {
                                            fetchRepos(for: org, accountToFetch: account)
                                        } else {
                                            if selectedOrganization?.id == org.id {
                                                selectedOrganization = nil
                                                organizationRepositories = []
                                            }
                                        }
                                    }
                                ),
                                content: { organizationRepositoriesList(for: org) }, // Extracted content
                                label: {
                                    OrganizationRow(organization: org)
                                }
                            )
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(minHeight: 300)
    }

    @ViewBuilder
    private func organizationRepositoriesList(for org: GitHubOrganization) -> some View {
        if selectedOrganization?.id == org.id {
            if isLoadingOrgRepos {
                ProgressView().padding([.leading, .top])
            } else if let error = orgRepoFetchError {
                Text("Error: \(error)").foregroundColor(.red).padding([.leading, .top])
            } else if organizationRepositories.isEmpty {
                Text("No repositories found for \(org.login).")
                    .foregroundColor(.secondary)
                    .padding([.leading, .top])
            } else {
                ForEach(organizationRepositories) { repo in
                    RepositoryListRow(repository: repo,
                                      isSelected: selectedRepository?.id == repo.id,
                                      showOwner: true,
                                      ownerLogin: org.login,
                                      repoViewModel: repoViewModel) // Ensure repoViewModel is passed here
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRepository = repo
                    }
                    .padding(.leading) // Indent org repos
                    Divider().padding(.leading)
                }
            }
        }
    }
}
