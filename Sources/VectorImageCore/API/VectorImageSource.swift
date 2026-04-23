//
//  VectorImageSource.swift
//  VectorImageCore
//
//  Defines lightweight source values for local and remote vector image content.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// A source from which SVG bytes can be loaded.
public enum VectorImageSource: Sendable, Hashable {
    case data(Data)
    case fileURL(URL)
    case remoteURL(URL)
}
