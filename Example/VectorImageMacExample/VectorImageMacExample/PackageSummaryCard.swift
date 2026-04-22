//
//  PackageSummaryCard.swift
//  VectorImageMacExample
//
//  Shows the current package layering used by the macOS demo.
//

import SwiftUI

struct PackageSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Package Layers")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            summaryRow(
                title: "VectorImageCore",
                description: "Production target today. Dependency-free detection, parsing, diagnostics, caching, and rasterization."
            )

            summaryRow(
                title: "VectorImageAdvanced",
                description: "Placeholder target. Not needed for this macOS validation app."
            )

            summaryRow(
                title: "VectorImageUI",
                description: "Placeholder target. UI convenience APIs are planned separately from the core renderer."
            )
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.11, blue: 0.18),
                    Color(red: 0.13, green: 0.21, blue: 0.33)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private func summaryRow(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(description)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
        }
    }
}
