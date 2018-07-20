import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class BlockSaverTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var saver: BlockSaver!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        saver = BlockSaver(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        saver = nil

        realm = nil

        super.tearDown()
    }

    func testSave() {
        let lastHeight = 1

        let items = [
            BlockHeaderItem(version: 536870912, prevBlock: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92".reversedData!, merkleRoot: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a".reversedData!, timestamp: 1506023937, bits: 453021074, nonce: 2001025151),
            BlockHeaderItem(version: 536870912, prevBlock: "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176".reversedData!, merkleRoot: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4".reversedData!, timestamp: 1506024043, bits: 453021074, nonce: 1373615473)
        ]

        saver.create(withHeight: lastHeight, fromItems: items)

        let blocks = realm.objects(Block.self)

        XCTAssertEqual(blocks.count, 2)
        verifyBlock(block: blocks[0], item: items[0], height: lastHeight + 1)
        verifyBlock(block: blocks[1], item: items[1], height: lastHeight + 2)
    }

    func testUpdateWithMerkleBlock() {
        let lastHeight = 1
        let blockHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92".reversedData!, merkleRoot: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a".reversedData!, timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
        let hashes = [
            "f0db27cd89551bd197bf551bf697d6eab8fea1fae982fe4b0055fdd58b1f7ee0".reversedData!,
            "86fef17ab1b91ffd8e9e9b14823539e4a22116a078cda1de6e31ddbcbd070993".reversedData!
        ]
        let message = MerkleBlockMessage(blockHeaderItem: blockHeaderItem, totalTransactions: 1, numberOfHashes: 2, hashes: hashes, numberOfFlags: 3, flags: [1, 0, 0])

        saver.create(withHeight: lastHeight, fromItems: [blockHeaderItem])
        guard let savedBlock = realm.objects(Block.self).last else {
            XCTFail("Block not saved!")
            return
        }

        saver.update(block: savedBlock, withMerkleBlock: message)
        let transactions = realm.objects(Transaction.self)

        XCTAssertEqual(savedBlock.transactions.count, transactions.count)
        for (i, transaction) in transactions.enumerated() {
            XCTAssertEqual(savedBlock.transactions[i].transactionHash, hashes[i].reversedHex)
        }
    }

    private func verifyBlock(block: Block, item: BlockHeaderItem, height: Int) {
        let rawHeader = item.serialized()
        let headerHash = Crypto.sha256sha256(rawHeader)
        XCTAssertEqual(block.reversedHeaderHashHex, headerHash.reversedHex)
        XCTAssertEqual(block.headerHash, headerHash)
        XCTAssertEqual(block.rawHeader, rawHeader)
        XCTAssertEqual(block.height, height)
        XCTAssertEqual(block.archived, false)
    }

}
