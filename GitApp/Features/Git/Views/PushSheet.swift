//
//  PushSheet.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//
import SwiftUI

struct PushSheet: View {
    @Binding var isPresented: Bool
    var branches: [Branch]
    var currentBranch: Branch?
    var onPush: (_ branches: [Branch], _ pushTags: Bool) -> Void

    @State private var selectedBranches: Set<String> = []
    @State private var pushAllTags: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SheetHeader(
                title: "Push to Repository",
                subtitle: "Send local commits to the remote repository",
                icon: "arrow.up.circle.fill",
                iconColor: .green
            )

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    FormSection(title: "Target Repository") {
                        HStack {
                            Text("Remote:")
                                .frame(width: 80, alignment: .leading)
                            Text("origin")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(.secondaryLabelColor).opacity(0.2))
                                )
                        }
                    }

                    FormSection(title: "Branches to Push") {
                        VStack(alignment: .leading, spacing: 4) {
                            TableHeader(columns: [
                                .init(title: "", width: 30),
                                .init(title: "Local Branch", width: nil),
                                .init(title: "Remote Branch", width: nil),
                                .init(title: "", width: 30)
                            ])

                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(branches, id: \.name) { branch in
                                        ListRow(
                                            isSelected: currentBranch?.name == branch.name,
                                            padding: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                                        ) {
                                            HStack {
                                                Toggle(isOn: Binding(
                                                    get: { selectedBranches.contains(branch.name) },
                                                    set: { isOn in
                                                        if isOn { selectedBranches.insert(branch.name) }
                                                        else { selectedBranches.remove(branch.name) }
                                                    }
                                                )) {
                                                    Text("")
                                                }
                                                .labelsHidden()
                                                .frame(width: 30)

                                                Text(branch.name)
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                Text(branch.name) // For remote branch, adjust as needed
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                Image(systemName: "minus.square")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 120)

                            Toggle("Select All", isOn: Binding(
                                get: { selectedBranches.count == branches.count },
                                set: { isOn in
                                    if isOn { selectedBranches = Set(branches.map { $0.name }) }
                                    else { selectedBranches.removeAll() }
                                }
                            ))
                            .padding(.vertical, 4)
                        }
                    }

                    FormSection(title: "Options", showDivider: false) {
                        Toggle("Push all tags", isOn: $pushAllTags)
                            .padding(.vertical, 4)
                    }
                }
            }

            SheetFooter(
                cancelAction: { isPresented = false },
                confirmAction: {
                    let selected = branches.filter { selectedBranches.contains($0.name) }
                    onPush(selected, pushAllTags)
                    isPresented = false
                },
                confirmText: "Push",
                isConfirmDisabled: selectedBranches.isEmpty
            )
        }
        .padding(24)
        .frame(minWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .onAppear {
            if let current = currentBranch {
                selectedBranches = [current.name]
            }
        }
    }
}
