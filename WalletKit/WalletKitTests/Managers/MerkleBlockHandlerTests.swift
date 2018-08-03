import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class MerkleBlockHandlerTests: XCTestCase {
    private var mockStorage: MockIStorage!
    private var mockValidator: MockMerkleBlockValidator!
    private var mockSaver: MockBlockSaver!
    private var merkleBlockHandler: MerkleBlockHandler!

    private var realm: Realm!
    private var block: Block!
    private var blockHeader: BlockHeader!
    private var sampleMerkleBlockMessage: MerkleBlockMessage!

    override func setUp() {
        super.setUp()

        mockStorage = MockIStorage()
        mockValidator = MockMerkleBlockValidator()
        mockSaver = MockBlockSaver()
        merkleBlockHandler = MerkleBlockHandler(storage: mockStorage, validator: mockValidator, saver: mockSaver)

        block = Block()
        block.headerHash = "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176".reversedData!
        block.height = 2016

        blockHeader = BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92", merkleRootReversedHex: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a", timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
        sampleMerkleBlockMessage = MerkleBlockMessage(blockHeader: blockHeader, totalTransactions: 1, numberOfHashes: 1, hashes: [Data(hex: "0000000000000000000000000000000000000000000000000000000000000001")!], numberOfFlags: 0, flags: [])

        stub(mockStorage) { mock in
            when(mock.getBlock(byHeaderHash: equal(to: block.headerHash))).thenReturn(block)
        }
        stub(mockSaver) { mock in
            when(mock.update(block: any(), withTransactionHashes: any())).thenDoNothing()
        }
        stub(mockValidator) { mock in
            when(mock.txIds).get.thenReturn(sampleMerkleBlockMessage.hashes)
        }
    }

    override func tearDown() {
        mockStorage = nil
        mockValidator = nil
        mockSaver = nil
        merkleBlockHandler = nil

        block = nil
        blockHeader = nil
        sampleMerkleBlockMessage = nil

        super.tearDown()
    }

    func testValidMerkleBlock() {
        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleMerkleBlockMessage))).thenDoNothing()
        }

        try! merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        verify(mockSaver).update(block: equal(to: block), withTransactionHashes: equal(to: sampleMerkleBlockMessage.hashes))
    }

    func testInvalidMerkleBlocks() {
        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleMerkleBlockMessage))).thenThrow(MerkleBlockValidator.ValidationError.wrongMerkleRoot)
        }

        try? merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        verifyNoMoreInteractions(mockSaver)
    }

    func testSync_NoBlock() {
        stub(mockStorage) { mock in
            when(mock.getBlock(byHeaderHash: equal(to: block.headerHash))).thenReturn(nil)
        }

        var caught = false

        do {
            try merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        } catch let error as MerkleBlockHandler.HandleError {
            caught = true
            XCTAssertEqual(error, MerkleBlockHandler.HandleError.blockNotFound)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        verifyNoMoreInteractions(mockSaver)
        XCTAssertTrue(caught, "blockNotFound exception not thrown")
    }

    func testNoMatchedHashes() {
        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleMerkleBlockMessage))).thenDoNothing()
            when(mock.txIds).get.thenReturn([])
        }

        try! merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        verify(mockSaver).update(block: equal(to: block), withTransactionHashes: equal(to: []))
    }

}
