//
//  VectorImageMacExampleRuntime.swift
//  VectorImageMacExample
//
//  Holds simple runtime configuration for the macOS example app.
//

import Foundation
import VectorImageCore

enum VectorImageMacExampleRuntime {
    static let disableCacheLaunchArgument = "--vectorimage-disable-cache"

    static let isCacheEnabled = ProcessInfo.processInfo.arguments.contains(disableCacheLaunchArgument) == false

    static let renderCache: VectorImageCache? = isCacheEnabled ? VectorImageCache(countLimit: 200) : nil

    static let configuration = VectorImageConfiguration(
        cachePolicy: renderCache.map(VectorImageCachePolicy.enabled) ?? .disabled
    )
}
