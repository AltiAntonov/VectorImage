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

@Test("Removes script elements before rendering")
func removesScriptElementsBeforeRendering() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12">
            <script>alert("nope")</script>
            <rect width="12" height="12" fill="#33588B" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(!processed.contains("<script"))
    #expect(processed.contains("<rect"))
    #expect(result.diagnostics.warnings.contains("Removed unsupported SVG element: script"))
}

@Test("Removes event handler attributes before rendering")
func removesEventHandlerAttributesBeforeRendering() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" onload="track()">
            <rect width="12" height="12" fill="#33588B" onclick="track()" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(!processed.contains("onload"))
    #expect(!processed.contains("onclick"))
    #expect(result.diagnostics.warnings.contains("Removed unsupported SVG event handler attribute: onload"))
    #expect(result.diagnostics.warnings.contains("Removed unsupported SVG event handler attribute: onclick"))
}

@Test("Removes external resource references before rendering")
func removesExternalResourceReferencesBeforeRendering() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12">
            <image href="https://example.com/image.png" width="12" height="12" />
            <rect width="12" height="12" fill="url(https://example.com/fill.svg#gradient)" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(!processed.contains("https://example.com"))
    #expect(result.diagnostics.warnings.contains("Removed unsupported SVG external resource reference: href"))
    #expect(result.diagnostics.warnings.contains("Removed unsupported SVG external resource reference: fill"))
}

@Test("Renders preprocessed SVG data through Core")
func rendersPreprocessedSVGDataThroughCore() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12">
            <script>alert("nope")</script>
            <rect width="12" height="12" fill="#33588B" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.render(svgData: data)

    #expect(result.diagnostics.warnings.contains("Removed unsupported SVG element: script"))
}
