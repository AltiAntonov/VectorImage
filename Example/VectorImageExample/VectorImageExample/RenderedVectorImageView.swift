//
//  RenderedVectorImageView.swift
//  VectorImageExample
//
//  Renders SVG example payloads into SwiftUI views using VectorImageCore.
//

import SwiftUI
import UIKit
import VectorImageCore

struct RenderedVectorImageView: View {
    let sample: VectorImageExampleData

    @State private var renderedImage: UIImage?
    @State private var warnings: [String] = []
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 24)
                .fill(sample.previewBackgroundColor)
                .overlay {
                    Group {
                        if let renderedImage {
                            Image(uiImage: renderedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(16)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(20)
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
                .frame(height: 210)

            Text(sample.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.11, green: 0.16, blue: 0.24))

            Text(sample.subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            if warnings.isEmpty == false {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Diagnostics")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.orange)

                    ForEach(warnings, id: \.self) { warning in
                        Text(warning)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.orange.opacity(0.08))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
        )
        .task(id: sample.id) {
            await render()
        }
    }

    @MainActor
    private func render() async {
        do {
            switch sample.source {
            case .svg(let svg):
                let result = try VectorImageRenderer.render(
                    svgData: Data(svg.utf8),
                    options: .init(
                        size: sample.size,
                        scale: UIScreen.main.scale,
                        contentMode: .fit,
                        backgroundColor: sample.rasterizationBackgroundColor
                    )
                )
                renderedImage = result.image
                warnings = result.diagnostics.warnings
                errorMessage = nil
            case .asset(let name):
                guard let image = UIImage(named: name) else {
                    renderedImage = nil
                    warnings = []
                    errorMessage = "Missing asset: \(name)"
                    return
                }
                renderedImage = image
                warnings = []
                errorMessage = nil
            case .remoteURL(let url):
                let result = try await VectorImageRenderer.render(
                    from: .remoteURL(url),
                    options: .init(
                        size: sample.size,
                        scale: UIScreen.main.scale,
                        contentMode: .fit,
                        backgroundColor: sample.rasterizationBackgroundColor
                    ),
                    cache: VectorImageExampleRuntime.renderCache
                )
                renderedImage = result.image
                warnings = result.diagnostics.warnings
                errorMessage = nil
            }
        } catch {
            renderedImage = nil
            warnings = []
            errorMessage = error.localizedDescription
        }
    }
}
