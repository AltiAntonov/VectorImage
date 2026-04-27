//
//  VectorImageAsyncImage.swift
//  VectorImageUI
//
//  SwiftUI async image view backed by VectorImageCore.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import SwiftUI
import VectorImageCore

/// A SwiftUI view that asynchronously loads and renders SVG content from a ``VectorImageSource``.
public struct VectorImageAsyncImage<Content: View>: View {
    private let source: VectorImageSource
    private let configuration: VectorImageConfiguration
    private let options: VectorImageRasterizationOptions
    private let transaction: Transaction
    private let content: (VectorImageAsyncImagePhase) -> Content

    @Environment(\.displayScale) private var displayScale
    @State private var phase: VectorImageAsyncImagePhase = .empty

    public init(
        source: VectorImageSource,
        loader: VectorImageLoader = .init(),
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil,
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.init(
            source: source,
            configuration: .init(loader: loader, cachePolicy: cache.map(VectorImageCachePolicy.enabled) ?? .disabled),
            options: options,
            transaction: transaction,
            content: content
        )
    }

    public init(
        source: VectorImageSource,
        configuration: VectorImageConfiguration,
        options: VectorImageRasterizationOptions = .init(),
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.source = source
        self.configuration = configuration
        self.options = options
        self.transaction = transaction
        self.content = content
    }

    public var body: some View {
        content(phase)
            .task(id: request) {
                await load()
            }
    }

    @MainActor
    private func load() async {
        withTransaction(transaction) {
            phase = .empty
        }

        do {
            let result = try await VectorImageRenderer.render(
                from: request.source,
                configuration: request.configuration,
                options: request.options
            )

            let value = VectorImageAsyncImageValue(
                image: Image(vectorImagePlatformImage: result.image),
                platformImage: result.image,
                diagnostics: result.diagnostics
            )

            withTransaction(transaction) {
                phase = .success(value)
            }
        } catch is CancellationError {
            return
        } catch {
            withTransaction(transaction) {
                phase = .failure(error)
            }
        }
    }

    private var request: VectorImageAsyncImageRequest {
        var resolvedOptions = options
        if resolvedOptions.scale <= 0 {
            resolvedOptions = .init(
                size: resolvedOptions.size,
                scale: displayScale,
                contentMode: resolvedOptions.contentMode,
                opaque: resolvedOptions.opaque,
                backgroundColor: resolvedOptions.backgroundColor
            )
        }

        return VectorImageAsyncImageRequest(source: source, configuration: configuration, options: resolvedOptions)
    }
}

public extension VectorImageAsyncImage where Content == Image {
    init(
        source: VectorImageSource,
        loader: VectorImageLoader = .init(),
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil,
        transaction: Transaction = .init()
    ) {
        self.init(
            source: source,
            loader: loader,
            options: options,
            cache: cache,
            transaction: transaction
        ) { phase in
            phase.image ?? Image(systemName: "photo")
        }
    }

    init(
        source: VectorImageSource,
        configuration: VectorImageConfiguration,
        options: VectorImageRasterizationOptions = .init(),
        transaction: Transaction = .init()
    ) {
        self.init(
            source: source,
            configuration: configuration,
            options: options,
            transaction: transaction
        ) { phase in
            phase.image ?? Image(systemName: "photo")
        }
    }

    init(
        svgData: Data,
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil,
        transaction: Transaction = .init()
    ) {
        self.init(
            source: .data(svgData),
            options: options,
            cache: cache,
            transaction: transaction
        )
    }

    init(
        svgData: Data,
        configuration: VectorImageConfiguration,
        options: VectorImageRasterizationOptions = .init(),
        transaction: Transaction = .init()
    ) {
        self.init(
            source: .data(svgData),
            configuration: configuration,
            options: options,
            transaction: transaction
        )
    }

    init(
        fileURL: URL,
        loader: VectorImageLoader = .init(),
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil,
        transaction: Transaction = .init()
    ) {
        self.init(
            source: .fileURL(fileURL),
            loader: loader,
            options: options,
            cache: cache,
            transaction: transaction
        )
    }

    init(
        fileURL: URL,
        configuration: VectorImageConfiguration,
        options: VectorImageRasterizationOptions = .init(),
        transaction: Transaction = .init()
    ) {
        self.init(
            source: .fileURL(fileURL),
            configuration: configuration,
            options: options,
            transaction: transaction
        )
    }
}

public extension VectorImageAsyncImage {
    init(
        svgData: Data,
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil,
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.init(
            source: .data(svgData),
            options: options,
            cache: cache,
            transaction: transaction,
            content: content
        )
    }

    init(
        svgData: Data,
        configuration: VectorImageConfiguration,
        options: VectorImageRasterizationOptions = .init(),
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.init(
            source: .data(svgData),
            configuration: configuration,
            options: options,
            transaction: transaction,
            content: content
        )
    }

    init(
        fileURL: URL,
        loader: VectorImageLoader = .init(),
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil,
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.init(
            source: .fileURL(fileURL),
            loader: loader,
            options: options,
            cache: cache,
            transaction: transaction,
            content: content
        )
    }

    init(
        fileURL: URL,
        configuration: VectorImageConfiguration,
        options: VectorImageRasterizationOptions = .init(),
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.init(
            source: .fileURL(fileURL),
            configuration: configuration,
            options: options,
            transaction: transaction,
            content: content
        )
    }

    init(
        url: URL,
        loader: VectorImageLoader = .init(),
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil,
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.init(
            source: .remoteURL(url),
            loader: loader,
            options: options,
            cache: cache,
            transaction: transaction,
            content: content
        )
    }

    init(
        url: URL,
        configuration: VectorImageConfiguration,
        options: VectorImageRasterizationOptions = .init(),
        transaction: Transaction = .init(),
        @ViewBuilder content: @escaping (VectorImageAsyncImagePhase) -> Content
    ) {
        self.init(
            source: .remoteURL(url),
            configuration: configuration,
            options: options,
            transaction: transaction,
            content: content
        )
    }
}

private struct VectorImageAsyncImageRequest: Hashable {
    let source: VectorImageSource
    let configuration: VectorImageConfiguration
    let options: VectorImageRasterizationOptions
}
