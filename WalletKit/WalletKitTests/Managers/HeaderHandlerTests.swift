import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderHandlerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockValidator: MockBlockHeaderItemValidator!
    private var mockSaver: MockBlockSaver!
    private var headerHandler: HeaderHandler!

    private var realm: Realm!
    private var initialBlock: Block!
    private var initialItem: BlockHeaderItem!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockBlockHeaderItemValidator()
        mockSaver = MockBlockSaver()
        headerHandler = HeaderHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        initialBlock = Block()
        initialBlock.reversedHeaderHashHex = "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e"
        initialBlock.headerHash = "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e".reversedData!
        initialBlock.height = 2016

        let previousHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176".reversedData!, merkleRoot: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4".reversedData!, timestamp: 1506024043, bits: 453021074, nonce: 1373615473)
        initialBlock.rawHeader = previousHeaderItem.serialized()

        initialItem = BlockHeaderItem.deserialize(byteStream: ByteStream(initialBlock.rawHeader))

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.create(withHeight: any(), fromItems: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockValidator = nil
        mockSaver = nil
        headerHandler = nil

        realm = nil
        initialBlock = nil
        initialItem = nil

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
            when(mock.isValid(item: equal(to: items[0]), previousBlock: equal(to: initialItem))).thenReturn(true)
        }

        headerHandler.handle(blockHeaders: items)
        verify(mockSaver).create(withHeight: equal(to: initialBlock.height), fromItems: equal(to: items))
    }

    func testInvalidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let items = [BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 0, bits: 0, nonce: 0)]

        stub(mockValidator) { mock in
            when(mock.isValid(item: equal(to: items[0]), previousBlock: equal(to: initialItem))).thenReturn(false)
        }

        headerHandler.handle(blockHeaders: items)
        verifyNoMoreInteractions(mockSaver)
    }

    func testPartialValidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let items = [BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 0, bits: 0, nonce: 0),
                     BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 1, bits: 0, nonce: 0),
                     BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 2, bits: 0, nonce: 0)]

        stub(mockValidator) { mock in
            when(mock.isValid(item: equal(to: items[0]), previousBlock: equal(to: initialItem))).thenReturn(true)
            when(mock.isValid(item: equal(to: items[1]), previousBlock: equal(to: items[0]))).thenReturn(true)
            when(mock.isValid(item: equal(to: items[2]), previousBlock: equal(to: items[1]))).thenReturn(false)
        }

        headerHandler.handle(blockHeaders: items)
        verify(mockSaver).create(withHeight: equal(to: initialBlock.height), fromItems: equal(to: [items[0], items[1]]))
    }

}
