//
//  VectorImageConfigurationEnvironment.swift
//  VectorImageUI
//
//  Provides SwiftUI environment support for VectorImage configuration.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import SwiftUI
import VectorImageCore

private struct VectorImageConfigurationEnvironmentKey: EnvironmentKey {
    static let defaultValue = VectorImageConfiguration.default
}

public extension EnvironmentValues {
    /// The default source-rendering configuration used by `VectorImageAsyncImage`.
    var vectorImageConfiguration: VectorImageConfiguration {
        get { self[VectorImageConfigurationEnvironmentKey.self] }
        set { self[VectorImageConfigurationEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Sets the default source-rendering configuration for descendant `VectorImageAsyncImage` views.
    func vectorImageConfiguration(_ configuration: VectorImageConfiguration) -> some View {
        environment(\.vectorImageConfiguration, configuration)
    }
}
