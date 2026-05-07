import Testing
@testable import VectorImageMacExample

struct VectorImageMacExampleTests {
    @MainActor
    @Test func sampleDataIsAvailable() {
        #expect(VectorImageExampleData.samples.isEmpty == false)
    }
}
