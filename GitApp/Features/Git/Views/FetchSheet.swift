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
        NavigationStack {
            VStack(spacing: 20) {
                // Fetch options
                Form {
                    Section(header: Text("Fetch Options")) {
                        if !fetchAllRemotes {
                            Picker("Remote", selection: $selectedRemote) {
                                ForEach(remotes, id: \.self) { remote in
                                    Text(remote).tag(remote)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Toggle("Fetch from all remotes", isOn: $fetchAllRemotes)
                            .tint(.blue)

                        Toggle("Prune tracking branches no longer present on remote(s)", isOn: $prune)
                            .tint(.blue)

                        Toggle("Fetch and store all tags locally", isOn: $fetchTags)
                            .tint(.blue)
                    }
                }

                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        isFetching = true
                        onFetch(
                            selectedRemote,
                            fetchAllRemotes,
                            prune,
                            fetchTags
                        )
                        isFetching = false
                        isPresented = false
                    } label: {
                        if isFetching {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("OK")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isFetching)
                }
                .padding()
            }
            .padding()
            .frame(maxWidth: 500)
        }
    }
}
