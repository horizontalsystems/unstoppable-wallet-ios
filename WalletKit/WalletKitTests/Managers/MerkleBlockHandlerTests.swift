import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class MerkleBlockHandlerTests: XCTestCase {
    private var mockRealmFactory: MockRealmFactory!
    private var mockValidator: MockMerkleBlockValidator!
    private var mockSaver: MockBlockSaver!
    private var merkleBlockHandler: MerkleBlockHandler!

    private var realm: Realm!
    private var block: Block!
    private var blockHeaderItem: BlockHeaderItem!
    private var sampleMerkleBlockMessage: MerkleBlockMessage!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockMerkleBlockValidator()
        mockSaver = MockBlockSaver()
        merkleBlockHandler = MerkleBlockHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))

        block = Block()
        block.reversedHeaderHashHex = "00000000000025c23a19cc91ad8d3e33c2630ce1df594e1ae0bf0eabe30a9176"
        block.height = 2016

        blockHeaderItem = BlockHeaderItem(version: 536870912, prevBlock: "000000000000837bcdb53e7a106cf0e74bab6ae8bc96481243d31bea3e6b8c92".reversedData!, merkleRoot: "8beab73ba2318e4cbdb1c65624496bc3214d6ba93204e049fb46293a41880b9a".reversedData!, timestamp: 1506023937, bits: 453021074, nonce: 2001025151)
        sampleMerkleBlockMessage = MerkleBlockMessage(blockHeaderItem: blockHeaderItem, totalTransactions: 1, numberOfHashes: 1, hashes: [Data(hex: "0000000000000000000000000000000000000000000000000000000000000001")!], numberOfFlags: 0, flags: [])

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.update(block: any(), withTransactionHashes: any()).thenDoNothing())
        }
        stub(mockValidator) { mock in
            when(mock.txIds).get.thenReturn(sampleMerkleBlockMessage.hashes)
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

        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleMerkleBlockMessage))).thenDoNothing()
        }

        try! merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        verify(mockSaver).update(block: equal(to: block), withTransactionHashes: equal(to: sampleMerkleBlockMessage.hashes))
    }

    func testInvalidMerkleBlocks() {
        try! realm.write { realm.add(block) }

        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleMerkleBlockMessage))).thenThrow(MerkleBlockValidator.ValidationError.wrongMerkleRoot)
        }

        try? merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        verifyNoMoreInteractions(mockSaver)
    }

    func testSync_NoBlock() {
        var caught = false

        do {
            try merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        } catch let error as MerkleBlockHandler.HandleError {
            caught = true
            XCTAssertEqual(error, MerkleBlockHandler.HandleError.blockNotFound)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        verifyNoMoreInteractions(mockSaver)
        XCTAssertTrue(caught, "blockNotFound exception not thrown")
    }

    func testNoMatchedHashes() {
        try! realm.write { realm.add(block) }

        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleMerkleBlockMessage))).thenDoNothing()
            when(mock.txIds).get.thenReturn([])
        }

        try! merkleBlockHandler.handle(message: sampleMerkleBlockMessage)
        verifyNoMoreInteractions(mockSaver)
    }
}
