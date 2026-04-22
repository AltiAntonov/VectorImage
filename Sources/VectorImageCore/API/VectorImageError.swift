//
//  VectorImageError.swift
//  VectorImageCore
//
//  Declares public error cases used by VectorImage rendering APIs.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Errors emitted by the VectorImage core pipeline.
public enum VectorImageError: Error, Equatable, Sendable {
    case emptyData
    case invalidUTF8
    case notSVG
    case invalidXML
    case missingSVGRoot
    case invalidDocumentSize
    case unsupportedFeature(String)
    case unsupportedPathCommand(Character)
}
