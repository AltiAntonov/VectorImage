//
//  RenderedVectorImageView.swift
//  VectorImageExample
//
//  Renders SVG example payloads into SwiftUI views using VectorImageCore and VectorImageUI.
//

import SwiftUI
import UIKit
import VectorImageCore
import VectorImageUI

struct RenderedVectorImageView: View {
    let sample: VectorImageExampleData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 24)
                .fill(sample.previewBackgroundColor)
                .overlay {
                    sampleImage
                }
                .frame(height: 210)

            Text(sample.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.11, green: 0.16, blue: 0.24))

            Text(sample.subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
        )
    }

    private var rasterizationOptions: VectorImageRasterizationOptions {
        .init(
            size: sample.size,
            contentMode: .fit,
            backgroundColor: sample.rasterizationBackgroundColor
        )
    }

    @ViewBuilder
    private var sampleImage: some View {
        switch sample.source {
        case .svg(let svg):
            vectorImagePhaseView(source: .data(Data(svg.utf8)))
        case .asset(let name):
            if let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)
            } else {
                errorView("Missing asset: \(name)")
            }
        case .remoteURL(let url):
            vectorImagePhaseView(source: .remoteURL(url))
        }
    }

    private func vectorImagePhaseView(source: VectorImageSource) -> some View {
        VectorImageAsyncImage(
            source: source,
            options: rasterizationOptions
        ) { phase in
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if let error = phase.error {
                        errorView(error.localizedDescription)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let diagnostics = phase.diagnostics, diagnostics.warnings.isEmpty == false {
                    diagnosticsView(diagnostics.warnings)
                }
            }
            .padding(16)
        }
    }

    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func diagnosticsView(_ warnings: [String]) -> some View {
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
