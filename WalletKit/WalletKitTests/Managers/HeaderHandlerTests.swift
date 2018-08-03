import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderHandlerTests: XCTestCase {

    private var mockStorage: MockIStorage!
    private var mockBlockFactory: MockBlockFactory!
    private var mockValidator: MockBlockValidator!
    private var mockSaver: MockBlockSaver!
    private var headerHandler: HeaderHandler!

    private var initialBlock: Block!
    private var initialHeader: BlockHeader!

    override func setUp() {
        super.setUp()

        mockStorage = MockIStorage()
        mockBlockFactory = MockBlockFactory()
        mockValidator = MockBlockValidator()
        mockSaver = MockBlockSaver()
        headerHandler = HeaderHandler(storage: mockStorage, blockFactory: mockBlockFactory, validator: mockValidator, saver: mockSaver)

        let preCheckpointBlock = BlockFactory.shared.block(withHeader: TestHelper.preCheckpointBlockHeader, height: TestHelper.preCheckpointBlockHeight)

        initialHeader = TestHelper.checkpointBlockHeader
        initialBlock = BlockFactory.shared.block(withHeader: initialHeader, previousBlock: preCheckpointBlock)

        stub(mockStorage) { mock in
            when(mock.getLastBlockInChain()).thenReturn(initialBlock)
        }
        stub(mockSaver) { mock in
            when(mock.create(blocks: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockStorage = nil
        mockBlockFactory = nil
        mockValidator = nil
        mockSaver = nil
        headerHandler = nil

        initialBlock = nil
        initialHeader = nil

        super.tearDown()
    }

    func testSync_EmptyItems() {
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
        stub(mockStorage) { mock in
            when(mock.getLastBlockInChain()).thenReturn(nil)
        }

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
        let blocks = [BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                previousBlock: initialBlock
        )]

        stub(mockBlockFactory) { mock in
            when(mock.blocks(fromHeaders: equal(to: blocks.map { $0.header }), initialBlock: equal(to: initialBlock))).thenReturn(blocks)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: blocks[0]))).thenDoNothing()
        }

        try! headerHandler.handle(headers: blocks.map { $0.header })
        verify(mockSaver).create(blocks: equal(to: blocks))
    }

    func testInvalidBlocks() {
        let blocks = [BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                previousBlock: initialBlock
        )]

        stub(mockBlockFactory) { mock in
            when(mock.blocks(fromHeaders: equal(to: blocks.map { $0.header }), initialBlock: equal(to: initialBlock))).thenReturn(blocks)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: blocks[0]))).thenThrow(BlockValidator.ValidatorError.notEqualBits)
        }

        try? headerHandler.handle(headers: blocks.map { $0.header })
        verifyNoMoreInteractions(mockSaver)
    }

    func testPartialValidBlocks() {
        let block1 = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                previousBlock: initialBlock
        )
        let block2 = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                previousBlock: block1
        )
        let block3 = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000003053b2dad316ce2fc65e8ac63d59d0752d980e43934ad0", merkleRootReversedHex: "cbf9b7821ecfb4d5a9cbd9e2bb01729aeecfa6cef3ded7df1e325b6aa3559dae", timestamp: 1531800228, bits: 389437975, nonce: 3500855249),
                previousBlock: block2
        )

        stub(mockBlockFactory) { mock in
            when(mock.blocks(fromHeaders: equal(to: [block1.header, block2.header, block3.header]), initialBlock: equal(to: initialBlock))).thenReturn([block1, block2, block3])
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
