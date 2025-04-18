//
//  MonthHeaderView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

struct MonthHeaderView: View {
    let date: Date

    var body: some View {
        Text(date.formatted(.dateTime.month(.wide).year()))
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor).opacity(0.8))
    }
}
