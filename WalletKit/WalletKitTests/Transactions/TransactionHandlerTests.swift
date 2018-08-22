import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionHandlerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockProcessor: MockTransactionProcessor!
    private var transactionHandler: TransactionHandler!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockProcessor = MockTransactionProcessor(realmFactory: mockRealmFactory, extractor: TransactionExtractorStub(scriptConverter: ScriptConverter(), addressConverter: AddressConverterStub(network: TestNet())), linker: TransactionLinkerStub(), logger: LoggerStub())

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockProcessor) { mock in
            when(mock.enqueueRun()).thenDoNothing()
        }

        transactionHandler = TransactionHandler(realmFactory: mockRealmFactory, processor: mockProcessor)
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockProcessor = nil
        transactionHandler = nil
        realm = nil

        super.tearDown()
    }

    func testHandleBlockTransactions() {
        let transaction = TestData.p2pkhTransaction
        let block = TestData.checkpointBlock

        try! realm.write {
            realm.add(block, update: true)
        }

        try! transactionHandler.handle(blockTransactions: [transaction], blockHeaderHash: block.headerHash)

        let realmBlock = realm.objects(Block.self).last!
        let realmTransaction = realm.objects(Transaction.self).last!

        assertTransactionEqual(tx1: transaction, tx2: realmTransaction)
        XCTAssertEqual(realmBlock.headerHash, block.headerHash)
        XCTAssertEqual(realmBlock.synced, true)
        XCTAssertEqual(realmTransaction.block, realmBlock)

        verify(mockProcessor).enqueueRun()
    }

    func testHandleBlockTransactions_EmptyTransactions() {
        let block = TestData.checkpointBlock

        try! realm.write {
            realm.add(block, update: true)
        }

        try! transactionHandler.handle(blockTransactions: [], blockHeaderHash: block.headerHash)

        verify(mockProcessor, never()).enqueueRun()
    }

    func testHandleMemPoolTransactions() {
        let transaction = TestData.p2pkhTransaction

        try! transactionHandler.handle(memPoolTransactions: [transaction])

        let realmTransaction = realm.objects(Transaction.self).last!
        assertTransactionEqual(tx1: transaction, tx2: realmTransaction)
        XCTAssertEqual(realmTransaction.block, nil)

        verify(mockProcessor).enqueueRun()
    }

    func testHandleMemPoolTransactions_EmptyTransactions() {
        try! transactionHandler.handle(memPoolTransactions: [])
        verify(mockProcessor, never()).enqueueRun()
    }

    private func assertTransactionEqual(tx1: Transaction, tx2: Transaction) {
        XCTAssertEqual(tx1, tx2)
        XCTAssertEqual(tx1.reversedHashHex, tx2.reversedHashHex)
        XCTAssertEqual(tx1.version, tx2.version)
        XCTAssertEqual(tx1.lockTime, tx2.lockTime)
        XCTAssertEqual(tx1.inputs.count, tx2.inputs.count)
        XCTAssertEqual(tx1.outputs.count, tx2.outputs.count)

        for i in 0..<tx1.inputs.count {
            XCTAssertEqual(tx1.inputs[i].previousOutputTxReversedHex, tx2.inputs[i].previousOutputTxReversedHex)
            XCTAssertEqual(tx1.inputs[i].previousOutputIndex, tx2.inputs[i].previousOutputIndex)
            XCTAssertEqual(tx1.inputs[i].signatureScript, tx2.inputs[i].signatureScript)
            XCTAssertEqual(tx1.inputs[i].sequence, tx2.inputs[i].sequence)
        }

        for i in 0..<tx2.outputs.count {
            assertOutputEqual(out1: tx1.outputs[i], out2: tx2.outputs[i])
        }
    }

    private func assertOutputEqual(out1: TransactionOutput, out2: TransactionOutput) {
        XCTAssertEqual(out1.value, out2.value)
        XCTAssertEqual(out1.lockingScript, out2.lockingScript)
        XCTAssertEqual(out1.index, out2.index)
    }

}
