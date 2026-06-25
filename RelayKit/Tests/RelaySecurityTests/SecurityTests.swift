import Testing
import Foundation
@testable import RelaySecurity

@Suite("Security")
struct SecurityTests {

    @Test("Touch ID sudo status returns a defined value")
    func touchIDStatusDefined() {
        let status = SudoDetector().touchIDStatus()
        #expect([.enabled, .notConfigured, .unknown].contains(status))
    }

    @Test("Privileged operations are a small, named, parameterless set")
    func curatedOperations() {
        // The security model depends on operations being fixed and free of arbitrary input.
        #expect(!PrivilegedOperation.allCases.isEmpty)
        for op in PrivilegedOperation.allCases {
            #expect(!op.summary.isEmpty)
        }
    }

    @Test("Privileged operations are codable for XPC transport")
    func operationsCodable() throws {
        for op in PrivilegedOperation.allCases {
            let data = try JSONEncoder().encode(op)
            let decoded = try JSONDecoder().decode(PrivilegedOperation.self, from: data)
            #expect(decoded == op)
        }
    }

    @Test("Helper perform fails safely when not installed")
    func helperUnavailable() async {
        let client = ServiceManagementHelperClient()
        await #expect(throws: PrivilegedHelperError.self) {
            try await client.perform(.flushDNSCache)
        }
    }
}
