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
    private var initialHeader: BlockHeader!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockBlockHeaderItemValidator()
        mockSaver = MockBlockSaver()
        headerHandler = HeaderHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        let preCheckpointBlock = Block(header: TestHelper.preCheckpointBlockHeader, height: TestHelper.preCheckpointBlockHeight)
        try! realm.write {
            realm.add(preCheckpointBlock)
        }

        initialHeader = TestHelper.checkpointBlockHeader
        initialBlock = Block(header: initialHeader, previousBlock: preCheckpointBlock)

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.create(blocks: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockValidator = nil
        mockSaver = nil
        headerHandler = nil

        realm = nil
        initialBlock = nil
        initialHeader = nil

        super.tearDown()
    }

    func testSync_EmptyItems() {
        try! realm.write { realm.add(initialBlock) }
        try! headerHandler.handle(headers: [])
        verifyNoMoreInteractions(mockSaver)
    }

    func testSync_NoInitialBlock() {
        let header = BlockHeader()
        try! headerHandler.handle(headers: [header])
        verifyNoMoreInteractions(mockSaver)
    }

    func testValidBlocks() {
//        try! realm.write { realm.add(initialBlock) }
//
//        let headers = [BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910)]
//
//        stub(mockValidator) { mock in
//            when(mock.validate(block: equal(to: headers[0]))).thenDoNothing()
//        }
//
//        try! headerHandler.handle(headers: headers)
//        verify(mockSaver).create(withPreviousBlock: equal(to: initialBlock), fromHeaders: equal(to: headers))
    }

    func testInvalidBlocks() {
//        try! realm.write { realm.add(initialBlock) }
//
//        let headers = [BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910)]
//
//        stub(mockValidator) { mock in
//            when(mock.validate(header: equal(to: headers[0]), previousHeader: equal(to: initialHeader), previousHeight: initialBlock.height)).thenThrow(BlockHeaderItemValidator.HeaderValidatorError.notEqualBits)
//        }
//
//        try? headerHandler.handle(headers: headers)
//        verifyNoMoreInteractions(mockSaver)
    }

    func testPartialValidBlocks() {
//        try! realm.write { realm.add(initialBlock) }
//
//        let headers = [BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
//                       BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
//                       BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000003053b2dad316ce2fc65e8ac63d59d0752d980e43934ad0", merkleRootReversedHex: "cbf9b7821ecfb4d5a9cbd9e2bb01729aeecfa6cef3ded7df1e325b6aa3559dae", timestamp: 1531800228, bits: 389437975, nonce: 3500855249)]
//
//
//        stub(mockValidator) { mock in
//            when(mock.validate(header: equal(to: headers[0]), previousHeader: equal(to: initialHeader), previousHeight: initialBlock.height)).thenDoNothing()
//            when(mock.validate(header: equal(to: headers[1]), previousHeader: equal(to: headers[0]), previousHeight: initialBlock.height + 1)).thenDoNothing()
//            when(mock.validate(header: equal(to: headers[2]), previousHeader: equal(to: headers[1]), previousHeight: initialBlock.height + 2)).thenThrow(BlockHeaderItemValidator.HeaderValidatorError.notEqualBits)
//        }
//
//        try? headerHandler.handle(headers: headers)
//        verify(mockSaver).create(withPreviousBlock: equal(to: initialBlock), fromHeaders: equal(to: [headers[0], headers[1]]))
    }

}
