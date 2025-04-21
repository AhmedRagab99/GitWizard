//
//  ExpandableModel.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct ExpandableModel<Model: Hashable>: Hashable {
    var isExpanded: Bool
    var model: Model
}
