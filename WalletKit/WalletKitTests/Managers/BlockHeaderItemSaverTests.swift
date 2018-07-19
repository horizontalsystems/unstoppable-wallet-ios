import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class BlockHeaderItemSaverTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var saver: BlockHeaderItemSaver!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        saver = BlockHeaderItemSaver(realmFactory: mockRealmFactory)

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

        saver.save(lastHeight: lastHeight, items: items)

        let blocks = realm.objects(Block.self)

        XCTAssertEqual(blocks.count, 2)
        verify(block: blocks[0], item: items[0], height: lastHeight + 1)
        verify(block: blocks[1], item: items[1], height: lastHeight + 2)
    }

    private func verify(block: Block, item: BlockHeaderItem, height: Int) {
        let headerHash = Crypto.sha256sha256(item.serialized())
        XCTAssertEqual(block.reversedHeaderHashHex, headerHash.reversedHex)
        XCTAssertEqual(block.headerHash, headerHash)
        XCTAssertEqual(block.height, height)
        XCTAssertEqual(block.archived, false)
    }

}
