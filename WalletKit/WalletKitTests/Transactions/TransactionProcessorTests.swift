import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionProcessorTests: XCTestCase{
    private var mockRealmFactory: MockRealmFactory!
    private var mockExtractor: MockTransactionExtractor!
    private var mockLinker: MockTransactionLinker!
    private var mockLogger: MockLogger!
    private var transactionProcessor: TransactionProcessor!

    private var realm: Realm!
    private var pubKeys: Results<PublicKey>!
    private var oldTransaction: Transaction!
    private var transaction: Transaction!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write {
            realm.deleteAll()
        }
        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        mockExtractor = MockTransactionExtractor(addressConverter: AddressConverter(network: TestNet()))
        mockLinker = MockTransactionLinker()
        mockLogger = MockLogger()
        transactionProcessor = TransactionProcessor(extractor: mockExtractor, linker: mockLinker, logger: mockLogger)

        oldTransaction = Transaction()
        oldTransaction.reversedHashHex = Data(hex: "3e7f350bf5c2169833ad02e8ada93a5d47862fe708cdd6c9fb4c15af59e50f70")!.reversedHex
        oldTransaction.block = Block(withHeader: TestData.checkpointBlockHeader, height: 1)

        let txInput = TransactionInput()
        txInput.previousOutputTxReversedHex = "28c004efa76de2dc58921a9eb21fd1a0f5aa91286e7f44e5800ca9d76c105c86"
        txInput.previousOutputIndex = 0
        txInput.signatureScript = Data(hex: "47304402205c54aa165861bf5347683fb078a99188726ee2577e3554d0f77ad7c60a4b072902206f77f42f216e4c64585a60ec76a944fc83278524e5a0dfda31b58f94035d27be01")!
        txInput.sequence = 4294967295

        let txOutput = TransactionOutput()
        txOutput.value = 4998000000
        txOutput.lockingScript = Data(hex: "a914121e63ee09fc7e20b59d144dcce6e2700f6f1a9c87")!

        transaction = Transaction()
        transaction.reversedHashHex = oldTransaction.reversedHashHex
        transaction.version = 1
        transaction.lockTime = 0
        transaction.inputs.append(txInput)
        transaction.outputs.append(txOutput)

        pubKeys = realm.objects(PublicKey.self)

        stub(mockLinker) { mock in
            when(mock.handle(transaction: any(), realm: any(), pubKeys: any())).thenDoNothing()
        }
        stub(mockExtractor) { mock in
            when(mock.extract(transaction: equal(to: transaction))).thenDoNothing()
        }
        stub(mockLogger) { mock in
            when(mock.log(tag: any(), message: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockExtractor = nil
        mockLogger = nil
        mockLinker = nil
        transactionProcessor = nil

        realm = nil
        oldTransaction = nil

        super.tearDown()
    }

    func testTransactionProcessing() {
        try! realm.write {
            realm.add(transaction)
        }
        let transactions = realm.objects(Transaction.self).filter("processed = %@", false)

        transactionProcessor.process(realm: realm, transactions: transactions)
        verify(mockExtractor).extract(transaction: equal(to: transaction))
        verify(mockLinker).handle(transaction: equal(to: transaction), realm: equal(to: realm), pubKeys: any())
    }

    func testTransactionUpdate() {
        try! realm.write {
            realm.add(transaction)
        }
        let transactions = realm.objects(Transaction.self).filter("processed = %@", false)

        transactionProcessor.process(realm: realm, transactions: transactions)
        let realmTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).last!
        XCTAssertEqual(realmTransaction.processed, true)
    }

    func testProcessingError() {
        try! realm.write {
            realm.add(transaction)
        }
        let transactions = realm.objects(Transaction.self).filter("processed = %@", false)

        stub(mockExtractor) { mock in
            when(mock.extract(transaction: any())).thenThrow(TransactionExtractor.ExtractionError.invalid)
        }

        transactionProcessor.process(realm: realm, transactions: transactions)
        verify(mockLogger).log(tag: "Transaction Processor Error", message: any())
    }

}
