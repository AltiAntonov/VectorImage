import SwiftUI
import Testing
import VectorImageCore
import VectorImageUI

@Test("Environment values provide the default VectorImage configuration")
func environmentValuesProvideDefaultConfiguration() {
    let values = EnvironmentValues()

    #expect(values.vectorImageConfiguration == .default)
}

@Test("Environment values store custom VectorImage configuration")
func environmentValuesStoreCustomConfiguration() {
    let cache = VectorImageCache(countLimit: 12)
    let configuration = VectorImageConfiguration(
        cachePolicy: .enabled(cache),
        inFlightRequestPolicy: .disabled
    )

    var values = EnvironmentValues()
    values.vectorImageConfiguration = configuration

    #expect(values.vectorImageConfiguration == configuration)
}
