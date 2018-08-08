import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionHandlerTests: XCTestCase {
    private var mockRealmFactory: MockRealmFactory!
    private var mockExtractor: MockTransactionExtractor!
    private var mockSaver: MockTransactionSaver!
    private var mockLinker: MockTransactionLinker!
    private var transactionHandler: TransactionHandler!

    private var realm: Realm!
    private var oldTransaction: Transaction!
    private var transaction: Transaction!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }
        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        mockExtractor = MockTransactionExtractor()
        mockSaver = MockTransactionSaver()
        mockLinker = MockTransactionLinker(realmFactory: mockRealmFactory)
        transactionHandler = TransactionHandler(realmFactory: mockRealmFactory, extractor: mockExtractor, saver: mockSaver, linker: mockLinker)

        oldTransaction = Transaction()
        oldTransaction.reversedHashHex = Data(hex: "3e7f350bf5c2169833ad02e8ada93a5d47862fe708cdd6c9fb4c15af59e50f70")!.reversedHex
        oldTransaction.block = BlockFactory.shared.block(withHeader: TestHelper.checkpointBlockHeader, height: 1)

        let txInput = TransactionInput()
        txInput.previousOutputTxReversedHex = Data(hex: "28c004efa76de2dc58921a9eb21fd1a0f5aa91286e7f44e5800ca9d76c105c86")!
        txInput.previousOutputIndex = 0
        txInput.signatureScript = Data(hex: "47304402205c54aa165861bf5347683fb078a99188726ee2577e3554d0f77ad7c60a4b072902206f77f42f216e4c64585a60ec76a944fc83278524e5a0dfda31b58f94035d27be01")!
        txInput.sequence = 4294967295

        let txOutput = TransactionOutput()
        txOutput.value = 4998000000
        txOutput.lockingScript = Data(hex: "a914121e63ee09fc7e20b59d144dcce6e2700f6f1a9c87")!

        transaction = TransactionFactory.shared.transaction(withReversedHashHex: oldTransaction.reversedHashHex)
        transaction.version = 1
        transaction.lockTime = 0
        transaction.inputs.append(txInput)
        transaction.outputs.append(txOutput)

        stub(mockSaver) { mock in
            when(mock.save(transaction: any())).thenDoNothing()
        }
        stub(mockLinker) { mock in
            when(mock.handle(transaction: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockExtractor = nil
        mockSaver = nil
        transactionHandler = nil

        realm = nil
        oldTransaction = nil

        super.tearDown()
    }

    func testValidTransaction() {
        stub(mockExtractor) { mock in
            when(mock.extract(message: equal(to: transaction))).thenDoNothing()
        }

        try! transactionHandler.handle(transaction: transaction)
        verify(mockSaver).save(transaction: equal(to: transaction))
        verify(mockLinker).handle(transaction: equal(to: transaction))
        XCTAssertEqual(transaction.block, nil)
    }

    func testWithExistingTransaction() {
        try? realm.write {
            realm.add(oldTransaction, update: true)
        }

        stub(mockExtractor) { mock in
            when(mock.extract(message: equal(to: transaction))).thenDoNothing()
        }

        try! transactionHandler.handle(transaction: transaction)
        verify(mockSaver).save(transaction: equal(to: transaction))
        verify(mockLinker).handle(transaction: equal(to: transaction))
        XCTAssertEqual(transaction.block, oldTransaction.block)
    }

    func testWithInvalidTransaction() {
        stub(mockExtractor) { mock in
            when(mock.extract(message: equal(to: transaction))).thenThrow(TransactionExtractor.ExtractionError.invalid)
        }

        try? transactionHandler.handle(transaction: transaction)
        verifyNoMoreInteractions(mockSaver)
        verifyNoMoreInteractions(mockLinker)
    }

}
