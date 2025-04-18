//
//  File.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
