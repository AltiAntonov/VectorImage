//
//  ContentView.swift
//  VectorImageExample
//
//  Created by Altimir Antonov on 22.04.26.
//

import SwiftUI
import VectorImageCore
import VectorImageUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                PackageSummaryCard()

                ForEach(VectorImageExampleData.samples) { sample in
                    RenderedVectorImageView(sample: sample)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 0.99),
                    Color(red: 0.92, green: 0.95, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .vectorImageConfiguration(VectorImageExampleRuntime.configuration)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VectorImage")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.18))

            Text("A package-first SVG playground for the current VectorImage renderer.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                pill("iOS 15+")
                pill("Local SPM package")
                pill("No private SVG APIs")
                pill(VectorImageExampleRuntime.isCacheEnabled ? "Cache On" : "Cache Off")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.12, green: 0.18, blue: 0.28))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.92))
            )
    }
}

#Preview {
    ContentView()
}
