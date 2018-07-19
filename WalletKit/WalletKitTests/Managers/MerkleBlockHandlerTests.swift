import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class MerkleBlockHandlerTests: XCTestCase {
    private var mockRealmFactory: MockRealmFactory!
    private var mockValidator: MockMerkleBlockValidator!
    private var mockSaver: MockMerkleBlockSaver!
    private var merkleBlockHandler: MerkleBlockHandler!

    private var realm: Realm!
    private var block: Block!
    private var blockHeaderItem: BlockHeaderItem!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockMerkleBlockValidator()
        mockSaver = MockMerkleBlockSaver()
        merkleBlockHandler = MerkleBlockHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        block = Block()
        block.reversedHeaderHashHex = "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176"
        block.height = 2016

        blockHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92".reversedData!, merkleRoot: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a".reversedData!, timestamp: 1506023937, bits: 453021074, nonce: 2001025151)

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.save(block: any(), message: any()).thenDoNothing())
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockValidator = nil
        mockSaver = nil
        merkleBlockHandler = nil

        realm = nil
        block = nil

        super.tearDown()
    }

    func testValidMerkleBlock() {
        try! realm.write { realm.add(block) }

        let message = MerkleBlockMessage(blockHeaderItem: blockHeaderItem, totalTransactions: 1, numberOfHashes: 1, hashes: [Data()], numberOfFlags: 1, flags: [])

        stub(mockValidator) { mock in
            when(mock.isValid(message: equal(to: message))).thenReturn(true)
        }

        try! merkleBlockHandler.handle(message: message)
        verify(mockSaver).save(block: equal(to: block), message: equal(to: message))
    }

    func testInvalidMerkleBlocks() {
        try! realm.write { realm.add(block) }

        let message = MerkleBlockMessage(blockHeaderItem: blockHeaderItem, totalTransactions: 1, numberOfHashes: 1, hashes: [Data()], numberOfFlags: 1, flags: [])

        stub(mockValidator) { mock in
            when(mock.isValid(message: equal(to: message))).thenReturn(false)
        }

        try! merkleBlockHandler.handle(message: message)
        verifyNoMoreInteractions(mockSaver)
    }

    func testSync_NoBlock() {
        let message = MerkleBlockMessage(blockHeaderItem: blockHeaderItem, totalTransactions: 1, numberOfHashes: 1, hashes: [Data()], numberOfFlags: 1, flags: [])
        var caught = false

        do {
            try merkleBlockHandler.handle(message: message)
        } catch let error as MerkleBlockHandler.HandleError {
            caught = true
            XCTAssertEqual(error, MerkleBlockHandler.HandleError.blockNotFound)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        verifyNoMoreInteractions(mockSaver)
        XCTAssertTrue(caught, "blockNotFound exception not thrown")
    }

}
