import XCTest
import Cuckoo
import RealmSwift
import BigInt
@testable import WalletKit

class TestNetBlockValidatorTests: XCTestCase {

    private var validator: BlockValidator!
    private var firstCheckPointBlock: Block!
    private var previousSmallTimeSpanBlock: Block!

    override func setUp() {
        super.setUp()

        validator = TestNetBlockValidator()

        firstCheckPointBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000c9a91d8277c58eab3bfda59d3068142dd54216129e5597ccbd", merkleRootReversedHex: "076c5847dbde99ed49cd75d7dbe63c3d3bb9399b135d1639d6169b8a5510913b", timestamp: 1531214479, bits: 425766046, nonce: 1076882637),
                height: 1352736
        )
        previousSmallTimeSpanBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000000023551663777c17f6f7b4c567ef9421f6b5a949dbaf47a696da", merkleRootReversedHex: "f28b33a2a294ca879f65245cd5fe60d55db27abadb146993bc83f8d574b19027", timestamp: 1532135281, bits: 425766046, nonce: 1555164689),
                height: 1354749
        )
    }

    override func tearDown() {
        validator = nil
        firstCheckPointBlock = nil
        previousSmallTimeSpanBlock = nil

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
        let previousBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000003207f0eec08b503a1cfd436bebd534447d5617e873e565e857", merkleRootReversedHex: "cea385cdb303a11667ea0815237a3884972735847d16ddb8e249e8b85f9f6da5", timestamp: 1532135295, bits: 425766046, nonce: 1573976592),
                height: 1354750
        )
        let block = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000004b68d8b5453cf38c485b1b42d564b6a1d8487ec5ce662622ea", merkleRootReversedHex: "fde234b11907f3f6d45633ab11a1ba0db59f8aabecf5879d1ef301ef091f4f44", timestamp: 1532135309, bits: 425766046, nonce: 3687858789),
                previousBlock: previousBlock
        )

        do {
            try validator.validate(block: block)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidItem_checkPoint() {

        let block = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000003207f0eec08b503a1cfd436bebd534447d5617e873e565e857", merkleRootReversedHex: "cea385cdb303a11667ea0815237a3884972735847d16ddb8e249e8b85f9f6da5", timestamp: 1532135295, bits: 425766046, nonce: 1573976592),
                previousBlock: previousSmallTimeSpanBlock
        )

        do {
            try validator.validate(block: block)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidItem_changeBits2() {
        let previousBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000292d142fcc1ddbd9dafd4518310009f152bdca2a66cc589f97", merkleRootReversedHex: "48239e76f8b37d9c8824fef93d42ac3d7c433029c1e9fa23b6416dd0356f3e57", timestamp: 1532143012, bits: 424253525, nonce: 3410287696),
                height: 1354760
        )

        let block = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000000127454a8c91e74cf93ad76752cceb7eb3bcff0c398ba84b1f", merkleRootReversedHex: "df50dc26ca3a5ac081e90b7c228c25319e018dd2ccd6d34e63c1919f80d25b0c", timestamp: 1532144219, bits: 486604799, nonce: 419922806),
                previousBlock: previousBlock
        )

        do {
            try validator.validate(block: block)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidItem_changeToMaxTarget() {
        let oldBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000292d142fcc1ddbd9dafd4518310009f152bdca2a66cc589f97", merkleRootReversedHex: "48239e76f8b37d9c8824fef93d42ac3d7c433029c1e9fa23b6416dd0356f3e57", timestamp: 1532143012, bits: 424253525, nonce: 3410287696),
                height: 1354760
        )

        let previousBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000000127454a8c91e74cf93ad76752cceb7eb3bcff0c398ba84b1f", merkleRootReversedHex: "df50dc26ca3a5ac081e90b7c228c25319e018dd2ccd6d34e63c1919f80d25b0c", timestamp: 1532144219, bits: 486604799, nonce: 419922806),
                previousBlock: oldBlock
        )

        let block = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "0000000000004a50ef5733ab333f718e6ef5c1995e2cfd5a7caa0875f118cd30", merkleRootReversedHex: "66d13b02f9eec87b7f4ae7b0ae15b76816ddb432cceaf01ace6c7b81b901ddc5", timestamp: 1532145052, bits: 424253525, nonce: 2794859001),
                previousBlock: previousBlock
        )

        do {
            try validator.validate(block: block)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidCheckPointItem() {
        let checkPointBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000002ac6d5c058c9932f350aeef84f6e334f4e01b40be4db537f8c2", merkleRootReversedHex: "9e172a04fc387db6f273ee96b4ef50732bb4b06e494483d182c5722afd8770b3", timestamp: 1530756778, bits: 436273151, nonce: 4053884125),
                height: 1350720
        )
        let previousBlock = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000c6721126859c1f2d289eb3f9beff79388f596f332ae8d3e3a8", merkleRootReversedHex: "77bb66cd8075995f05ef82c727cfa407769ee70607f16c589f594e0dbb23f881", timestamp: 1531213571, bits: 436273151, nonce: 3537712057),
                height: 1352735
        )
        makeChain(block: previousBlock, lastBlock: checkPointBlock, interval: 2014)
        let block = BlockFactory.shared.block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000000c9a91d8277c58eab3bfda59d3068142dd54216129e5597ccbd", merkleRootReversedHex: "076c5847dbde99ed49cd75d7dbe63c3d3bb9399b135d1639d6169b8a5510913b", timestamp: 1531214479, bits: 425766046, nonce: 1665657862),
                previousBlock: previousBlock
        )

        do {
            try validator.validate(block: block)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

}
