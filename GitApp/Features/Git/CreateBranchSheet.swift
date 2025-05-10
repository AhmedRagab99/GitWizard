// MARK: - Create Branch Sheet
struct CreateBranchSheet: View {
    @Binding var isPresented: Bool
    var currentBranch: String
    var onCreate: (_ branchName: String, _ commitSource: CommitSource, _ specifiedCommit: String?, _ checkout: Bool) -> Void

    @State private var branchName: String = ""
    @State private var commitSource: CommitSource = .workingCopyParent
    @State private var specifiedCommit: String = ""
    @State private var showCommitPicker: Bool = false
    @State private var checkoutNewBranch: Bool = true

    enum CommitSource: String, CaseIterable, Identifiable {
        case workingCopyParent = "Working copy parent"
        case specifiedCommit = "Specified commit"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("New Branch")
                    .font(.title2.bold())
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Current branch")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(currentBranch)
                    .font(.body)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.secondaryLabelColor)))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("New Branch:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Branch name", text: $branchName)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Commit:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Commit Source", selection: $commitSource) {
                    ForEach(CommitSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.radioGroup)
                if commitSource == .specifiedCommit {
                    HStack {
                        TextField("Commit hash", text: $specifiedCommit)
                            .textFieldStyle(.roundedBorder)
                        Button("Pick…") {
                            // TODO: Show commit picker
                        }
                        .disabled(true)
                    }
                }
            }

            Toggle(isOn: $checkoutNewBranch) {
                Text("Checkout new branch")
            }
            .toggleStyle(.switch)
            .padding(.top, 8)

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Create Branch") {
                    onCreate(branchName.trimmingCharacters(in: .whitespacesAndNewlines), commitSource, specifiedCommit.isEmpty ? nil : specifiedCommit, checkoutNewBranch)
                    isPresented = false
                }
                .disabled(branchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(minWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .shadow(radius: 20)
    }
}
