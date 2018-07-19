import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderHandlerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockValidator: MockBlockHeaderItemValidator!
    private var mockSaver: MockBlockHeaderItemSaver!
    private var headerHandler: HeaderHandler!

    private var realm: Realm!
    private var initialBlock: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockBlockHeaderItemValidator()
        mockSaver = MockBlockHeaderItemSaver()
        headerHandler = HeaderHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        initialBlock = Block()
        initialBlock.reversedHeaderHashHex = "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e"
        initialBlock.headerHash = "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e".reversedData!
        initialBlock.height = 2016

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.save(lastHeight: any(), items: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockValidator = nil
        mockSaver = nil
        headerHandler = nil

        realm = nil
        initialBlock = nil

        super.tearDown()
    }

    func testSync_EmptyItems() {
        try! realm.write { realm.add(initialBlock) }
        headerHandler.handle(blockHeaders: [])
        verifyNoMoreInteractions(mockSaver)
    }

    func testSync_NoInitialBlock() {
        let item = BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 0, bits: 0, nonce: 0)
        headerHandler.handle(blockHeaders: [item])
        verifyNoMoreInteractions(mockSaver)
    }

    func testValidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let items = [BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 0, bits: 0, nonce: 0)]

        stub(mockValidator) { mock in
            when(mock.filterValidItems(initialHash: equal(to: initialBlock.headerHash), items: equal(to: items))).thenReturn(items)
        }

        headerHandler.handle(blockHeaders: items)
        verify(mockSaver).save(lastHeight: equal(to: initialBlock.height), items: equal(to: items))
    }

    func testInvalidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let items = [BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 0, bits: 0, nonce: 0)]

        stub(mockValidator) { mock in
            when(mock.filterValidItems(initialHash: equal(to: initialBlock.headerHash), items: equal(to: items))).thenReturn([])
        }

        headerHandler.handle(blockHeaders: items)
        verifyNoMoreInteractions(mockSaver)
    }

}
