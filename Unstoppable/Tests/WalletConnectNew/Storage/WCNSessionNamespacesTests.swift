import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNSessionNamespacesTests {
    @Test func containsAcceptsSubsetAndRejectsExtension() throws {
        let approved = try WCNSessionNamespaces(sessionNamespaces: WCNSessionFixtures.session(topic: "t").namespaces)
        let subset = try WCNSessionNamespaces(sessionNamespaces: WCNSessionFixtures.session(topic: "t", accounts: ["eip155:1:\(WCNTestFixtures.address)"], methods: ["personal_sign"]).namespaces)
        let extraChain = try WCNSessionNamespaces(sessionNamespaces: WCNSessionFixtures.session(topic: "t", accounts: ["eip155:56:\(WCNTestFixtures.address)"]).namespaces)
        let extraMethod = try WCNSessionNamespaces(sessionNamespaces: WCNSessionFixtures.session(topic: "t", methods: ["eth_signTypedData_v4"]).namespaces)
        let otherNamespace = WCNSessionNamespaces(namespaces: ["solana": .init(accounts: [], methods: [], events: [])])

        #expect(approved.contains(subset))
        #expect(approved.contains(approved))
        #expect(approved.contains(extraChain) == false)
        #expect(approved.contains(extraMethod) == false)
        #expect(approved.contains(otherNamespace) == false)
    }
}
