//
//  OpenVideoAction.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

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
