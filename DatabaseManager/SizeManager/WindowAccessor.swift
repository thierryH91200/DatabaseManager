//
//  WindowAccessor.swift
//  Welcome
//
//  Created by thierryH24 on 04/08/2025.
//

import SwiftUI

//struct WindowAccessor: NSViewRepresentable {
//    let callback: (NSWindow?) -> Void
//
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        DispatchQueue.main.async {
//            self.callback(view.window)
//        }
//        return view
//    }
//
//    func updateNSView(_ nsView: NSView, context: Context) {
//        
//    }
//}


import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let onChange: (NSWindow?) -> Void

    init(onChange: @escaping (NSWindow?) -> Void) {
        self.onChange = onChange
    }

    func makeNSView(context: Context) -> WindowAttachingView {
        WindowAttachingView(onWindowChange: onChange)
    }

    func updateNSView(_ nsView: WindowAttachingView, context: Context) {
        // No update needed: WindowAttachingView reports changes on its own
    }

    final class WindowAttachingView: NSView {
        private let onWindowChange: (NSWindow?) -> Void

        init(onWindowChange: @escaping (NSWindow?) -> Void) {
            self.onWindowChange = onWindowChange
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindowChange(self.window)
        }

        override func viewWillMove(toWindow newWindow: NSWindow?) {
            super.viewWillMove(toWindow: newWindow)
            onWindowChange(newWindow)
        }
    }
}
