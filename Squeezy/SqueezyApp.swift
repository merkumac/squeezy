// SPDX-FileCopyrightText: 2026 merkumac
// SPDX-License-Identifier: MIT

import SwiftUI

@main
struct SqueezyApp: App {
    @FocusedValue(\.openVideo) private var openVideo
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 650)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openVideo?()
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(openVideo == nil)
            }
        }
    }
}
