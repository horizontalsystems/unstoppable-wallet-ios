import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderSyncerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerManager: MockPeerManager!
    private var headerSyncer: HeaderSyncer!

    private var realm: Realm!
    private var initialBlock: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockPeerManager = MockPeerManager()
        headerSyncer = HeaderSyncer(realmFactory: mockRealmFactory, peerManager: mockPeerManager)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        initialBlock = Block()
        initialBlock.reversedHeaderHashHex = "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e"
        initialBlock.height = 2016

        let archivedBlock = Block()
        archivedBlock.reversedHeaderHashHex = "0000000000024131acaefe1b3a287865ea9a95cdc797488d6ba4592428804479"
        archivedBlock.height = 500
        archivedBlock.archived = true

        try! realm.write {
            realm.add(archivedBlock)
        }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockPeerManager) { mock in
            when(mock.requestHeaders(headerHashes: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        headerSyncer = nil
        mockPeerManager = nil
        mockRealmFactory = nil

        realm = nil
        initialBlock = nil

        super.tearDown()
    }

    func testSync_NoInitialBlock() {
        headerSyncer.sync()
        verifyNoMoreInteractions(mockPeerManager)
    }

    func testSync_OnlyInitialBlock() {
        try! realm.write {
            realm.add(initialBlock)
        }

        headerSyncer.sync()
        verify(mockPeerManager).requestHeaders(headerHashes: equal(to: [initialBlock.reversedHeaderHashHex.reversedData!]))
    }

    func testSync_99LastBlocks() {
        try! realm.write {
            realm.add(initialBlock)
        }

        let lastReversedHex = "000000000005c9a9d1e992f46bf0c0400a45feeb39d634e0a3cdde08c3b9f512"

        for i in 1...98 {
            createBlock(reversedHex: "\(2016 + i)", height: 2016 + i)
        }
        createBlock(reversedHex: lastReversedHex, height: 2016 + 99)

        headerSyncer.sync()
        verify(mockPeerManager).requestHeaders(headerHashes: equal(to: [lastReversedHex.reversedData!, initialBlock.reversedHeaderHashHex.reversedData!]))
    }

    func testSync_100LastBlocks() {
        try! realm.write {
            realm.add(initialBlock)
        }

        let firstReversedHex = "0000000000012d1d8525ce2db0abdb3617203ccd8485ecad81e37e5a228f7036"
        let lastReversedHex = "000000000005c9a9d1e992f46bf0c0400a45feeb39d634e0a3cdde08c3b9f512"

        createBlock(reversedHex: firstReversedHex, height: 2017)
        for i in 2...99 {
            createBlock(reversedHex: "\(2016 + i)", height: 2016 + i)
        }
        createBlock(reversedHex: lastReversedHex, height: 2016 + 100)

        headerSyncer.sync()
        verify(mockPeerManager).requestHeaders(headerHashes: equal(to: [lastReversedHex.reversedData!, firstReversedHex.reversedData!]))
    }

    private func createBlock(reversedHex: String, height: Int) {
        let block = Block()
        block.reversedHeaderHashHex = reversedHex
        block.height = height

        try! realm.write {
            realm.add(block)
        }
    }

}
