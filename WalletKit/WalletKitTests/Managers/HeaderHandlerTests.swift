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

    private var firstCheckPointBlock: Block!

    private var initialBlock: Block!
    private var initialItem: BlockHeaderItem!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockBlockHeaderItemValidator()
        mockSaver = MockBlockSaver()
        headerHandler = HeaderHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        firstCheckPointBlock = Block()
        firstCheckPointBlock.reversedHeaderHashHex = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30"
        firstCheckPointBlock.headerHash = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30".reversedData!
        firstCheckPointBlock.height = 530208

        let headerItem = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000000020c68bfc8de14bc9dd2d6cf45161a67e0c6455cf28cfd8".reversedData!, merkleRoot: "a3f40c28cc6b90b2b1bfaef0e1c394b01dd97786b6a7da5e35f26bc4a7b1e451".reversedData!, timestamp: 1530545661, bits: 389315112, nonce: 630776633)
        firstCheckPointBlock.rawHeader = headerItem.serialized()

        initialBlock = Block()
        initialBlock.reversedHeaderHashHex = "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5"
        initialBlock.headerHash = "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!
        initialBlock.height = 532222

        let previousHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001c2b0214f8ada677b719faa14bb04f03dd231b3624af41".reversedData!, merkleRoot: "5c7238b4ba3638c9622c393e3d61c35a0f1ce2e414e633c3260047b2c6b641cb".reversedData!, timestamp: 1531798356, bits: 389315112, nonce: 1780738424)
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
        try! headerHandler.handle(blockHeaders: [])
        verifyNoMoreInteractions(mockSaver)
    }

    func testSync_NoInitialBlock() {
        let item = BlockHeaderItem(version: 0, prevBlock: Data(), merkleRoot: Data(), timestamp: 0, bits: 0, nonce: 0)
        try! headerHandler.handle(blockHeaders: [item])
        verifyNoMoreInteractions(mockSaver)
    }

    func testValidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let initialPreviousHeight = 532222
        let items = [BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910)]

        stub(mockValidator) { mock in
            when(mock.isValid(item: equal(to: items[0]), previousItem: equal(to: initialItem), previousHeight: initialPreviousHeight)).thenReturn(true)
        }

        try! headerHandler.handle(blockHeaders: items)
        verify(mockSaver).create(withHeight: equal(to: initialBlock.height), fromItems: equal(to: items))
    }

    func testInvalidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let initialPreviousHeight = 532222
        let items = [BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910)]

        stub(mockValidator) { mock in
            when(mock.isValid(item: equal(to: items[0]), previousItem: equal(to: initialItem), previousHeight: initialPreviousHeight)).thenReturn(false)
        }

        try! headerHandler.handle(blockHeaders: items)
        verifyNoMoreInteractions(mockSaver)
    }

    func testPartialValidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let initialPreviousHeight = 532222
        let items = [BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                     BlockHeaderItem(version: 536870912, prevBlock: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0".reversedData!, merkleRoot: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40".reversedData!, timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                     BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000003053b2dad316ce2fc65e8ac63d59d0752d980e43934ad0".reversedData!, merkleRoot: "cbf9b7821ecfb4d5a9cbd9e2bb01729aeecfa6cef3ded7df1e325b6aa3559dae".reversedData!, timestamp: 1531800228, bits: 389437975, nonce: 3500855249)]


        stub(mockValidator) { mock in
            when(mock.isValid(item: equal(to: items[0]), previousItem: equal(to: initialItem), previousHeight: initialPreviousHeight)).thenReturn(true)
            when(mock.isValid(item: equal(to: items[1]), previousItem: equal(to: items[0]), previousHeight: initialPreviousHeight + 1)).thenReturn(true)
            when(mock.isValid(item: equal(to: items[2]), previousItem: equal(to: items[1]), previousHeight: initialPreviousHeight + 2)).thenReturn(false)
        }

        try! headerHandler.handle(blockHeaders: items)
        verify(mockSaver).create(withHeight: equal(to: initialBlock.height), fromItems: equal(to: [items[0], items[1]]))
    }

    func testPartialValidAndWrongCheckPointBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let initialPreviousHeight = 532222
        let items = [BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                     BlockHeaderItem(version: 536870912, prevBlock: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0".reversedData!, merkleRoot: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40".reversedData!, timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                     BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000003053b2dad316ce2fc65e8ac63d59d0752d980e43934ad0".reversedData!, merkleRoot: "cbf9b7821ecfb4d5a9cbd9e2bb01729aeecfa6cef3ded7df1e325b6aa3559dae".reversedData!, timestamp: 1531800228, bits: 389437975, nonce: 3500855249)]


        stub(mockValidator) { mock in
            when(mock.isValid(item: equal(to: items[0]), previousItem: equal(to: initialItem), previousHeight: initialPreviousHeight)).thenReturn(true)
            when(mock.isValid(item: equal(to: items[1]), previousItem: equal(to: items[0]), previousHeight: initialPreviousHeight + 1)).thenThrow(BlockHeaderItemValidator.HeaderValidatorError.noCheckpointBlock)
            when(mock.isValid(item: equal(to: items[2]), previousItem: equal(to: items[1]), previousHeight: initialPreviousHeight + 2)).thenReturn(true)
        }

        var caught = false

        do {
            try headerHandler.handle(blockHeaders: items)
        } catch let error as BlockHeaderItemValidator.HeaderValidatorError {
            caught = true
            XCTAssertEqual(error, BlockHeaderItemValidator.HeaderValidatorError.noCheckpointBlock)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "noCheckpointBlock exception not thrown")

        verify(mockSaver).create(withHeight: equal(to: initialBlock.height), fromItems: equal(to: [items[0]]))
    }

}
