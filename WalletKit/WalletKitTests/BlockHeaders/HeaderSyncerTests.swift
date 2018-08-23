import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderSyncerTests: XCTestCase {

    private var mockPeerGroup: MockPeerGroup!
    private var headerSyncer: HeaderSyncer!

    private var realm: Realm!
    private var checkpointBlock: Block!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        mockPeerGroup = mockWalletKit.mockPeerGroup
        realm = mockWalletKit.mockRealm

        checkpointBlock = TestData.checkpointBlock

        stub(mockPeerGroup) { mock in
            when(mock.requestHeaders(headerHashes: any())).thenDoNothing()
        }

        let mockNetwork = mockWalletKit.mockNetwork
        stub(mockNetwork) { mock in
            when(mock.checkpointBlock.get).thenReturn(checkpointBlock)
        }

        headerSyncer = HeaderSyncer(realmFactory: mockWalletKit.mockRealmFactory, peerGroup: mockPeerGroup, network: mockNetwork, hashCheckpointThreshold: 3)
    }

    override func tearDown() {
        mockPeerGroup = nil
        headerSyncer = nil

        realm = nil
        checkpointBlock = nil

        super.tearDown()
    }

    func testSync_NoBlocksInRealm() {
        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [checkpointBlock.headerHash]))
    }

    func testSync_NoBlocksInChain() {
        try! realm.write {
            realm.add(TestData.oldBlock)
        }

        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [checkpointBlock.headerHash]))
    }

    func testSync_SingleBlockInChain() {
        let firstBlock = TestData.firstBlock

        try! realm.write {
            realm.add(firstBlock)
        }

        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [firstBlock.headerHash, checkpointBlock.headerHash]))
    }

    func testSync_SeveralBlocksInChain() {
        let thirdBlock = TestData.thirdBlock

        try! realm.write {
            realm.add(thirdBlock)
        }

        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [thirdBlock.headerHash, checkpointBlock.headerHash]))
    }

    func testSync_MoreThanThreshold() {
        let forthBlock = TestData.forthBlock
        let firstBlock = forthBlock.previousBlock!.previousBlock!.previousBlock!

        try! realm.write {
            realm.add(forthBlock)
        }

        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [forthBlock.headerHash, firstBlock.headerHash]))
    }

}
