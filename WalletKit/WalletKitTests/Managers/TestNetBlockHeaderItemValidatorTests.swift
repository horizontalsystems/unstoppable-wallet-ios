import XCTest
import Cuckoo
import RealmSwift
import BigInt
@testable import WalletKit

class TestNetBlockHeaderItemValidatorTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!

    private var validator: BlockHeaderItemValidator!

    private var realm: Realm!
    private var firstCheckPointBlock: Block!

    private var previousSmallTimeSpanBlock: Block!
    private var previousSmallTimeSpanItem: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        validator = TestNetBlockHeaderItemValidator(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

//        firstCheckPointBlock = Block()
//        firstCheckPointBlock.reversedHeaderHashHex = "000000000000000111aedaafdf2b2319ae2b773c2f3cad9d1bb7833c22b21e26"
//        firstCheckPointBlock.headerHash = "000000000000000111aedaafdf2b2319ae2b773c2f3cad9d1bb7833c22b21e26".reversedData!
//        firstCheckPointBlock.height = 1352736
//
//        let previousHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000c9a91d8277c58eab3bfda59d3068142dd54216129e5597ccbd".reversedData!, merkleRoot: "076c5847dbde99ed49cd75d7dbe63c3d3bb9399b135d1639d6169b8a5510913b".reversedData!, timestamp: 1531214479, bits: 425766046, nonce: 1076882637)
//        firstCheckPointBlock.rawHeader = previousHeaderItem.serialized()
//
//        previousSmallTimeSpanBlock = Block()
//        previousSmallTimeSpanBlock.reversedHeaderHashHex = "000000000000003207f0eec08b503a1cfd436bebd534447d5617e873e565e857"
//        previousSmallTimeSpanBlock.headerHash = "000000000000003207f0eec08b503a1cfd436bebd534447d5617e873e565e857".reversedData!
//        previousSmallTimeSpanBlock.height = 1354749
//
//        let previousSmallTimeSpanItem = BlockHeaderItem(version: 536870912, prevBlock: "0000000000000023551663777c17f6f7b4c567ef9421f6b5a949dbaf47a696da".reversedData!, merkleRoot: "f28b33a2a294ca879f65245cd5fe60d55db27abadb146993bc83f8d574b19027".reversedData!, timestamp: 1532135281, bits: 425766046, nonce: 1555164689)
//        previousSmallTimeSpanBlock.rawHeader = previousHeaderItem.serialized()

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        validator = nil

        realm = nil
        firstCheckPointBlock = nil

        previousSmallTimeSpanBlock = nil
        previousSmallTimeSpanItem = nil

        super.tearDown()
    }

    func testValidItem() {
//        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "000000000000003207f0eec08b503a1cfd436bebd534447d5617e873e565e857".reversedData!, merkleRoot: "cea385cdb303a11667ea0815237a3884972735847d16ddb8e249e8b85f9f6da5".reversedData!, timestamp: 1532135295, bits: 425766046, nonce: 1573976592)
//        let item = BlockHeaderItem(version: 536870912, prevBlock: "000000000000004b68d8b5453cf38c485b1b42d564b6a1d8487ec5ce662622ea".reversedData!, merkleRoot: "fde234b11907f3f6d45633ab11a1ba0db59f8aabecf5879d1ef301ef091f4f44".reversedData!, timestamp: 1532135309, bits: 425766046, nonce: 3687858789)
//        let previousHeight = 1354750
//
//        do {
//            try validator.validate(item: item, previousItem: previousItem, previousHeight: previousHeight)
//        } catch let error {
//            XCTFail("\(error) Exception Thrown")
//        }
    }

    func testValidItem_checkPoint() {
//        try! realm.write { realm.add(firstCheckPointBlock) }
//
//        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "000000000000004b68d8b5453cf38c485b1b42d564b6a1d8487ec5ce662622ea".reversedData!, merkleRoot: "fde234b11907f3f6d45633ab11a1ba0db59f8aabecf5879d1ef301ef091f4f44".reversedData!, timestamp: 1532135309, bits: 425766046, nonce: 3687858789)
//        let item = BlockHeaderItem(version: 536870912, prevBlock: "0000000000000051bff2f64c9078fb346d6a2a209ba5c3ffa0048c6b7027e47f".reversedData!, merkleRoot: "992c07e1a7b9a53ae3b8764333324396570fce24c49b8de7ed87fb1346df62a7".reversedData!, timestamp: 1532137995, bits: 424253525, nonce: 1665657862)
//        let previousHeight = 1354751
//
//        do {
//            try validator.validate(item: item, previousItem: previousItem, previousHeight: previousHeight)
//        } catch let error {
//            XCTFail("\(error) Exception Thrown")
//        }
    }

    func testValidItem_changeBits2() {
//        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000292d142fcc1ddbd9dafd4518310009f152bdca2a66cc589f97".reversedData!, merkleRoot: "48239e76f8b37d9c8824fef93d42ac3d7c433029c1e9fa23b6416dd0356f3e57".reversedData!, timestamp: 1532143012, bits: 424253525, nonce: 3410287696)
//        let item = BlockHeaderItem(version: 536870912, prevBlock: "000000000000000127454a8c91e74cf93ad76752cceb7eb3bcff0c398ba84b1f".reversedData!, merkleRoot: "df50dc26ca3a5ac081e90b7c228c25319e018dd2ccd6d34e63c1919f80d25b0c".reversedData!, timestamp: 1532144219, bits: 486604799, nonce: 419922806)
//        let previousHeight = 1354760
//
//        do {
//            try validator.validate(item: item, previousItem: previousItem, previousHeight: previousHeight)
//        } catch let error {
//            XCTFail("\(error) Exception Thrown")
//        }
    }

    func testValidItem_changeToMaxTarget() {
//        var block = Block()
//        block.reversedHeaderHashHex = "000000000000000127454a8c91e74cf93ad76752cceb7eb3bcff0c398ba84b1f"
//        block.headerHash = "000000000000000127454a8c91e74cf93ad76752cceb7eb3bcff0c398ba84b1f".reversedData!
//        block.height = 1354760
//
//        let blockItem = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000292d142fcc1ddbd9dafd4518310009f152bdca2a66cc589f97".reversedData!, merkleRoot: "48239e76f8b37d9c8824fef93d42ac3d7c433029c1e9fa23b6416dd0356f3e57".reversedData!, timestamp: 1532143012, bits: 424253525, nonce: 3410287696)
//        block.rawHeader = blockItem.serialized()
//
//        try! realm.write { realm.add(block) }
//
//        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "000000000000000127454a8c91e74cf93ad76752cceb7eb3bcff0c398ba84b1f".reversedData!, merkleRoot: "df50dc26ca3a5ac081e90b7c228c25319e018dd2ccd6d34e63c1919f80d25b0c".reversedData!, timestamp: 1532144219, bits: 486604799, nonce: 419922806)
//        let item = BlockHeaderItem(version: 536870912, prevBlock: "0000000000004a50ef5733ab333f718e6ef5c1995e2cfd5a7caa0875f118cd30".reversedData!, merkleRoot: "66d13b02f9eec87b7f4ae7b0ae15b76816ddb432cceaf01ace6c7b81b901ddc5".reversedData!, timestamp: 1532145052, bits: 424253525, nonce: 2794859001)
//        let previousHeight = 1354761
//
//        do {
//            try validator.validate(item: item, previousItem: previousItem, previousHeight: previousHeight)
//        } catch let error {
//            XCTFail("\(error) Exception Thrown")
//        }
    }

    func testInvalidHashItem() {
//        let previousBlock = BlockHeaderItem(version: 536870912, prevBlock: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92".reversedData!, merkleRoot: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a".reversedData!, timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
//        let item = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000d0923442e1a8345b82f553786487293204746b2631a6858549".reversedData!, merkleRoot: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4".reversedData!, timestamp: 1506024043, bits: 453021074, nonce: 1373615473)
//        let previousHeight = 0
//
//        var caught = false
//        do {
//            try validator.validate(item: item, previousItem: previousBlock, previousHeight: previousHeight)
//        } catch let error as BlockHeaderItemValidator.HeaderValidatorError {
//            caught = true
//            XCTAssertEqual(error, BlockHeaderItemValidator.HeaderValidatorError.wrongPreviousHeaderHash)
//        } catch {
//            XCTFail("Unknown exception thrown")
//        }
//
//        XCTAssertTrue(caught, "wrongPreviousHeaderHash exception not thrown")
    }

}
