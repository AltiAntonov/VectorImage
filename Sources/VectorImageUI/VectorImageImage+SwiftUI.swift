//
//  VectorImageImage+SwiftUI.swift
//  VectorImageUI
//
//  Bridges platform images from VectorImageCore into SwiftUI Image values.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import SwiftUI
import VectorImageCore

extension Image {
    init(vectorImagePlatformImage: VectorImagePlatformImage) {
#if canImport(UIKit)
        self.init(uiImage: vectorImagePlatformImage)
#elseif canImport(AppKit)
        self.init(nsImage: vectorImagePlatformImage)
#endif
    }
}
