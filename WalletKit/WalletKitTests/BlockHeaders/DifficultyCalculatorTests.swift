import XCTest
import Cuckoo
import RealmSwift
import BigInt
@testable import WalletKit

class DifficultyCalculatorTests: XCTestCase {

    private var firstCheckPointBlock: Block!
    private var calculator: DifficultyCalculator!

    private var mockDifficultyEncoder: MockDifficultyEncoder!

    override func setUp() {
        super.setUp()

        mockDifficultyEncoder = MockDifficultyEncoder()
        calculator = DifficultyCalculator(difficultyEncoder: mockDifficultyEncoder)

        firstCheckPointBlock = BlockFactory().block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000020c68bfc8de14bc9dd2d6cf45161a67e0c6455cf28cfd8", merkleRootReversedHex: "a3f40c28cc6b90b2b1bfaef0e1c394b01dd97786b6a7da5e35f26bc4a7b1e451", timestamp: 1530545661, bits: 389315112, nonce: 630776633),
                height: 530208
        )

        firstCheckPointBlock.reversedHeaderHashHex = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30"
        firstCheckPointBlock.headerHash = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30".reversedData!
        firstCheckPointBlock.height = 530208
    }

    override func tearDown() {
        firstCheckPointBlock = nil
        calculator = nil
        mockDifficultyEncoder = nil

        super.tearDown()
    }

    func testDifficultyForBlock() {

        let previousBlock = BlockFactory().block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5", merkleRootReversedHex: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78", timestamp: 1531798474, bits: 389315112, nonce: 2195910910),
                height: 532223
        )
        let previousBigInt = BigInt("5026314587016750785722693470327208449351582469580652544")!

        let block = BlockFactory().block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0", merkleRootReversedHex: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40", timestamp: 1531799449, bits: 389437975, nonce: 2023890938),
                previousBlock: previousBlock
        )

        let itemBigInt = BigInt("5205879841852030921059527756813029926469497427631238471")!

        stub(mockDifficultyEncoder) { mock in
            when(mock.decodeCompact(bits: previousBlock.header!.bits)).thenReturn(previousBigInt)
            when(mock.decodeCompact(bits: block.header!.bits)).thenReturn(itemBigInt)
            when(mock.encodeCompact(from: equal(to: previousBigInt))).thenReturn(previousBlock.header!.bits)
            when(mock.encodeCompact(from: equal(to: itemBigInt))).thenReturn(block.header!.bits)
        }

        do {
            let newDifficulty = try calculator.difficultyAfter(block: previousBlock, lastCheckPointBlock: firstCheckPointBlock)
            XCTAssertEqual(newDifficulty, block.header!.bits)
        } catch {
            XCTFail("Error Handled!")
        }
    }

}
