//
//  VectorImageAdvancedTests.swift
//  VectorImageAdvancedTests
//
//  Validates the public Advanced preprocessing API surface.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Testing
import VectorImageAdvanced
import VectorImageCore

@Test("Processes supported SVG data without changing bytes")
func processesSupportedSVGDataWithoutChangingBytes() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12">
            <rect width="12" height="12" fill="#33588B" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)

    #expect(result.svgData == data)
    #expect(result.diagnostics.warnings.isEmpty)
}

@Test("Rejects non-SVG data")
func rejectsNonSVGData() {
    let data = Data("not svg".utf8)

    #expect(throws: VectorImageError.notSVG) {
        try VectorImageAdvancedProcessor.process(svgData: data)
    }
}

@Test("Rejects empty data")
func rejectsEmptyData() {
    #expect(throws: VectorImageError.emptyData) {
        try VectorImageAdvancedProcessor.process(svgData: Data())
    }
}
