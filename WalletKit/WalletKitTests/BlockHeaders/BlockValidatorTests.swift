import XCTest
import Cuckoo
import RealmSwift
import BigInt
@testable import WalletKit

class BlockValidatorTests: XCTestCase {

    private var validator: BlockValidator!
    private var mockCalculator: MockDifficultyCalculator!

    private var firstCheckPointBlock: Block!
    private var firstBlock: Block!

    override func setUp() {
        super.setUp()

        mockCalculator = MockDifficultyCalculator(difficultyEncoder: DifficultyEncoderStub())
        validator = BlockValidator(calculator: mockCalculator)

        firstCheckPointBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000020c68bfc8de14bc9dd2d6cf45161a67e0c6455cf28cfd8", merkleRootReversedHex: "a3f40c28cc6b90b2b1bfaef0e1c394b01dd97786b6a7da5e35f26bc4a7b1e451", timestamp: 1530545661, bits: 389315112, nonce: 630776633),
                height: 530208
        )
        firstBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                height: 532223
        )

        stub(mockCalculator) { mock in
            when(mock.difficultyAfter(block: equal(to: firstBlock), lastCheckPointBlock: equal(to: firstCheckPointBlock))).thenReturn(0)
        }

    }

    override func tearDown() {
        validator = nil

        firstCheckPointBlock = nil
        firstBlock = nil

        super.tearDown()
    }

    func makeChain(block: Block, lastBlock: Block, interval: Int) {
        var previousBlock: Block = block
        for _ in 0..<interval {
            let block = Block()
            block.height = previousBlock.height - 1
            previousBlock.previousBlock = block

            previousBlock = block
        }
        previousBlock.previousBlock = lastBlock
    }

    func testValidItem() {
        let firstBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92", merkleRootReversedHex: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a", timestamp: 1506023937, bits: 453021074, nonce: 2001025151),
                height: 1
        )
        let testBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176", merkleRootReversedHex: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4", timestamp: 1506024043, bits: 453021074, nonce: 1373615473),
                previousBlock: firstBlock
        )
        do {
            try validator.validate(block: testBlock)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidChangeDifficultyItem() {
        let testBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                previousBlock: firstBlock
        )

        stub(mockCalculator) { mock in
            when(mock.difficultyAfter(block: any(), lastCheckPointBlock: any())).thenReturn(389437975)
        }

        makeChain(block: firstBlock, lastBlock: firstCheckPointBlock, interval: 2014)

        var caught = false
        do {
            try validator.validate(block: testBlock)
        } catch {
            caught = true
        }

        XCTAssertFalse(caught, "exception thrown")
    }

    func testInvalidHashItem() {
        let firstBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92", merkleRootReversedHex: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a", timestamp: 1506023937, bits: 453021074, nonce: 2001025151),
                height: 0
        )
        let testBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000d0923442e1a8345b82f553786487293204746b2631a6858549", merkleRootReversedHex: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4", timestamp: 1506024043, bits: 453021074, nonce: 1373615473),
                previousBlock: firstBlock
        )
        var caught = false
        do {
            try validator.validate(block: testBlock)
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.wrongPreviousHeaderHash)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "wrongPreviousHeaderHash exception not thrown")
    }

    func testNoEqualBitsItem() {
        let firstBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                height: 0
        )
        let testBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                previousBlock: firstBlock
        )
        var caught = false
        do {
            try validator.validate(block: testBlock)
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.notEqualBits)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "notEqualBits exception not thrown")
    }

    func testNoLastCheckPointItem() {
        let testBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                previousBlock: firstBlock
        )
        makeChain(block: firstBlock, lastBlock: Block(), interval: 2013)

        var caught = false
        do {
            try validator.validate(block: testBlock)
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.noCheckpointBlock)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "noCheckpointBlock exception not thrown")
    }

    func testInvalidChangeDifficulty() {
        let testBlock = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389315112, nonce: 2023890938),
                previousBlock: firstBlock
        )
        makeChain(block: firstBlock, lastBlock: firstCheckPointBlock, interval: 2014)

        var caught = false
        do {
            try validator.validate(block: testBlock)
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.notDifficultyTransitionEqualBits)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "notDifficultyTransitionEqualBits exception not thrown")
    }

}
