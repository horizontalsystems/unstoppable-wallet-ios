import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderHandlerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockCreator: MockBlockCreator!
    private var mockValidator: MockBlockValidator!
    private var mockSaver: MockBlockSaver!
    private var headerHandler: HeaderHandler!

    private var realm: Realm!

    private var initialBlock: Block!
    private var initialHeader: BlockHeader!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockCreator = MockBlockCreator()
        mockValidator = MockBlockValidator()
        mockSaver = MockBlockSaver()
        headerHandler = HeaderHandler(realmFactory: mockRealmFactory, creator: mockCreator, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        let preCheckpointBlock = BlockCreator.shared.create(withHeader: TestHelper.preCheckpointBlockHeader, height: TestHelper.preCheckpointBlockHeight)
        try! realm.write {
            realm.add(preCheckpointBlock)
        }

        initialHeader = TestHelper.checkpointBlockHeader
        initialBlock = BlockCreator.shared.create(withHeader: initialHeader, previousBlock: preCheckpointBlock)

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.create(blocks: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockCreator = nil
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

        var caught = false

        do {
            try headerHandler.handle(headers: [])
        } catch let error as HeaderHandler.HandleError {
            caught = true
            XCTAssertEqual(error, HeaderHandler.HandleError.emptyHeaders)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        verifyNoMoreInteractions(mockSaver)
        XCTAssertTrue(caught, "emptyHeaders exception not thrown")
    }

    func testSync_NoInitialBlock() {
        var caught = false

        do {
            let header = BlockHeader()
            try headerHandler.handle(headers: [header])
        } catch let error as HeaderHandler.HandleError {
            caught = true
            XCTAssertEqual(error, HeaderHandler.HandleError.noInitialBlock)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        verifyNoMoreInteractions(mockSaver)
        XCTAssertTrue(caught, "noInitialBlock exception not thrown")
    }

    func testValidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let blocks = [BlockCreator.shared.create(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                previousBlock: initialBlock
        )]

        stub(mockCreator) { mock in
            when(mock.create(fromHeaders: equal(to: blocks.map { $0.header }), initialBlock: equal(to: initialBlock))).thenReturn(blocks)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: blocks[0]))).thenDoNothing()
        }

        try! headerHandler.handle(headers: blocks.map { $0.header })
        verify(mockSaver).create(blocks: equal(to: blocks))
    }

    func testInvalidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let blocks = [BlockCreator.shared.create(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                previousBlock: initialBlock
        )]

        stub(mockCreator) { mock in
            when(mock.create(fromHeaders: equal(to: blocks.map { $0.header }), initialBlock: equal(to: initialBlock))).thenReturn(blocks)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: blocks[0]))).thenThrow(BlockValidator.ValidatorError.notEqualBits)
        }

        try? headerHandler.handle(headers: blocks.map { $0.header })
        verifyNoMoreInteractions(mockSaver)
    }

    func testPartialValidBlocks() {
        try! realm.write { realm.add(initialBlock) }

        let block1 = BlockCreator.shared.create(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                previousBlock: initialBlock
        )
        let block2 = BlockCreator.shared.create(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                previousBlock: block1
        )
        let block3 = BlockCreator.shared.create(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000003053b2dad316ce2fc65e8ac63d59d0752d980e43934ad0", merkleRootReversedHex: "cbf9b7821ecfb4d5a9cbd9e2bb01729aeecfa6cef3ded7df1e325b6aa3559dae", timestamp: 1531800228, bits: 389437975, nonce: 3500855249),
                previousBlock: block2
        )

        stub(mockCreator) { mock in
            when(mock.create(fromHeaders: equal(to: [block1.header, block2.header, block3.header]), initialBlock: equal(to: initialBlock))).thenReturn([block1, block2, block3])
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: block1))).thenDoNothing()
            when(mock.validate(block: equal(to: block2))).thenDoNothing()
            when(mock.validate(block: equal(to: block3))).thenThrow(BlockValidator.ValidatorError.notEqualBits)
        }

        try? headerHandler.handle(headers: [block1.header, block2.header, block3.header])
        verify(mockSaver).create(blocks: equal(to: [block1, block2]))
    }

}
