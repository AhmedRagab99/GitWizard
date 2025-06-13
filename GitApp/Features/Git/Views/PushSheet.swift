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
            HStack {
                Text("Push to repository:")
                    .font(.headline)
                Spacer()
                Text("origin")
                    .font(.body)
                    .padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.secondaryLabelColor)))
            }
            .padding(.bottom, 4)

            Text("Branches to push")
                .font(.subheadline)
                .padding(.bottom, 2)

            TableHeader(columns: [
                .init(title: "", width: 30),
                .init(title: "Local Branch", width: nil),
                .init(title: "Remote Branch", width: nil),
                .init(title: "", width: 30)
            ])

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(branches, id: \.name) { branch in
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
                            Spacer()
                            Image(systemName: "minus.square")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .background(currentBranch?.name == branch.name ? Color.accentColor.opacity(0.08) : Color.clear)
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

            Toggle("Push all tags", isOn: $pushAllTags)
                .padding(.vertical, 4)

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("OK") {
                    let selected = branches.filter { selectedBranches.contains($0.name) }
                    onPush(selected, pushAllTags)
                    isPresented = false
                }
                .disabled(selectedBranches.isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .shadow(radius: 20)
        .onAppear {
            if let current = currentBranch {
                selectedBranches = [current.name]
            }
        }
    }
}
