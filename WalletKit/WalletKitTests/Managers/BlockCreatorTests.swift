import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class BlockCreatorTests: XCTestCase {

    private var creator: BlockCreator!

    override func setUp() {
        super.setUp()

        creator = BlockCreator()
    }

    override func tearDown() {
        creator = nil

        super.tearDown()
    }

    func testCreateWithPreviousBlock() {
        let previousBlock = Block()
        previousBlock.height = 1
        let header = TestHelper.checkpointBlockHeader
        let headerHash = Crypto.sha256sha256(header.serialized())

        let block = creator.create(withHeader: header, previousBlock: previousBlock)

        XCTAssertEqual(block.header, header)
        XCTAssertEqual(block.previousBlock, previousBlock)
        XCTAssertEqual(block.height, 2)
        XCTAssertEqual(block.headerHash, headerHash)
        XCTAssertEqual(block.reversedHeaderHashHex, headerHash.reversedHex)
    }

    func testCreateWithHeight() {
        let height = 1
        let header = TestHelper.checkpointBlockHeader
        let headerHash = Crypto.sha256sha256(header.serialized())

        let block = creator.create(withHeader: header, height: height)

        XCTAssertEqual(block.header, header)
        XCTAssertEqual(block.previousBlock, nil)
        XCTAssertEqual(block.height, height)
        XCTAssertEqual(block.headerHash, headerHash)
        XCTAssertEqual(block.reversedHeaderHashHex, headerHash.reversedHex)
    }

    func testCreateFromHeaders() {
        let initialBlock = Block()
        initialBlock.height = 1

        let header1 = TestHelper.checkpointBlockHeader
        let header2 = TestHelper.preCheckpointBlockHeader
        let headerHash1 = Crypto.sha256sha256(header1.serialized())
        let headerHash2 = Crypto.sha256sha256(header2.serialized())

        let blocks = creator.create(fromHeaders: [header1, header2], initialBlock: initialBlock)

        XCTAssertEqual(blocks[0].header, header1)
        XCTAssertEqual(blocks[0].previousBlock, initialBlock)
        XCTAssertEqual(blocks[0].height, 2)
        XCTAssertEqual(blocks[0].headerHash, headerHash1)
        XCTAssertEqual(blocks[0].reversedHeaderHashHex, headerHash1.reversedHex)

        XCTAssertEqual(blocks[1].header, header2)
        XCTAssertEqual(blocks[1].previousBlock, blocks[0])
        XCTAssertEqual(blocks[1].height, 3)
        XCTAssertEqual(blocks[1].headerHash, headerHash2)
        XCTAssertEqual(blocks[1].reversedHeaderHashHex, headerHash2.reversedHex)
    }

}
