import SwiftUI

struct FetchSheet: View {
    @Binding var isPresented: Bool

    var remotes: [String]
    var currentRemote: String
    var onFetch: (_ remote: String, _ fetchAllRemotes: Bool, _ prune: Bool, _ fetchTags: Bool) -> Void

    @State private var selectedRemote: String
    @State private var fetchAllRemotes: Bool = true
    @State private var prune: Bool = true
    @State private var fetchTags: Bool = true
    @State private var isFetching: Bool = false

    init(
        isPresented: Binding<Bool>,
        remotes: [String],
        currentRemote: String = "origin",
        onFetch: @escaping (_ remote: String, _ fetchAllRemotes: Bool, _ prune: Bool, _ fetchTags: Bool) -> Void
    ) {
        self._isPresented = isPresented
        self.remotes = remotes
        self.currentRemote = currentRemote
        self.onFetch = onFetch
        _selectedRemote = State(initialValue: currentRemote)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SheetHeader(
                title: "Fetch from Remote",
                subtitle: "Download objects and refs from remote repositories",
                icon: "arrow.down.circle",
                iconColor: .blue
            )

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    if !fetchAllRemotes {
                        FormSection(title: "Remote Repository") {
                            Picker("Remote", selection: $selectedRemote) {
                                ForEach(remotes, id: \.self) { remote in
                                    Text(remote).tag(remote)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    FormSection(title: "Fetch Options", showDivider: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Fetch from all remotes", isOn: $fetchAllRemotes)

                            Toggle("Prune tracking branches no longer present on remote(s)", isOn: $prune)

                            Toggle("Fetch and store all tags locally", isOn: $fetchTags)
                        }
                    }
                }
            }

            SheetFooter(
                cancelAction: { isPresented = false },
                confirmAction: {
                    isFetching = true
                    onFetch(
                        selectedRemote,
                        fetchAllRemotes,
                        prune,
                        fetchTags
                    )
                    isFetching = false
                    isPresented = false
                },
                confirmText: "Fetch",
                isLoading: isFetching
            )
        }
        .padding(24)
        .frame(width: 450)
        .background(Color(.windowBackgroundColor))
    }
}
