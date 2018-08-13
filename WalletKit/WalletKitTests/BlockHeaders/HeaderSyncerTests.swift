import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderSyncerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerGroup: MockPeerGroup!
    private var mockConfiguration: MockConfiguration!
    private var mockNetwork: MockNetworkProtocol!
    private var headerSyncer: HeaderSyncer!

    private var realm: Realm!
    private var checkpointBlock: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockPeerGroup = MockPeerGroup(realmFactory: mockRealmFactory)
        mockConfiguration = MockConfiguration()
        mockNetwork = MockNetworkProtocol()

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        checkpointBlock = TestData.checkpointBlock

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockPeerGroup) { mock in
            when(mock.requestHeaders(headerHashes: any())).thenDoNothing()
        }
        stub(mockConfiguration) { mock in
            when(mock.hashCheckpointThreshold.get).thenReturn(3)
            when(mock.network.get).thenReturn(mockNetwork)
        }
        stub(mockNetwork) { mock in
            when(mock.checkpointBlock.get).thenReturn(checkpointBlock)
        }

        headerSyncer = HeaderSyncer(realmFactory: mockRealmFactory, peerGroup: mockPeerGroup, configuration: mockConfiguration)
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockPeerGroup = nil
        mockNetwork = nil
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
