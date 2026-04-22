//
//  VectorImageExampleData.swift
//  VectorImageExample
//
//  Defines the example SVG payloads rendered by the demo application.
//

import CoreGraphics
import Foundation
import SwiftUI
import VectorImageCore

struct VectorImageExampleData: Identifiable {
    enum Source {
        case svg(String)
        case asset(name: String)
        case remoteURL(URL)
    }

    let id: String
    let title: String
    let subtitle: String
    let source: Source
    let size: CGSize
    let previewBackgroundColor: Color
    let rasterizationBackgroundColor: VectorImageColor?

    init(
        id: String,
        title: String,
        subtitle: String,
        source: Source,
        size: CGSize,
        previewBackgroundColor: Color,
        rasterizationBackgroundColor: VectorImageColor?
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.source = source
        self.size = size
        self.previewBackgroundColor = previewBackgroundColor
        self.rasterizationBackgroundColor = rasterizationBackgroundColor
    }
}

extension VectorImageExampleData {
    private static func simpleIconsURL(_ brand: String) -> URL {
        URL(string: "https://cdn.jsdelivr.net/npm/simple-icons@v16/icons/\(brand).svg")!
    }

    static let samples: [VectorImageExampleData] = [
        .init(
            id: "brand-card",
            title: "Brand Card",
            subtitle: "Rectangles, circles, and layout-like composition using supported primitives only.",
            source: .svg("""
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 140" width="240" height="140">
              <rect x="0" y="0" width="240" height="140" fill="#101826" />
              <rect x="12" y="12" width="216" height="116" fill="#172033" />
              <rect x="20" y="20" width="100" height="100" fill="#F97316" />
              <circle cx="170" cy="54" r="26" fill="#38BDF8" />
              <ellipse cx="170" cy="98" rx="38" ry="16" fill="#A3E635" />
              <line x1="120" y1="20" x2="220" y2="20" stroke="#E5E7EB" stroke-width="4" />
              <line x1="120" y1="34" x2="205" y2="34" stroke="#94A3B8" stroke-width="4" />
              <line x1="120" y1="92" x2="210" y2="92" stroke="#E5E7EB" stroke-width="8" />
              <line x1="120" y1="108" x2="190" y2="108" stroke="#94A3B8" stroke-width="6" />
            </svg>
            """),
            size: CGSize(width: 240, height: 140),
            previewBackgroundColor: Color(red: 0.08, green: 0.11, blue: 0.17),
            rasterizationBackgroundColor: nil
        ),
        .init(
            id: "signal",
            title: "Signal Waves",
            subtitle: "Path support with cubic curves and layered shapes.",
            source: .svg("""
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 120" width="240" height="120">
              <rect x="0" y="0" width="240" height="120" fill="#08111F" />
              <path d="M 16 76 C 36 44, 56 44, 76 76 C 96 108, 116 108, 136 76 C 156 44, 176 44, 196 76 C 208 96, 218 98, 224 88" stroke="#38BDF8" stroke-width="10" fill="none" />
              <path d="M 16 64 C 36 32, 56 32, 76 64 C 96 96, 116 96, 136 64 C 156 32, 176 32, 196 64 C 208 84, 218 86, 224 76" stroke="#F97316" stroke-width="6" fill="none" />
              <polygon points="18,96 40,100 58,84 80,96 102,92 120,102 144,88 164,98 188,80 220,96" fill="#A3E635" fill-opacity="0.65" />
            </svg>
            """),
            size: CGSize(width: 240, height: 120),
            previewBackgroundColor: Color(red: 0.08, green: 0.11, blue: 0.17),
            rasterizationBackgroundColor: nil
        ),
        .init(
            id: "diagnostics",
            title: "Diagnostics",
            subtitle: "Includes unsupported filter definitions so the demo can surface non-fatal warnings.",
            source: .svg("""
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 140" width="220" height="140">
              <defs>
                <filter id="blur">
                  <feGaussianBlur stdDeviation="4" />
                </filter>
              </defs>
              <rect x="0" y="0" width="220" height="140" fill="#111827" />
              <rect x="16" y="16" width="188" height="108" fill="#2563EB" />
              <path d="M 28 92 Q 72 38, 112 92 Q 152 38, 192 92" stroke="#F8FAFC" stroke-width="10" fill="none" filter="url(#blur)" />
            </svg>
            """),
            size: CGSize(width: 220, height: 140),
            previewBackgroundColor: Color(red: 0.08, green: 0.11, blue: 0.17),
            rasterizationBackgroundColor: nil
        ),
        .init(
            id: "asset-orbit-badge",
            title: "Asset: Orbit Badge",
            subtitle: "Generic SVG asset loaded through the example app asset catalog for visual comparison.",
            source: .asset(name: "orbitBadge"),
            size: CGSize(width: 220, height: 220),
            previewBackgroundColor: Color(red: 0.05, green: 0.08, blue: 0.13),
            rasterizationBackgroundColor: nil
        ),
        .init(
            id: "asset-grid-glyph",
            title: "Asset: Grid Glyph",
            subtitle: "Another bundled SVG asset to keep the asset-catalog path visible in the demo.",
            source: .asset(name: "gridGlyph"),
            size: CGSize(width: 220, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: nil
        ),
        .init(
            id: "remote-simple-icons-github",
            title: "Remote URL: Simple Icons GitHub",
            subtitle: "Loaded from jsDelivr using the simple-icons CDN pattern.",
            source: .remoteURL(simpleIconsURL("github")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-apple",
            title: "Remote URL: Simple Icons Apple",
            subtitle: "A compact silhouette with cutouts from the same simple-icons source.",
            source: .remoteURL(simpleIconsURL("apple")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-meta",
            title: "Remote URL: Simple Icons Meta",
            subtitle: "Curved logo with multiple compound segments from the same CDN URL pattern.",
            source: .remoteURL(simpleIconsURL("meta")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-google",
            title: "Remote URL: Simple Icons Google",
            subtitle: "Open-ring geometry that is useful for checking compound silhouettes and missing wedges.",
            source: .remoteURL(simpleIconsURL("google")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-wikimedia-github",
            title: "Remote URL: Wikimedia GitHub",
            subtitle: "External GitHub mark loaded from Wikimedia as a direct non-CDN SVG check.",
            source: .remoteURL(URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/91/Octicons-mark-github.svg")!),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-bootstrap-alarm",
            title: "Remote URL: Bootstrap Alarm",
            subtitle: "External icon loaded from Bootstrap Icons to exercise another SVG source style.",
            source: .remoteURL(URL(string: "https://icons.getbootstrap.com/assets/icons/alarm.svg")!),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-gitkraken",
            title: "Remote URL: Simple Icons GitKraken",
            subtitle: "Curved negative-space mark from the simple-icons catalog.",
            source: .remoteURL(simpleIconsURL("gitkraken")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-docker",
            title: "Remote URL: Simple Icons Docker",
            subtitle: "Repeated small blocks plus a larger silhouette to exercise compound path rendering.",
            source: .remoteURL(simpleIconsURL("docker")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-figma",
            title: "Remote URL: Simple Icons Figma",
            subtitle: "Rounded stacked geometry that is useful for checking curves and internal joins.",
            source: .remoteURL(simpleIconsURL("figma")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-spotify",
            title: "Remote URL: Simple Icons Spotify",
            subtitle: "Circular brand mark with layered arc strokes for another interesting shape profile.",
            source: .remoteURL(simpleIconsURL("spotify")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-kubernetes",
            title: "Remote URL: Simple Icons Kubernetes",
            subtitle: "Spoked wheel geometry with multiple internal cutouts and curved segments.",
            source: .remoteURL(simpleIconsURL("kubernetes")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-cloudflare",
            title: "Remote URL: Simple Icons Cloudflare",
            subtitle: "Layered cloud-like silhouette with overlapping rounded forms.",
            source: .remoteURL(simpleIconsURL("cloudflare")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-blender",
            title: "Remote URL: Simple Icons Blender",
            subtitle: "Asymmetrical mark with cutouts and long curved arms.",
            source: .remoteURL(simpleIconsURL("blender")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-firefox",
            title: "Remote URL: Simple Icons Firefox Browser",
            subtitle: "Curved browser mark with more aggressive silhouette variation.",
            source: .remoteURL(simpleIconsURL("firefoxbrowser")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-simple-icons-gitlab",
            title: "Remote URL: Simple Icons GitLab",
            subtitle: "Triangular compound mark that is good for checking sharp joins and symmetry.",
            source: .remoteURL(simpleIconsURL("gitlab")),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-bootstrap-bezier2",
            title: "Remote URL: Bootstrap Bezier",
            subtitle: "Bootstrap icon with circles, joins, and connecting segments.",
            source: .remoteURL(URL(string: "https://icons.getbootstrap.com/assets/icons/bezier2.svg")!),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-bootstrap-bug",
            title: "Remote URL: Bootstrap Bug",
            subtitle: "Bootstrap icon with mirrored legs and multiple small subpaths.",
            source: .remoteURL(URL(string: "https://icons.getbootstrap.com/assets/icons/bug.svg")!),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-bootstrap-cloud-lightning-rain",
            title: "Remote URL: Bootstrap Cloud Lightning Rain",
            subtitle: "Bootstrap weather icon with a larger compound silhouette and several internal shapes.",
            source: .remoteURL(URL(string: "https://icons.getbootstrap.com/assets/icons/cloud-lightning-rain.svg")!),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-bootstrap-activity",
            title: "Remote URL: Bootstrap Activity",
            subtitle: "Bootstrap waveform icon that is useful for checking repeated sharp turns.",
            source: .remoteURL(URL(string: "https://icons.getbootstrap.com/assets/icons/activity.svg")!),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        ),
        .init(
            id: "remote-bootstrap-hexagon",
            title: "Remote URL: Bootstrap Hexagon",
            subtitle: "Bootstrap polygonal icon for another clean-shape validation point.",
            source: .remoteURL(URL(string: "https://icons.getbootstrap.com/assets/icons/hexagon.svg")!),
            size: CGSize(width: 180, height: 180),
            previewBackgroundColor: .white,
            rasterizationBackgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        )
    ]
}
