import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderHandlerTests: XCTestCase {

    private var mockFactory: MockFactory!
    private var mockValidator: MockBlockValidator!
    private var mockBlockSyncer: MockBlockSyncer!
    private var headerHandler: HeaderHandler!

    private var realm: Realm!
    private var checkpointBlock: Block!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        mockFactory = mockWalletKit.mockFactory
        mockValidator = mockWalletKit.mockBlockValidator
        mockBlockSyncer = mockWalletKit.mockBlockSyncer
        realm = mockWalletKit.realm

        checkpointBlock = TestData.checkpointBlock

        stub(mockBlockSyncer) { mock in
            when(mock.enqueueRun()).thenDoNothing()
        }

        let mockNetwork = mockWalletKit.mockNetwork
        stub(mockNetwork) { mock in
            when(mock.checkpointBlock.get).thenReturn(checkpointBlock)
        }

        headerHandler = HeaderHandler(realmFactory: mockWalletKit.mockRealmFactory, factory: mockFactory, validator: mockValidator, blockSyncer: mockBlockSyncer, network: mockNetwork)
    }

    override func tearDown() {
        mockFactory = nil
        mockValidator = nil
        mockBlockSyncer = nil
        headerHandler = nil

        realm = nil
        checkpointBlock = nil

        super.tearDown()
    }

    func testSync_EmptyHeaders() {
        var caught = false

        do {
            try headerHandler.handle(headers: [])
        } catch let error as HeaderHandler.HandleError {
            caught = true
            XCTAssertEqual(error, HeaderHandler.HandleError.emptyHeaders)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "emptyHeaders exception not thrown")

        verify(mockBlockSyncer, never()).enqueueRun()
    }

    func testSync_NoBlocksInRealm() {
        let firstBlock = TestData.firstBlock

        stub(mockFactory) { mock in
            when(mock.block(withHeader: equal(to: firstBlock.header), previousBlock: equal(to: checkpointBlock))).thenReturn(firstBlock)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: firstBlock))).thenDoNothing()
        }

        try! headerHandler.handle(headers: [firstBlock.header])

        XCTAssertEqual(realm.objects(Block.self).count, 2)
        verify(mockBlockSyncer).enqueueRun()
    }

    func testValidBlocks() {
        let thirdBlock = TestData.thirdBlock
        let secondBlock = thirdBlock.previousBlock!
        let firstBlock = secondBlock.previousBlock!

        try! realm.write {
            realm.add(firstBlock)
        }

        stub(mockFactory) { mock in
            when(mock.block(withHeader: equal(to: secondBlock.header), previousBlock: equal(to: firstBlock))).thenReturn(secondBlock)
            when(mock.block(withHeader: equal(to: thirdBlock.header), previousBlock: equal(to: secondBlock))).thenReturn(thirdBlock)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: secondBlock))).thenDoNothing()
            when(mock.validate(block: equal(to: thirdBlock))).thenDoNothing()
        }

        try! headerHandler.handle(headers: [secondBlock.header, thirdBlock.header])

        XCTAssertNotEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", secondBlock.reversedHeaderHashHex).first, nil)
        XCTAssertNotEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", thirdBlock.reversedHeaderHashHex).first, nil)

        verify(mockBlockSyncer).enqueueRun()
    }

    func testInvalidBlocks() {
        let thirdBlock = TestData.thirdBlock
        let secondBlock = thirdBlock.previousBlock!
        let firstBlock = secondBlock.previousBlock!

        try! realm.write {
            realm.add(firstBlock)
        }

        stub(mockFactory) { mock in
            when(mock.block(withHeader: equal(to: secondBlock.header), previousBlock: equal(to: firstBlock))).thenReturn(secondBlock)
            when(mock.block(withHeader: equal(to: thirdBlock.header), previousBlock: equal(to: secondBlock))).thenReturn(thirdBlock)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: secondBlock))).thenThrow(BlockValidator.ValidatorError.notEqualBits)
            when(mock.validate(block: equal(to: thirdBlock))).thenDoNothing()
        }

        var caught = false

        do {
            try headerHandler.handle(headers: [secondBlock.header, thirdBlock.header])
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.notEqualBits)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "validation exception not thrown")
        verify(mockBlockSyncer, never()).enqueueRun()
    }

    func testPartialValidBlocks() {
        let thirdBlock = TestData.thirdBlock
        let secondBlock = thirdBlock.previousBlock!
        let firstBlock = secondBlock.previousBlock!

        try! realm.write {
            realm.add(firstBlock)
        }

        stub(mockFactory) { mock in
            when(mock.block(withHeader: equal(to: secondBlock.header), previousBlock: equal(to: firstBlock))).thenReturn(secondBlock)
            when(mock.block(withHeader: equal(to: thirdBlock.header), previousBlock: equal(to: secondBlock))).thenReturn(thirdBlock)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: secondBlock))).thenDoNothing()
            when(mock.validate(block: equal(to: thirdBlock))).thenThrow(BlockValidator.ValidatorError.notEqualBits)
        }

        var caught = false

        do {
            try headerHandler.handle(headers: [secondBlock.header, thirdBlock.header])
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.notEqualBits)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "validation exception not thrown")
        verify(mockBlockSyncer).enqueueRun()
    }

    func testGetValidBlocks() {
        let thirdBlock = TestData.thirdBlock
        let secondBlock = thirdBlock.previousBlock!
        let firstBlock = secondBlock.previousBlock!

        try! realm.write {
            realm.add(firstBlock)
        }

        stub(mockFactory) { mock in
            when(mock.block(withHeader: equal(to: secondBlock.header), previousBlock: equal(to: firstBlock))).thenReturn(secondBlock)
            when(mock.block(withHeader: equal(to: thirdBlock.header), previousBlock: equal(to: secondBlock))).thenReturn(thirdBlock)
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: secondBlock))).thenDoNothing()
            when(mock.validate(block: equal(to: thirdBlock))).thenDoNothing()
        }

        let validBlocks = headerHandler.getValidBlocks(headers: [secondBlock.header, thirdBlock.header], realm: realm)

        XCTAssertEqual(validBlocks.blocks[0].headerHash, secondBlock.headerHash)
        XCTAssertEqual(validBlocks.blocks[1].headerHash, thirdBlock.headerHash)
        XCTAssertNil(validBlocks.error)
    }

}
