//
//  VectorImagePlatformImage.swift
//  VectorImageCore
//
//  Defines cross-platform image aliases used by the VectorImage renderer.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
public typealias VectorImagePlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias VectorImagePlatformImage = NSImage
#endif

enum VectorImagePlatformFactory {
    static func makeImage(cgImage: CGImage, logicalSize: CGSize, scale: CGFloat) -> VectorImagePlatformImage {
#if canImport(UIKit)
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
#elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: logicalSize)
#endif
    }
}
