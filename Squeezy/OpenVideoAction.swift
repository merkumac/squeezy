// SPDX-FileCopyrightText: 2026 merkumac
// SPDX-License-Identifier: MIT

import SwiftUI

struct OpenVideoActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var openVideo: (() -> Void)? {
        get { self[OpenVideoActionKey.self] }
        set { self[OpenVideoActionKey.self] = newValue }
    }
}
