import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class InitialSyncerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockHDWallet: MockHDWallet!
    private var mockStateManager: MockStateManager!
    private var mockApiManager: MockApiManager!
    private var mockPeerGroup: MockPeerGroup!
    private var syncer: InitialSyncer!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockHDWallet = MockHDWallet(seed: Data(), network: TestNet())
        mockStateManager = MockStateManager(realmFactory: mockRealmFactory)
        mockApiManager = MockApiManager(apiUrl: "")
        mockPeerGroup = MockPeerGroup(realmFactory: mockRealmFactory, network: TestNet())

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockStateManager) { mock in
            when(mock.apiSynced.get).thenReturn(false)
        }
        stub(mockPeerGroup) { mock in
            when(mock.connect()).thenDoNothing()
        }

        syncer = InitialSyncer(realmFactory: mockRealmFactory, hdWallet: mockHDWallet, stateManager: mockStateManager, apiManager: mockApiManager, peerGroup: mockPeerGroup, gapLimit: 2)
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockHDWallet = nil
        mockStateManager = nil
        mockApiManager = nil
        mockPeerGroup = nil
        syncer = nil

        realm = nil

        super.tearDown()
    }

    func testConnectPeerGroupIfAlreadySynced() {
        stub(mockStateManager) { mock in
            when(mock.apiSynced.get).thenReturn(true)
        }

//        try! syncer.sync()

//        verify(mockPeerGroup).connect()
    }

    func testApiSync() {
//        try! syncer.sync()

//        verify(mockPeerGroup, never()).connect()
    }

}
