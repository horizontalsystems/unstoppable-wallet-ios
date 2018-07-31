import XCTest
import Cuckoo
import RealmSwift
import RxSwift
@testable import WalletKit

class BlockSyncerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerManager: MockPeerManager!
    private var blockSyncer: BlockSyncer!

    private var realm: Realm!
    private var peerStatusSubject: PublishSubject<PeerManager.Status>!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockPeerManager = MockPeerManager()

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        peerStatusSubject = PublishSubject()

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockPeerManager) { mock in
            when(mock.requestBlocks(headerHashes: any())).thenDoNothing()
            when(mock.statusSubject.get).thenReturn(peerStatusSubject)
        }

        blockSyncer = BlockSyncer(realmFactory: mockRealmFactory, peerManager: mockPeerManager, scheduler: MainScheduler.instance, queue: .main)
    }

    override func tearDown() {
        blockSyncer = nil
        mockPeerManager = nil
        mockRealmFactory = nil

        realm = nil
        peerStatusSubject = nil

        super.tearDown()
    }

    func testSync_NoBlocks() {
        peerStatusSubject.onNext(.connected)
        verify(mockPeerManager, never()).requestBlocks(headerHashes: any())
    }

    func testSync_NonSyncedBlocks() {
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        try! realm.write {
            realm.create(Block.self, value: ["reversedHeaderHashHex": hash.reversedHex, "headerHash": hash, "height": 2, "synced": false], update: true)
        }

        peerStatusSubject.onNext(.connected)
        verify(mockPeerManager).requestBlocks(headerHashes: equal(to: [hash]))
    }

    func testSync_OnDisconnect() {
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        try! realm.write {
            realm.create(Block.self, value: ["reversedHeaderHashHex": hash.reversedHex, "headerHash": hash, "height": 1, "synced": false], update: true)
        }

        peerStatusSubject.onNext(.disconnected)
        verify(mockPeerManager, never()).requestBlocks(headerHashes: any())
    }

    func testSync_SyncedBlocks() {
        let syncedHash = "00000000000000501c12693a4125d4856737e3827db078c4f44bafd236ee3c51".reversedData!
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        try! realm.write {
            realm.create(Block.self, value: ["reversedHeaderHashHex": syncedHash.reversedHex, "headerHash": syncedHash, "height": 1, "synced": true], update: true)
            realm.create(Block.self, value: ["reversedHeaderHashHex": hash.reversedHex, "headerHash": hash, "height": 2, "synced": false], update: true)
        }

        peerStatusSubject.onNext(.connected)
        verify(mockPeerManager).requestBlocks(headerHashes: equal(to: [hash]))
    }

    func testSync_Observe() {
        peerStatusSubject.onNext(.connected)

        let syncedHash = "00000000000000501c12693a4125d4856737e3827db078c4f44bafd236ee3c51".reversedData!
        let hash1 = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!
        let hash2 = "000000000000002d7b058a413cda4de7c54ba3ce7836fe75569f908635679afe".reversedData!

        let e = expectation(description: "Realm Observer")

        let token = realm.objects(Block.self).filter("synced = %@", false).observe { changes in
            if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                e.fulfill()
            }
        }

        try! realm.write {
            realm.create(Block.self, value: ["reversedHeaderHashHex": syncedHash.reversedHex, "headerHash": syncedHash, "height": 1, "synced": true], update: true)
            realm.create(Block.self, value: ["reversedHeaderHashHex": hash1.reversedHex, "headerHash": hash1, "height": 2, "synced": false], update: true)
            realm.create(Block.self, value: ["reversedHeaderHashHex": hash2.reversedHex, "headerHash": hash2, "height": 3, "synced": false], update: true)
        }

        waitForExpectations(timeout: 2)
        verify(self.mockPeerManager).requestBlocks(headerHashes: equal(to: [hash1, hash2]))

        token.invalidate()
    }

}
