import CoreGraphics
import Foundation
import Testing
@testable import VectorImageCore

#if canImport(Darwin)
import Darwin
#endif

@Test("Simple fixture stays within baseline render budget")
func simpleFixturePerformanceBudget() throws {
    let fixtureURL = try #require(Bundle.module.url(forResource: "simple-rect", withExtension: "svg"))
    let data = try Data(contentsOf: fixtureURL)

    let metrics = try measureRenderMetrics(
        svgData: data,
        iterations: 150,
        options: .init(size: CGSize(width: 120, height: 80))
    )

    #expect(metrics.averageMilliseconds < 8)
    #expect(metrics.residentMemoryDeltaMB < 24)
}

@Test("Representative compound fixture stays within baseline render budget")
func representativeFixturePerformanceBudget() throws {
    let fixtureURL = try #require(Bundle.module.url(forResource: "compound-mark", withExtension: "svg"))
    let data = try Data(contentsOf: fixtureURL)

    let metrics = try measureRenderMetrics(
        svgData: data,
        iterations: 80,
        options: .init(size: CGSize(width: 240, height: 120))
    )

    #expect(metrics.averageMilliseconds < 15)
    #expect(metrics.residentMemoryDeltaMB < 40)
}

private struct RenderMetrics {
    let averageMilliseconds: Double
    let residentMemoryDeltaMB: Double
}

private func measureRenderMetrics(
    svgData: Data,
    iterations: Int,
    options: VectorImageRasterizationOptions
) throws -> RenderMetrics {
    precondition(iterations > 0)

    let startingResident = residentMemoryBytes()
    let start = ContinuousClock.now

    for _ in 0..<iterations {
        _ = try VectorImageRenderer.render(svgData: svgData, options: options)
    }

    let elapsed = start.duration(to: .now)
    let endingResident = residentMemoryBytes()
    let deltaBytes = max(endingResident - startingResident, 0)

    let elapsedSeconds = Double(elapsed.components.seconds)
        + (Double(elapsed.components.attoseconds) / 1_000_000_000_000_000_000)

    return RenderMetrics(
        averageMilliseconds: elapsedSeconds * 1_000 / Double(iterations),
        residentMemoryDeltaMB: Double(deltaBytes) / 1_048_576
    )
}

private func residentMemoryBytes() -> UInt64 {
#if canImport(Darwin)
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info_data_t>.size) / 4
    let result = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
            task_info(
                mach_task_self_,
                task_flavor_t(MACH_TASK_BASIC_INFO),
                reboundPointer,
                &count
            )
        }
    }

    guard result == KERN_SUCCESS else { return 0 }
    return UInt64(info.resident_size)
#else
    return 0
#endif
}
