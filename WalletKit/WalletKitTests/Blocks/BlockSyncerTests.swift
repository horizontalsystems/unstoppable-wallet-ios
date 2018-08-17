import XCTest
import Cuckoo
import RealmSwift
import RxSwift
@testable import WalletKit

class BlockSyncerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerGroup: MockPeerGroup!
    private var blockSyncer: BlockSyncer!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockPeerGroup = MockPeerGroup(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockPeerGroup) { mock in
            when(mock.requestBlocks(headerHashes: any())).thenDoNothing()
        }

        blockSyncer = BlockSyncer(realmFactory: mockRealmFactory, peerGroup: mockPeerGroup, queue: DispatchQueue.main)
    }

    override func tearDown() {
        blockSyncer = nil
        mockPeerGroup = nil
        mockRealmFactory = nil

        realm = nil

        super.tearDown()
    }

    func testSync_NoBlocks() {
        blockSyncer.enqueueRun()
        waitForMainQueue()

        verify(mockPeerGroup, never()).requestBlocks(headerHashes: any())
    }

    func testSync_NonSyncedBlocks() {
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        try! realm.write {
            realm.create(Block.self, value: ["reversedHeaderHashHex": hash.reversedHex, "headerHash": hash, "height": 2, "synced": false], update: true)
        }

        blockSyncer.enqueueRun()
        waitForMainQueue()

        verify(mockPeerGroup).requestBlocks(headerHashes: equal(to: [hash]))
    }

    func testSync_SyncedBlocks() {
        let syncedHash = "00000000000000501c12693a4125d4856737e3827db078c4f44bafd236ee3c51".reversedData!
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        try! realm.write {
            realm.create(Block.self, value: ["reversedHeaderHashHex": syncedHash.reversedHex, "headerHash": syncedHash, "height": 1, "synced": true], update: true)
            realm.create(Block.self, value: ["reversedHeaderHashHex": hash.reversedHex, "headerHash": hash, "height": 2, "synced": false], update: true)
        }

        blockSyncer.enqueueRun()
        waitForMainQueue()

        verify(mockPeerGroup).requestBlocks(headerHashes: equal(to: [hash]))
    }

}
