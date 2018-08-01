import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionHandlerTests: XCTestCase {
    private var mockRealmFactory: MockRealmFactory!
    private var mockValidator: MockTransactionValidator!
    private var mockSaver: MockTransactionSaver!
    private var transactionHandler: TransactionHandler!

    private var realm: Realm!
    private var transaction: Transaction!
    private var sampleTransaction: Transaction!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockTransactionValidator()
        mockSaver = MockTransactionSaver()
        transactionHandler = TransactionHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        transaction = Transaction()
        transaction.reversedHashHex = Data(hex: "3e7f350bf5c2169833ad02e8ada93a5d47862fe708cdd6c9fb4c15af59e50f70")!.reversedHex

        var txInput = TransactionInput()
        txInput.previousOutputTxReversedHex = Data(hex: "28c004efa76de2dc58921a9eb21fd1a0f5aa91286e7f44e5800ca9d76c105c86")!
        txInput.previousOutputIndex = 0
        txInput.signatureScript = Data(hex: "47304402205c54aa165861bf5347683fb078a99188726ee2577e3554d0f77ad7c60a4b072902206f77f42f216e4c64585a60ec76a944fc83278524e5a0dfda31b58f94035d27be01")!
        txInput.sequence = 4294967295

        var txOutput = TransactionOutput()
        txOutput.value = 4998000000
        txOutput.lockingScript = Data(hex: "a914121e63ee09fc7e20b59d144dcce6e2700f6f1a9c87")!

        sampleTransaction = Transaction()
        sampleTransaction.version = 1
        sampleTransaction.lockTime = 0
        sampleTransaction.inputs.append(txInput)
        sampleTransaction.outputs.append(txOutput)

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.save(transaction: any(), toExistingTransaction: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockValidator = nil
        mockSaver = nil
        transactionHandler = nil

        realm = nil
        transaction = nil

        super.tearDown()
    }

    func testValidTransaction() {
        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleTransaction))).thenDoNothing()
        }

        try! transactionHandler.handle(transaction: sampleTransaction)
        verify(mockSaver).save(transaction: equal(to: sampleTransaction), toExistingTransaction: equal(to: nil))
    }

    func testWithExistingTransaction() {
        try? realm.write {
            realm.add([transaction], update: true)
        }

        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleTransaction))).thenDoNothing()
        }

        try! transactionHandler.handle(transaction: sampleTransaction)
        verify(mockSaver).save(transaction: equal(to: sampleTransaction), toExistingTransaction: equal(to: transaction))
    }

    func testWithInvalidTransaction() {
        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleTransaction))).thenThrow(TransactionValidator.ValidationError.doesNotBelongToCurrentWallet)
        }

        try? transactionHandler.handle(transaction: sampleTransaction)
        verifyNoMoreInteractions(mockSaver)
    }

}
