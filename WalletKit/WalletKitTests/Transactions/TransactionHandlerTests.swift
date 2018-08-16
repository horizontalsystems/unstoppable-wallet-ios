import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionHandlerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var transactionHandler: TransactionHandler!

    private var realm: Realm!
    private var transaction: Transaction!
    private var rawTransaction: String!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        transactionHandler = TransactionHandler(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        let txInput = TransactionInput()
        txInput.previousOutputTxReversedHex = "28c004efa76de2dc58921a9eb21fd1a0f5aa91286e7f44e5800ca9d76c105c86"
        txInput.previousOutputIndex = 0
        txInput.signatureScript = Data(hex: "47304402205c54aa165861bf5347683fb078a99188726ee2577e3554d0f77ad7c60a4b072902206f77f42f216e4c64585a60ec76a944fc83278524e5a0dfda31b58f94035d27be01")!
        txInput.sequence = 4294967295

        let txOutput = TransactionOutput()
        txOutput.value = 4998000000
        txOutput.lockingScript = Data(hex: "a914121e63ee09fc7e20b59d144dcce6e2700f6f1a9c87")!

        transaction = Transaction()
        transaction.reversedHashHex = Data(hex: "3e7f350bf5c2169833ad02e8ada93a5d47862fe708cdd6c9fb4c15af59e50f70")!.reversedHex
        transaction.version = 1
        transaction.lockTime = 0
        transaction.inputs.append(txInput)
        transaction.outputs.append(txOutput)

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        transactionHandler = nil
        realm = nil

        super.tearDown()
    }

    func testMerkleBlockTransactions() {
        let block = TestData.checkpointBlock
        try! realm.write {
            realm.add(block, update: true)
        }

        try! transactionHandler.handle(blockHeaderHash: block.headerHash, transactions: [transaction])
        let realmBlock = realm.objects(Block.self).last!
        let realmTransaction = realm.objects(Transaction.self).last!

        assertTransactionEqual(tx1: transaction, tx2: realmTransaction)
        XCTAssertEqual(realmBlock.headerHash, block.headerHash)
        XCTAssertEqual(realmBlock.synced, true)
    }

    func testHandleOneTransaction() {
        try! transactionHandler.handle(transaction: transaction)
        let realmTransaction = realm.objects(Transaction.self).last!

        assertTransactionEqual(tx1: transaction, tx2: realmTransaction)
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
