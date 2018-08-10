import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class BlockSaverTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var saver: BlockSaver!

    private var realm: Realm!
    private var initialBlock: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        saver = BlockSaver(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write {
            realm.deleteAll()
        }

        initialBlock = Block(withHeader: TestData.checkpointBlockHeader, height: 1)

        try! realm.write {
            realm.add(initialBlock)
        }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        saver = nil

        realm = nil
        initialBlock = nil

        super.tearDown()
    }

    func testSave() {
        let block1 = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92", merkleRootReversedHex: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a", timestamp: 1506023937, bits: 453021074, nonce: 2001025151),
                previousBlock: initialBlock
        )
        let block2 = Block(
                withHeader: BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176", merkleRootReversedHex: "63241c065cf8240ac64772e064a9436c21dc4c75843e7e5df6ecf41d5ef6a1b4", timestamp: 1506024043, bits: 453021074, nonce: 1373615473),
                previousBlock: block1
        )

        try! saver.create(blocks: [block1, block2])

        let blocks = realm.objects(Block.self)

        XCTAssertEqual(blocks.count, 1 + 2)
        XCTAssertEqual(blocks[1].previousBlock, initialBlock)
        XCTAssertEqual(blocks[2].previousBlock, blocks[1])
    }

    func testUpdateWithMerkleBlock() {
        let blockHeader = BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92", merkleRootReversedHex: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a", timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
        let hashes = [
            "f0db27cd89551bd197bf551bf697d6eab8fea1fae982fe4b0055fdd58b1f7ee0".reversedData!,
            "86fef17ab1b91ffd8e9e9b14823539e4a22116a078cda1de6e31ddbcbd070993".reversedData!
        ]
        let block = Block(withHeader: blockHeader, previousBlock: initialBlock)

        try! saver.create(blocks: [block])

        guard let savedBlock = realm.objects(Block.self).last else {
            XCTFail("Block not saved!")
            return
        }

        try! saver.update(block: savedBlock, withTransactionHashes: hashes)
        let transactions = realm.objects(Transaction.self)

        XCTAssertEqual(savedBlock.transactions.count, transactions.count)
        for i in 0..<transactions.count {
            XCTAssertEqual(savedBlock.transactions[i].reversedHashHex, hashes[i].reversedHex)
        }

        XCTAssertTrue(savedBlock.synced)
    }

    func testUpdateExistingTransactionsWithBlock() {
        let rawTransaction = "0100000001865c106cd7a90c80e5447f6e2891aaf5a0d11fb29e1a9258dce26da7ef04c028000000004847304402205c54aa165861bf5347683fb078a99188726ee2577e3554d0f77ad7c60a4b072902206f77f42f216e4c64585a60ec76a944fc83278524e5a0dfda31b58f94035d27be01ffffffff01806de7290100000017a914121e63ee09fc7e20b59d144dcce6e2700f6f1a9c8700000000"
        let transaction = Transaction.deserialize(Data(hex: rawTransaction)!)

        let blockHeader = BlockHeader(version: 536870912, previousBlockHeaderReversedHex: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92", merkleRootReversedHex: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a", timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
        let hashes = [
            Data(Data(hex: transaction.reversedHashHex)!.reversed())
        ]

        let block = Block(withHeader: blockHeader, previousBlock: initialBlock)

        try! saver.create(blocks: [block])
        try! realm.write {
            realm.add(transaction, update: true)
        }

        guard let savedBlock = realm.objects(Block.self).last else {
            XCTFail("Block not saved!")
            return
        }

        var savedTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", hashes[0].reversedHex).first!
        XCTAssertEqual(savedTransaction.block, nil)

        try! saver.update(block: savedBlock, withTransactionHashes: hashes)

        savedTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", hashes[0].reversedHex).first!
        XCTAssertEqual(savedTransaction.block, savedBlock)
        XCTAssertEqual(savedTransaction.version, transaction.version)
        XCTAssertEqual(savedBlock.synced, true)
    }

}
