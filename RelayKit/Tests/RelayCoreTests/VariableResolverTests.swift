import Testing
import Foundation
@testable import RelayCore

@Suite("VariableResolver")
struct VariableResolverTests {

    @Test("Resolves built-in path and identity variables")
    func resolvesBuiltins() async {
        let resolver = VariableResolver()
        let resolved = await resolver.resolve("cd $Home && whoami")
        #expect(resolved.contains(NSHomeDirectory()))
        #expect(!resolved.contains("$Home"))
    }

    @Test("Resolves Date with a fixed clock")
    func resolvesDate() async {
        let fixed = Date(timeIntervalSince1970: 0)   // 1970-01-01
        let resolver = VariableResolver(now: { fixed })
        let resolved = await resolver.resolve("echo $Date")
        #expect(resolved.contains("1970-01-01"))
    }

    @Test("Resolves custom variables and leaves unknowns intact")
    func customAndUnknown() async {
        let resolver = VariableResolver(custom: ["NAS": "/Volumes/Media"])
        let resolved = await resolver.resolve("cp file $NAS/$Unknown")
        #expect(resolved.contains("/Volumes/Media"))
        #expect(resolved.contains("$Unknown"))   // untouched
    }

    @Test("Clipboard comes from the injected system context")
    func clipboardFromContext() async {
        struct Ctx: SystemContextProviding {
            func clipboardString() async -> String { "pasted" }
            func selectedFinderPaths() async -> [String] { [] }
            func currentFinderFolder() async -> String? { nil }
        }
        let resolver = VariableResolver(context: Ctx())
        #expect(await resolver.resolve("echo $Clipboard") == "echo pasted")
    }
}
