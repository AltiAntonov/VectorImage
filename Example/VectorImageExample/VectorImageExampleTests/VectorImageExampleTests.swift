import Testing
@testable import VectorImageExample

struct VectorImageExampleTests {
    @MainActor
    @Test func sampleDataIsAvailable() {
        #expect(VectorImageExampleData.samples.isEmpty == false)
    }
}
