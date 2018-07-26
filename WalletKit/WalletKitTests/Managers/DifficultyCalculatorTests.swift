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

        firstCheckPointBlock = Block()
        firstCheckPointBlock.reversedHeaderHashHex = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30"
        firstCheckPointBlock.headerHash = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30".reversedData!
        firstCheckPointBlock.height = 530208

        let previousHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000000020c68bfc8de14bc9dd2d6cf45161a67e0c6455cf28cfd8".reversedData!, merkleRoot: "a3f40c28cc6b90b2b1bfaef0e1c394b01dd97786b6a7da5e35f26bc4a7b1e451".reversedData!, timestamp: 1530545661, bits: 389315112, nonce: 630776633)
//        firstCheckPointBlock.rawHeader = previousHeaderItem.serialized()
    }

    override func tearDown() {
        firstCheckPointBlock = nil
        calculator = nil
        mockDifficultyEncoder = nil

        super.tearDown()
    }

    func testDifficultyForBlock() {

        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910)
        let previousItemHeight = 532223
        let previousBigInt = BigInt("5026314587016750785722693470327208449351582469580652544")!

        let item = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0".reversedData!, merkleRoot: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40".reversedData!, timestamp: 1531799449, bits: 389437975, nonce: 2023890938)
        let itemBigInt = BigInt("5205879841852030921059527756813029926469497427631238471")!

        stub(mockDifficultyEncoder) { mock in
            when(mock.decodeCompact(bits: previousItem.bits)).thenReturn(previousBigInt)
            when(mock.decodeCompact(bits: item.bits)).thenReturn(itemBigInt)
            when(mock.encodeCompact(from: equal(to: previousBigInt))).thenReturn(previousItem.bits)
            when(mock.encodeCompact(from: equal(to: itemBigInt))).thenReturn(item.bits)
        }

//        XCTAssertEqual(calculator.difficultyAfter(item: previousItem, checkPointBlock: firstCheckPointBlock, height: previousItemHeight), item.bits)
    }

}
