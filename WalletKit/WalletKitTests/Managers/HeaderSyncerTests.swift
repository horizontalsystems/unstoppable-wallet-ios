import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderSyncerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerManager: MockPeerManager!
    private var headerSyncer: HeaderSyncer!

    private var realm: Realm!
    private var checkpointBlock: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockPeerManager = MockPeerManager()
        headerSyncer = HeaderSyncer(realmFactory: mockRealmFactory, peerManager: mockPeerManager)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        let preCheckpointBlock = Block(header: TestHelper.preCheckpointBlockHeader, height: TestHelper.preCheckpointBlockHeight)
        try! realm.write {
            realm.add(preCheckpointBlock)
        }

        checkpointBlock = Block(header: TestHelper.checkpointBlockHeader, previousBlock: preCheckpointBlock)

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
        checkpointBlock = nil

        super.tearDown()
    }

    func testSync_NoCheckpointBlock() {
        var caught = false

        do {
            try headerSyncer.sync()
        } catch let error as HeaderSyncer.SyncError {
            caught = true
            XCTAssertEqual(error, HeaderSyncer.SyncError.noCheckpointBlock)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        verifyNoMoreInteractions(mockPeerManager)
        XCTAssertTrue(caught, "noCheckpointBlock exception not thrown")
    }

    func testSync_OnlyCheckpointBlock() {
        try! realm.write {
            realm.add(checkpointBlock)
        }

        try! headerSyncer.sync()
        verify(mockPeerManager).requestHeaders(headerHashes: equal(to: [checkpointBlock.headerHash]))
    }

    func testSync_99LastBlocks() {
        try! realm.write {
            realm.add(checkpointBlock)
        }

        let lastReversedHex = "000000000005c9a9d1e992f46bf0c0400a45feeb39d634e0a3cdde08c3b9f512"

        var previousBlock = checkpointBlock
        for i in 1...98 {
            previousBlock = createBlock(reversedHex: "\(2016 + i)", previousBlock: previousBlock!)
        }
        _ = createBlock(reversedHex: lastReversedHex, previousBlock: previousBlock!)

        try! headerSyncer.sync()
        verify(mockPeerManager).requestHeaders(headerHashes: equal(to: [lastReversedHex.reversedData!, checkpointBlock.headerHash]))
    }

    func testSync_100LastBlocks() {
        try! realm.write {
            realm.add(checkpointBlock)
        }

        let firstReversedHex = "0000000000012d1d8525ce2db0abdb3617203ccd8485ecad81e37e5a228f7036"
        let lastReversedHex = "000000000005c9a9d1e992f46bf0c0400a45feeb39d634e0a3cdde08c3b9f512"

        var previousBlock = createBlock(reversedHex: firstReversedHex, previousBlock: checkpointBlock)
        for i in 2...99 {
            previousBlock = createBlock(reversedHex: "\(2016 + i)", previousBlock: previousBlock)
        }
        _ = createBlock(reversedHex: lastReversedHex, previousBlock: previousBlock)

        try! headerSyncer.sync()
        verify(mockPeerManager).requestHeaders(headerHashes: equal(to: [lastReversedHex.reversedData!, firstReversedHex.reversedData!]))
    }

    private func createBlock(reversedHex: String, previousBlock: Block) -> Block {
        let block = Block()
        block.reversedHeaderHashHex = reversedHex
        block.headerHash = reversedHex.reversedData!
        block.previousBlock = previousBlock
        block.height = previousBlock.height + 1

        try! realm.write {
            realm.add(block)
        }

        return block
    }

}
