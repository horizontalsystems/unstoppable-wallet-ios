import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class SyncerTests: XCTestCase {

    class TestError: Error, CustomStringConvertible {
        private(set) var description: String = "test error"
    }

    private var mockRealmFactory: MockRealmFactory!
    private var mockLogger: MockLogger!
    private var mockHeaderSyncer: MockHeaderSyncer!
    private var mockHeaderHandler: MockHeaderHandler!
    private var mockTransactionHandler: MockTransactionHandler!
    private var mockFactory: MockFactory!
    private var syncer: Syncer!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        DefaultValueRegistry.register(value: TestNet(), forType: NetworkProtocol.self)

        let mockWalletKit = MockWalletKit()

        mockLogger = mockWalletKit.mockLogger
        mockHeaderSyncer = mockWalletKit.mockHeaderSyncer
        mockHeaderHandler = mockWalletKit.mockHeaderHandler
        mockFactory = mockWalletKit.mockFactory
        mockTransactionHandler = mockWalletKit.mockTransactionHandler
        realm = mockWalletKit.realm

        stub(mockLogger) { mock in
            when(mock.log(tag: any(), message: any())).thenDoNothing()
        }
        stub(mockHeaderSyncer) { mock in
            when(mock.sync()).thenDoNothing()
        }
        stub(mockHeaderHandler) { mock in
            when(mock.handle(headers: any())).thenDoNothing()
        }
        stub(mockTransactionHandler) { mock in
            when(mock.handle(blockTransactions: any(), blockHeader: any())).thenDoNothing()
            when(mock.handle(memPoolTransactions: any())).thenDoNothing()
        }

        syncer = Syncer(logger: mockLogger, realmFactory: mockWalletKit.mockRealmFactory)
        syncer.headerSyncer = mockHeaderSyncer
        syncer.headerHandler = mockHeaderHandler
        syncer.transactionHandler = mockTransactionHandler
    }

    override func tearDown() {
        mockLogger = nil
        mockHeaderSyncer = nil
        mockHeaderHandler = nil
        mockTransactionHandler = nil
        mockFactory = nil
        syncer = nil

        realm = nil

        super.tearDown()
    }

    func testRunHeaderSyncerOnConnect() {
        syncer.peerGroupDidConnect()
        verify(mockHeaderSyncer).sync()
    }

    func testRunHeaderSyncerOnConnect_Error() {
        let error = TestError()

        stub(mockHeaderSyncer) { mock in
            when(mock.sync()).thenThrow(error)
        }

        syncer.peerGroupDidConnect()
        verify(mockLogger).log(tag: "Header Syncer Error", message: "\(error)")
    }

    func testRunHeaderHandler() {
        let headers: [BlockHeader] = [TestData.firstBlock.header, TestData.secondBlock.header]

        syncer.peerGroupDidReceive(headers: headers)

        verify(mockHeaderHandler).handle(headers: equal(to: headers))
    }

    func testRunHeaderHandler_Error() {
        let error = TestError()

        stub(mockHeaderHandler) { mock in
            when(mock.handle(headers: any())).thenThrow(error)
        }

        let headers: [BlockHeader] = [TestData.firstBlock.header, TestData.secondBlock.header]

        syncer.peerGroupDidReceive(headers: headers)

        verify(mockLogger).log(tag: "Header Handler Error", message: "\(error)")
    }

    func testRunTransactions() {
        let blockHeader = TestData.checkpointBlock.header!
        let transaction = TestData.p2pkhTransaction

        syncer.peerGroupDidReceive(blockHeader: blockHeader, withTransactions: [transaction])
        verify(mockTransactionHandler).handle(blockTransactions: equal(to: [transaction]), blockHeader: equal(to: blockHeader))
    }

    func testRunTransactions_Error() {
        let error = TestError()
        stub(mockTransactionHandler) { mock in
            when(mock.handle(blockTransactions: any(), blockHeader: any())).thenThrow(error)
        }

        let blockHeader = TestData.checkpointBlock.header!
        let transaction = TestData.p2pkhTransaction

        syncer.peerGroupDidReceive(blockHeader: blockHeader, withTransactions: [transaction])
        verify(mockLogger).log(tag: "Transaction Handler Error", message: "\(error)")
    }

    func testRunTransactionHandler() {
        let transaction = TestData.p2pkhTransaction
        syncer.peerGroupDidReceive(transaction: transaction)

        verify(mockTransactionHandler).handle(memPoolTransactions: equal(to: [transaction]))
    }

    func testRunTransactionHandler_Error() {
        let error = TestError()

        stub(mockTransactionHandler) { mock in
            when(mock.handle(memPoolTransactions: any())).thenThrow(error)
        }

        let transaction = TestData.p2pkhTransaction
        syncer.peerGroupDidReceive(transaction: transaction)

        verify(mockLogger).log(tag: "Transaction Handler Error", message: "\(error)")
    }

    func testShouldRequest_TransactionExists() {
        let transaction = TestData.p2pkhTransaction
        let inventoryItem = InventoryItem(type: InventoryItem.ObjectType.transaction.rawValue, hash: transaction.reversedHashHex.reversedData!)

        try! realm.write {
            realm.add(transaction)
        }

        XCTAssertEqual(syncer.shouldRequest(inventoryItem: inventoryItem), false)
    }

    func testShouldRequest_TransactionDoesntExists() {
        let transaction = TestData.p2pkhTransaction
        let inventoryItem = InventoryItem(type: InventoryItem.ObjectType.transaction.rawValue, hash: transaction.reversedHashHex.reversedData!)

        XCTAssertEqual(syncer.shouldRequest(inventoryItem: inventoryItem), true)
    }

    func testShouldRequest_BlockExists() {
        let block = TestData.firstBlock
        let inventoryItem = InventoryItem(type: InventoryItem.ObjectType.blockMessage.rawValue, hash: block.reversedHeaderHashHex.reversedData!)

        try! realm.write {
            realm.add(block)
        }

        XCTAssertEqual(syncer.shouldRequest(inventoryItem: inventoryItem), false)
    }

    func testShouldRequest_BlockDoesntExists() {
        let block = TestData.firstBlock
        let inventoryItem = InventoryItem(type: InventoryItem.ObjectType.blockMessage.rawValue, hash: block.reversedHeaderHashHex.reversedData!)

        XCTAssertEqual(syncer.shouldRequest(inventoryItem: inventoryItem), true)
    }

    func testShouldRequest_UnhandledItems() {
        let items = [
            InventoryItem(type: InventoryItem.ObjectType.filteredBlockMessage.rawValue, hash: Data()),
            InventoryItem(type: InventoryItem.ObjectType.compactBlockMessage.rawValue, hash: Data()),
            InventoryItem(type: InventoryItem.ObjectType.unknown.rawValue, hash: Data()),
            InventoryItem(type: InventoryItem.ObjectType.error.rawValue, hash: Data())
        ]

        for item in items {
            XCTAssertEqual(syncer.shouldRequest(inventoryItem: item), false)
        }
    }

    func testTransaction() {
        let transaction = TestData.p2pkhTransaction

        try! realm.write {
            realm.add(transaction)
        }

        let tx = syncer.transaction(forHash: transaction.reversedHashHex.reversedData!)
        XCTAssertEqual(tx?.reversedHashHex, transaction.reversedHashHex)
    }

    func testTransaction_NoTransaction() {
        let transaction = TestData.p2pkhTransaction
        let tx = syncer.transaction(forHash: transaction.reversedHashHex.reversedData!)
        XCTAssertEqual(tx, nil)
    }

}
