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

@Test("Normalizes inline style declarations into presentation attributes")
func normalizesInlineStyleDeclarationsIntoPresentationAttributes() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12">
            <rect width="12" height="12" style="fill: #33588B; stroke: #FFFFFF;" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains(##"fill="#33588B""##))
    #expect(processed.contains(##"stroke="#FFFFFF""##))
    #expect(!processed.contains("style="))
    #expect(result.diagnostics.warnings.contains("Inlined SVG style declarations from attribute: style"))
}

@Test("Inlines simple stylesheet class id and element rules")
func inlinesSimpleStylesheetRules() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12">
            <style>
                rect { stroke: #111111; }
                .primary { fill: #33588B; }
                #target { opacity: 0.5; }
            </style>
            <rect id="target" class="primary" width="12" height="12" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains(##"fill="#33588B""##))
    #expect(processed.contains(##"stroke="#111111""##))
    #expect(processed.contains(##"opacity="0.5""##))
    #expect(!processed.contains("<style"))
    #expect(result.diagnostics.warnings.contains("Inlined supported SVG stylesheet rules"))
}

@Test("Keeps element attributes above stylesheet rules")
func keepsElementAttributesAboveStylesheetRules() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12">
            <style>.primary { fill: #33588B; stroke: #111111; }</style>
            <rect class="primary" width="12" height="12" fill="#FF0000" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains(##"fill="#FF0000""##))
    #expect(!processed.contains(##"fill="#33588B""##))
    #expect(processed.contains(##"stroke="#111111""##))
}

@Test("Reports unsupported stylesheet selectors")
func reportsUnsupportedStylesheetSelectors() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12">
            <style>
                rect > .primary { fill: #33588B; }
                @media (prefers-color-scheme: dark) { rect { fill: #FFFFFF; } }
            </style>
            <rect class="primary" width="12" height="12" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)

    #expect(result.diagnostics.warnings.contains("Unsupported SVG stylesheet rule preserved as diagnostic: rect > .primary"))
    #expect(result.diagnostics.warnings.contains("Unsupported SVG stylesheet rule preserved as diagnostic: @media (prefers-color-scheme: dark)"))
}

@Test("Expands local symbol use references into renderable elements")
func expandsLocalSymbolUseReferencesIntoRenderableElements() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="16" viewBox="0 0 32 16">
            <defs>
                <symbol id="tile" viewBox="0 0 10 10">
                    <rect width="10" height="10" fill="#33588B" />
                </symbol>
            </defs>
            <use href="#tile" x="4" y="3" width="10" height="10" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains("<use") == false)
    #expect(processed.contains("<symbol") == false)
    #expect(processed.contains(##"fill="#33588B""##))
    #expect(processed.contains(##"transform="translate(4 3)""##))
    #expect(result.diagnostics.warnings.contains("Expanded local SVG use reference: #tile"))
}

@Test("Renders expanded local use references through Core")
func rendersExpandedLocalUseReferencesThroughCore() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="16" viewBox="0 0 32 16">
            <defs>
                <symbol id="tile" viewBox="0 0 10 10">
                    <rect width="10" height="10" fill="#33588B" />
                </symbol>
            </defs>
            <use href="#tile" x="4" y="3" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.render(
        svgData: data,
        options: .init(size: CGSize(width: 32, height: 16))
    )

    #expect(result.diagnostics.warnings.contains("Expanded local SVG use reference: #tile"))
}

@Test("Expands paired local use tags")
func expandsPairedLocalUseTags() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="16" viewBox="0 0 32 16">
            <defs>
                <symbol id="tile" viewBox="0 0 10 10">
                    <rect width="10" height="10" fill="#33588B" />
                </symbol>
            </defs>
            <use href="#tile" x="4" y="3"></use>
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains("<use") == false)
    #expect(processed.contains("</use>") == false)
    #expect(processed.contains(##"fill="#33588B""##))
}

@Test("Combines use translation with existing referenced transforms")
func combinesUseTranslationWithExistingReferencedTransforms() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="16" viewBox="0 0 32 16">
            <defs>
                <g id="mark" transform="scale(2)">
                    <circle cx="4" cy="4" r="4" fill="#F97316" />
                </g>
            </defs>
            <use href="#mark" x="5" y="6" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains("<use") == false)
    #expect(processed.contains(##"transform="translate(5 6) scale(2)""##))
    #expect(result.diagnostics.warnings.contains("Expanded local SVG use reference: #mark"))
}

@Test("Reports unresolved local use references")
func reportsUnresolvedLocalUseReferences() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">
            <use href="#missing" x="0" y="0" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains("<use") == false)
    #expect(result.diagnostics.warnings.contains("Unsupported SVG use reference could not be resolved: #missing"))
}

@Test("Reports external use references")
func reportsExternalUseReferences() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">
            <use href="https://example.com/icons.svg#external" x="0" y="0" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains("<use") == false)
    #expect(result.diagnostics.warnings.contains("Unsupported external SVG use reference: https://example.com/icons.svg#external"))
}

@Test("Preserves unrelated definitions while removing expanded symbols")
func preservesUnrelatedDefinitionsWhileRemovingExpandedSymbols() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="16" viewBox="0 0 32 16">
            <defs>
                <radialGradient id="paint">
                    <stop offset="0" stop-color="#FFFFFF" />
                    <stop offset="1" stop-color="#33588B" />
                </radialGradient>
                <symbol id="tile" viewBox="0 0 10 10">
                    <rect width="10" height="10" fill="#33588B" />
                </symbol>
            </defs>
            <use href="#tile" x="4" y="3" />
            <circle cx="24" cy="8" r="6" fill="url(#paint)" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains("<radialGradient"))
    #expect(processed.contains(##"fill="url(#paint)""##))
    #expect(processed.contains("<symbol") == false)
}

@Test("Reports recursive local use references")
func reportsRecursiveLocalUseReferences() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">
            <defs>
                <g id="loop">
                    <use href="#loop" />
                </g>
            </defs>
            <use href="#loop" />
        </svg>
        """.utf8
    )

    let result = try VectorImageAdvancedProcessor.process(svgData: data)
    let processed = try #require(String(data: result.svgData, encoding: .utf8))

    #expect(processed.contains("<use") == false)
    #expect(result.diagnostics.warnings.contains("Unsupported recursive SVG use reference: #loop"))
}
