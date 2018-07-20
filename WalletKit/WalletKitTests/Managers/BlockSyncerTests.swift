import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class BlockSyncerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerManager: MockPeerManager!
    private var blockSyncer: BlockSyncer!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockPeerManager = MockPeerManager()
        blockSyncer = BlockSyncer(realmFactory: mockRealmFactory, peerManager: mockPeerManager)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockPeerManager) { mock in
            when(mock.requestBlocks(headerHashes: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        blockSyncer = nil
        mockPeerManager = nil
        mockRealmFactory = nil

        realm = nil

        super.tearDown()
    }

    func testSync_NoBlocks() {
        blockSyncer.sync()
        verifyNoMoreInteractions(mockPeerManager)
    }

    func testSync_NonSyncedBlocks() {
        let archivedHash = "00000000000000501c12693a4125d4856737e3827db078c4f44bafd236ee3c51".reversedData!
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        createBlock(hash: archivedHash, height: 1, archived: true, synced: false)
        createBlock(hash: hash, height: 2, archived: false, synced: false)

        blockSyncer.sync()
        verify(mockPeerManager).requestBlocks(headerHashes: equal(to: [archivedHash, hash]))
    }

    func testSync_SyncedBlocks() {
        let syncedHash = "00000000000000501c12693a4125d4856737e3827db078c4f44bafd236ee3c51".reversedData!
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        createBlock(hash: syncedHash, height: 1, archived: true, synced: true)
        createBlock(hash: hash, height: 2, archived: false, synced: false)

        blockSyncer.sync()
        verify(mockPeerManager).requestBlocks(headerHashes: equal(to: [hash]))
    }

    private func createBlock(hash: Data, height: Int, archived: Bool, synced: Bool) {
        let block = Block()
        block.reversedHeaderHashHex = hash.reversedHex
        block.headerHash = hash
        block.height = height
        block.archived = archived
        block.synced = synced

        try! realm.write {
            realm.add(block)
        }
    }

}
