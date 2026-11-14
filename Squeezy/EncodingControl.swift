//
//  EncodingControl.swift
//  Squeezy
//
//  Created by merkumac on 01/11/2026.
//

import Foundation

nonisolated final class EncodingControl: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false
    
    func run(_ process: Process) throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard !cancelled else {
            throw CancellationError()
        }
        
        try process.run()
        self.process = process
    }
    
    
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        cancelled = true
        
        if let process, process.isRunning {
            process.terminate()
        }
    }
    
    
    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }
    
    
    func finish() {
        lock.lock()
        process = nil
        lock.unlock()
    }
}
