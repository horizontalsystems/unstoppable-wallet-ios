import XCTest
import Cuckoo
import RealmSwift
import BigInt
@testable import WalletKit

class BlockHeaderItemValidatorTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!

    private var validator: BlockHeaderItemValidator!

    private var realm: Realm!
    private var firstCheckPointBlock: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        validator = BlockHeaderItemValidator(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        firstCheckPointBlock = Block()
        firstCheckPointBlock.reversedHeaderHashHex = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30"
        firstCheckPointBlock.headerHash = "0000000000000000002999e6f0537a1707b027a7ccdce1723700d51b1400be30".reversedData!
        firstCheckPointBlock.height = 530208

        let previousHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000000020c68bfc8de14bc9dd2d6cf45161a67e0c6455cf28cfd8".reversedData!, merkleRoot: "a3f40c28cc6b90b2b1bfaef0e1c394b01dd97786b6a7da5e35f26bc4a7b1e451".reversedData!, timestamp: 1530545661, bits: 389315112, nonce: 630776633)
        firstCheckPointBlock.rawHeader = previousHeaderItem.serialized()

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        validator = nil

        realm = nil
        firstCheckPointBlock = nil

        super.tearDown()
    }

    func testIsDifficultyTransitionPoint() {
        let height = 4031 // block before second check point

        XCTAssertTrue(validator.isDifficultyTransitionPoint(height: height))
    }

    func testNotIsDifficultyTransitionPoint() {
        let height = 17933 // any not check point block height

        XCTAssertFalse(validator.isDifficultyTransitionPoint(height: height))
    }

    func testDifficultyForBlock() {
        try! realm.write { realm.add(firstCheckPointBlock) }

        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910)
        let previousItemHeight = 532223

        let item = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000000009dce52e227d46a6bdf38a8c1f2e88c6044893289c2bf0".reversedData!, merkleRoot: "43ee07fdd8892234d1d3ef85e83354ff79836ebafa1f8d94dec2858fdca16e40".reversedData!, timestamp: 1531799449, bits: 389437975, nonce: 2023890938)
        let itemHeight = 532224

        let newBits = try! validator.difficultyAfter(item: previousItem, height: previousItemHeight)
        XCTAssertEqual(newBits, item.bits)
    }

    func testDifficultyForBlock_NoCheckPoint() {
        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910)
        let previousItemHeight = 532223

        var caught = false
        do {
            let newBits = try validator.difficultyAfter(item: previousItem, height: previousItemHeight)
        } catch let error as BlockHeaderItemValidator.HeaderValidatorError {
            caught = true
            XCTAssertEqual(error, BlockHeaderItemValidator.HeaderValidatorError.noCheckpointBlock)
        } catch {
            XCTFail("Unknown exception thrown")
        }
        XCTAssertTrue(caught, "noCheckpointBlock exception not thrown")
    }

    func testDifficultyForBlock_Wrong() {
        try! realm.write { realm.add(firstCheckPointBlock) }

        let previousItem = BlockHeaderItem(version: 536870912, prevBlock: "0000000000000000001f1bd6d48e0fa41d054f54440a5ff3fee200bbdb37e0e5".reversedData!, merkleRoot: "df838278ff83d53e91423d5f7cefe64ef163004e18408de2374bd1b898241c78".reversedData!, timestamp: 1531798474, bits: 389315112, nonce: 2195910910)
        let previousItemHeight = 532223

        let item = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000c9a91d8277c58eab3bfda59d3068142dd54216129e5597ccbd".reversedData!, merkleRoot: "076c5847dbde99ed49cd75d7dbe63c3d3bb9399b135d1639d6169b8a5510913b".reversedData!, timestamp: 1531214479, bits: 425766046, nonce: 1076882637)

        XCTAssertNotEqual(try! validator.difficultyAfter(item: previousItem, height: previousItemHeight), item.bits)
    }

    func testValidItem() {
        let previousBlock = BlockHeaderItem(version: 536870912, prevBlock: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92".reversedData!, merkleRoot: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a".reversedData!, timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
        let item = BlockHeaderItem(version: 536870912, prevBlock: "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176".reversedData!, merkleRoot: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4".reversedData!, timestamp: 1506024043, bits: 453021074, nonce: 1373615473)
        let previousHeight = 0

        XCTAssertTrue(try! validator.isValid(item: item, previousItem: previousBlock, previousHeight: previousHeight))
    }

    func testInvalidItem() {
        let previousBlock = BlockHeaderItem(version: 536870912, prevBlock: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92".reversedData!, merkleRoot: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a".reversedData!, timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
        let item = BlockHeaderItem(version: 536870912, prevBlock: "00000000000000d0923442e1a8345b82f553786487293204746b2631a6858549".reversedData!, merkleRoot: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4".reversedData!, timestamp: 1506024043, bits: 453021074, nonce: 1373615473)
        let previousHeight = 0

        XCTAssertFalse(try! validator.isValid(item: item, previousItem: previousBlock, previousHeight: previousHeight))
    }

    func testLimitTimeSpanMinimum() {
        let timeSpan = 800
        let minimumSpan = BlockHeaderItemValidator.targetTimeSpan / 4

        XCTAssertEqual(validator.limit(timeSpan: timeSpan), minimumSpan)
    }

    func testLimitTimeSpanMaximum() {
        let timeSpan = 100012800
        let maximumSpan = BlockHeaderItemValidator.targetTimeSpan * 4

        XCTAssertEqual(validator.limit(timeSpan: timeSpan), maximumSpan)
    }

    func testLimitTimeSpan() {
        let timeSpan = BlockHeaderItemValidator.targetTimeSpan * 2
        let maximumSpan = BlockHeaderItemValidator.targetTimeSpan * 4

        XCTAssertEqual(validator.limit(timeSpan: timeSpan), timeSpan)
    }

    func testEncodeCompact() {
        let difficulty: BigInt = BigInt("1234560000", radix: 16)!
        let representation: UInt32 = 0x05123456

        XCTAssertEqual(BlockHeaderItemValidator.encodeCompact(from: difficulty), representation)
    }

    func testEncodeCompact_second() {
        let difficulty: BigInt = BigInt("c0de000000", radix: 16)!
        let representation: UInt32 = 0x0600c0de
        print(difficulty.description)
        XCTAssertEqual(BlockHeaderItemValidator.encodeCompact(from: difficulty), representation)
    }

    func testEncodeCompact_third() {
        let difficulty: BigInt = BigInt("-40de000000", radix: 16)!
        let representation: UInt32 = 0x05c0de00
        print(difficulty.description)
        XCTAssertEqual(BlockHeaderItemValidator.encodeCompact(from: difficulty), representation)
    }

    func testDecodeCompact() {
        let difficulty: BigInt = BigInt("1234560000", radix: 16)!
        let representation: UInt32 = 0x05123456

        XCTAssertEqual(BlockHeaderItemValidator.decodeCompact(bits: representation), difficulty)
    }

    func testDecodeCompact_second() {
        let difficulty: BigInt = BigInt("c0de000000", radix: 16)!
        let representation: UInt32 = 0x0600c0de

        XCTAssertEqual(BlockHeaderItemValidator.decodeCompact(bits: representation), difficulty)
    }

    func testDecodeCompact_third() {
        let difficulty: BigInt = BigInt("-40de000000", radix: 16)!
        let representation: UInt32 = 0x05c0de00

        XCTAssertEqual(BlockHeaderItemValidator.decodeCompact(bits: representation), difficulty)
    }

}
