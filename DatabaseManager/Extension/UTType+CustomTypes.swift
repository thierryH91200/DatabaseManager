//
//  UTType+CustomTypes.swift
//  WelcomeTo
//
//  Created by thierryH24 on 05/08/2025.
//

internal import UniformTypeIdentifiers
import SwiftUI
import AppKit

extension UTType {
    static var sqlite: UTType {
        UTType(filenameExtension: "sqlite") ?? .data
    }
    static var store: UTType {
        UTType(filenameExtension: "store") ?? .data
    }
}

// MARK: - Extension pour UTType
extension UTType {
    static var database: UTType {
        UTType(filenameExtension: "sqlite") ?? .data
    }
}

