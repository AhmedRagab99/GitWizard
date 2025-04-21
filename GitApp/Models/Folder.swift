//
//  Folder.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct Folder: Hashable, Codable {
    var url: URL
    var displayName: String {
        url.path.components(separatedBy: "/").filter{ !$0.isEmpty }.last ?? ""
    }
}