//
//  View.swift
//  DataBaseManager
//
//  Created by thierryH24 on 25/08/2025.
//

import SwiftUI
import AppKit

extension View {
    func uniformButton(width: CGFloat = 200) -> some View {
        self
            .frame(width: width)
            .controlSize(.regular)
            .background(Color.red.opacity(0.2))
    }
}
