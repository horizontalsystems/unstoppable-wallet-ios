import Testing
import WalletConnectSign
@testable import WalletCore

struct WCSessionNamespacesTests {
    @Test func containsAcceptsSubsetAndRejectsExtension() throws {
        let approved = try WCSessionNamespaces(sessionNamespaces: WCSessionFixtures.session(topic: "t").namespaces)
        let subset = try WCSessionNamespaces(sessionNamespaces: WCSessionFixtures.session(topic: "t", accounts: ["eip155:1:\(WCTestFixtures.address)"], methods: ["personal_sign"]).namespaces)
        let extraChain = try WCSessionNamespaces(sessionNamespaces: WCSessionFixtures.session(topic: "t", accounts: ["eip155:56:\(WCTestFixtures.address)"]).namespaces)
        let extraMethod = try WCSessionNamespaces(sessionNamespaces: WCSessionFixtures.session(topic: "t", methods: ["eth_signTypedData_v4"]).namespaces)
        let otherNamespace = WCSessionNamespaces(namespaces: ["solana": .init(accounts: [], methods: [], events: [])])

        #expect(approved.contains(subset))
        #expect(approved.contains(approved))
        #expect(approved.contains(extraChain) == false)
        #expect(approved.contains(extraMethod) == false)
        #expect(approved.contains(otherNamespace) == false)
    }
}
