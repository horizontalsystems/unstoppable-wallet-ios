import Testing
import WalletConnectSign
@testable import WalletCore

struct WCSessionStorageTests {
    @Test func roundTripsApprovedNamespaces() throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: "t1")
        let namespaces = WCSessionNamespaces(sessionNamespaces: session.namespaces)

        try storage.save(session: WCSessionRecord(topic: "t1", accountId: "a1", dAppName: "React App", namespaces: namespaces))

        let stored = try storage.session(topic: "t1")
        let record = try #require(stored)
        #expect(record.accountId == "a1")
        #expect(record.dAppName == "React App")
        let decoded = try record.sessionNamespaces()
        #expect(decoded == namespaces)
        #expect(decoded.accounts == [WCTestFixtures.approvedMainnet, WCTestFixtures.approvedOptimism])
    }

    @Test func filtersByAccountAndDeletes() throws {
        let storage = try WCSessionFixtures.storage()
        let namespaces = try WCSessionNamespaces(sessionNamespaces: WCSessionFixtures.session(topic: "x").namespaces)
        try storage.save(session: WCSessionRecord(topic: "t1", accountId: "a1", dAppName: "d1", namespaces: namespaces))
        try storage.save(session: WCSessionRecord(topic: "t2", accountId: "a2", dAppName: "d2", namespaces: namespaces))
        try storage.save(session: WCSessionRecord(topic: "t3", accountId: "a1", dAppName: "d3", namespaces: namespaces))

        let a1 = try storage.sessions(accountId: "a1").map(\.topic).sorted()
        #expect(a1 == ["t1", "t3"])

        try storage.delete(topics: ["t1"])
        let afterTopicDelete = try storage.sessions().map(\.topic).sorted()
        #expect(afterTopicDelete == ["t2", "t3"])

        try storage.delete(accountId: "a1")
        let afterAccountDelete = try storage.sessions().map(\.topic)
        #expect(afterAccountDelete == ["t2"])
    }

    @Test func topicIsUniqueAcrossAccounts() throws {
        let storage = try WCSessionFixtures.storage()
        let namespaces = try WCSessionNamespaces(sessionNamespaces: WCSessionFixtures.session(topic: "x").namespaces)
        try storage.save(session: WCSessionRecord(topic: "t1", accountId: "a1", dAppName: "d", namespaces: namespaces))
        try storage.save(session: WCSessionRecord(topic: "t1", accountId: "a2", dAppName: "d", namespaces: namespaces))

        let records = try storage.sessions()
        #expect(records.count == 1)
        #expect(records[0].accountId == "a2")
    }
}
