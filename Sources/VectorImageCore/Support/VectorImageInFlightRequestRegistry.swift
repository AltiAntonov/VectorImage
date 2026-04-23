//
//  VectorImageInFlightRequestRegistry.swift
//  VectorImageCore
//
//  Coalesces identical in-flight source-based render requests.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

@available(iOS 15.0, macOS 12.0, *)
actor VectorImageInFlightRequestRegistry {
    static let shared = VectorImageInFlightRequestRegistry()

    private var tasks: [VectorImageInFlightRequestKey: Task<VectorImageRenderResult, any Error>] = [:]

    func result(
        for key: VectorImageInFlightRequestKey,
        start: @Sendable @escaping () async throws -> VectorImageRenderResult
    ) async throws -> VectorImageRenderResult {
        if let task = tasks[key] {
            return try await task.value
        }

        let task = Task {
            try await start()
        }
        tasks[key] = task

        do {
            let result = try await task.value
            tasks[key] = nil
            return result
        } catch {
            tasks[key] = nil
            throw error
        }
    }
}

struct VectorImageInFlightRequestKey: Hashable, Sendable {
    let source: VectorImageSource
    let options: VectorImageRasterizationOptions
    let loaderIdentity: Int
}
