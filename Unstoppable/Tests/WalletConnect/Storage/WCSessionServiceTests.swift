import Combine
import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCSessionServiceTests {
    private let client = WCSpySignClient()
    private let accounts = WCStubAccountProvider(activeAccountId: "a1")

    private func service(storage: WCSessionStorage) -> WCSessionService {
        WCSessionService(signClient: client, storage: storage, accountProvider: accounts)
    }

    @Test func storeBindsTopicToAccountAndPublishes() throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: "t1")
        client.sessions = [session]
        let service = service(storage: storage)

        try service.store(session: session, accountId: "a1")

        #expect(service.sessions.map(\.topic) == ["t1"])
        #expect(service.sessions[0].peer?.name == "React App")
        let storedInfo = try service.sessionInfo(topic: "t1", accountId: "a1")
        let info = try #require(storedInfo)
        #expect(info.approvedAccounts == [WCTestFixtures.approvedMainnet, WCTestFixtures.approvedOptimism])
    }

    @Test func sessionInfoIsHiddenFromOtherAccounts() throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: "t1")
        client.sessions = [session]
        let service = service(storage: storage)
        try service.store(session: session, accountId: "a1")

        let other = try service.sessionInfo(topic: "t1", accountId: "a2")
        #expect(other == nil)
    }

    // bug-bounty #2: deleting the owner account disconnects in the SDK and never re-adopts the topic
    @Test func deletingAccountDisconnectsAndDoesNotRebind() async throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: "t1")
        client.sessions = [session]
        let service = service(storage: storage)
        try service.store(session: session, accountId: "a1")

        accounts.deletedAccountSubject.send("a1")
        try await waitUntil { client.disconnectedTopics == ["t1"] }

        // relay lag: the SDK still lists the topic while account a2 is active
        client.sessions = [session]
        accounts.activeAccountSubject.send("a2")
        service.sync()

        let records = try storage.sessions()
        #expect(records.isEmpty)
        #expect(service.sessions.isEmpty)
        let info = try service.sessionInfo(topic: "t1", accountId: "a2")
        #expect(info == nil)
    }

    @Test func twoDAppsResolveTheirOwnApprovals() throws {
        let storage = try WCSessionFixtures.storage()
        let a = try WCSessionFixtures.session(topic: "tA", accounts: ["eip155:1:\(WCTestFixtures.address)"])
        let b = try WCSessionFixtures.session(topic: "tB", accounts: ["eip155:10:\(WCTestFixtures.address)"])
        client.sessions = [a, b]
        let service = service(storage: storage)
        try service.store(session: a, accountId: "a1")
        try service.store(session: b, accountId: "a1")

        let storedB = try service.sessionInfo(topic: "tB", accountId: "a1")
        let infoB = try #require(storedB)
        #expect(infoB.approvedAccounts == [WCTestFixtures.approvedOptimism])
        #expect(service.sessions.map(\.topic).sorted() == ["tA", "tB"])
    }

    @Test func dAppUpdateDoesNotChangePersistedApproval() throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: "t1", accounts: ["eip155:1:\(WCTestFixtures.address)"])
        client.sessions = [session]
        let service = service(storage: storage)
        try service.store(session: session, accountId: "a1")

        let extended = try WCSessionFixtures.session(topic: "t1", accounts: ["eip155:1:\(WCTestFixtures.address)", "eip155:56:\(WCTestFixtures.address)"])
        client.sessionUpdateSubject.send((topic: "t1", namespaces: extended.namespaces))

        let updatedInfo = try service.sessionInfo(topic: "t1", accountId: "a1")
        let info = try #require(updatedInfo)
        #expect(info.approvedAccounts == [WCTestFixtures.approvedMainnet])
    }

    @Test func syncDropsRecordsUnknownToSdkAndIgnoresUnapprovedSessions() throws {
        let storage = try WCSessionFixtures.storage()
        let stored = try WCSessionFixtures.session(topic: "t1")
        let foreign = try WCSessionFixtures.session(topic: "t2")
        client.sessions = [stored]
        let service = service(storage: storage)
        try service.store(session: stored, accountId: "a1")

        client.sessions = [foreign]

        let records = try storage.sessions()
        #expect(records.isEmpty)
        #expect(service.sessions.isEmpty)
    }

    @Test func userDisconnectRemovesSessionEverywhere() async throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: "t1")
        client.sessions = [session]
        let service = service(storage: storage)
        try service.store(session: session, accountId: "a1")

        try await service.disconnect(topic: "t1")

        #expect(client.disconnectedTopics == ["t1"])
        let records = try storage.sessions()
        #expect(records.isEmpty)
        #expect(service.sessions.isEmpty)
    }

    @Test func switchingAccountChangesVisibleSessions() throws {
        let storage = try WCSessionFixtures.storage()
        let a = try WCSessionFixtures.session(topic: "tA")
        let b = try WCSessionFixtures.session(topic: "tB")
        client.sessions = [a, b]
        let service = service(storage: storage)
        try service.store(session: a, accountId: "a1")
        try service.store(session: b, accountId: "a2")

        #expect(service.sessions.map(\.topic) == ["tA"])
        accounts.activeAccountSubject.send("a2")
        #expect(service.sessions.map(\.topic) == ["tB"])
    }

    private func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(condition())
    }
}
