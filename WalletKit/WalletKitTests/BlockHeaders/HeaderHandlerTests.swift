import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderHandlerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockBlockFactory: MockBlockFactory!
    private var mockValidator: MockBlockValidator!
    private var mockSaver: MockBlockSaver!
    private var mockConfiguration: MockConfigurationManager!
    private var mockNetwork: MockNetworkProtocol!
    private var headerHandler: HeaderHandler!

    private var realm: Realm!
    private var checkpointBlock: Block!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockBlockFactory = MockBlockFactory()
        mockValidator = MockBlockValidator()
        mockSaver = MockBlockSaver()
        mockConfiguration = MockConfigurationManager()
        mockNetwork = MockNetworkProtocol()

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        checkpointBlock = TestData.checkpointBlock

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.create(blocks: any())).thenDoNothing()
        }
        stub(mockConfiguration) { mock in
            when(mock.network.get).thenReturn(mockNetwork)
        }
        stub(mockNetwork) { mock in
            when(mock.checkpointBlock.get).thenReturn(checkpointBlock)
        }

        headerHandler = HeaderHandler(realmFactory: mockRealmFactory, blockFactory: mockBlockFactory, validator: mockValidator, saver: mockSaver, configuration: mockConfiguration)
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockBlockFactory = nil
        mockValidator = nil
        mockSaver = nil
        mockConfiguration = nil
        mockNetwork = nil
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

        verifyNoMoreInteractions(mockSaver)
        XCTAssertTrue(caught, "emptyHeaders exception not thrown")
    }

    func testSync_NoBlocksInRealm() {
        let firstBlock = TestData.firstBlock

        stub(mockBlockFactory) { mock in
            when(mock.blocks(fromHeaders: equal(to: [firstBlock.header]), initialBlock: equal(to: checkpointBlock))).thenReturn([firstBlock])
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: firstBlock))).thenDoNothing()
        }

        try! headerHandler.handle(headers: [firstBlock.header])
        verify(mockSaver).create(blocks: equal(to: [firstBlock]))
    }

    func testValidBlocks() {
        let thirdBlock = TestData.thirdBlock
        let secondBlock = thirdBlock.previousBlock!
        let firstBlock = secondBlock.previousBlock!

        try! realm.write {
            realm.add(firstBlock)
        }

        stub(mockBlockFactory) { mock in
            when(mock.blocks(fromHeaders: equal(to: [secondBlock.header, thirdBlock.header]), initialBlock: equal(to: firstBlock))).thenReturn([secondBlock, thirdBlock])
        }
        stub(mockValidator) { mock in
            when(mock.validate(block: equal(to: secondBlock))).thenDoNothing()
            when(mock.validate(block: equal(to: thirdBlock))).thenDoNothing()
        }

        try! headerHandler.handle(headers: [secondBlock.header, thirdBlock.header])
        verify(mockSaver).create(blocks: equal(to: [secondBlock, thirdBlock]))
    }

    func testInvalidBlocks() {
        let thirdBlock = TestData.thirdBlock
        let secondBlock = thirdBlock.previousBlock!
        let firstBlock = secondBlock.previousBlock!

        try! realm.write {
            realm.add(firstBlock)
        }

        stub(mockBlockFactory) { mock in
            when(mock.blocks(fromHeaders: equal(to: [secondBlock.header, thirdBlock.header]), initialBlock: equal(to: firstBlock))).thenReturn([secondBlock, thirdBlock])
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

        verifyNoMoreInteractions(mockSaver)
        XCTAssertTrue(caught, "validation exception not thrown")
    }

    func testPartialValidBlocks() {
        let thirdBlock = TestData.thirdBlock
        let secondBlock = thirdBlock.previousBlock!
        let firstBlock = secondBlock.previousBlock!

        try! realm.write {
            realm.add(firstBlock)
        }

        stub(mockBlockFactory) { mock in
            when(mock.blocks(fromHeaders: equal(to: [secondBlock.header, thirdBlock.header]), initialBlock: equal(to: firstBlock))).thenReturn([secondBlock, thirdBlock])
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

        verify(mockSaver).create(blocks: equal(to: [secondBlock]))
        XCTAssertTrue(caught, "validation exception not thrown")
    }

}
