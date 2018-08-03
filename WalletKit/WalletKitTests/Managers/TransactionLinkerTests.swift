import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionLinkerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var linker: TransactionLinker!

    private var realm: Realm!
    private var transaction: Transaction!
    private var rawTransaction: String!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        linker = TransactionLinker(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        rawTransaction = "0100000001865c106cd7a90c80e5447f6e2891aaf5a0d11fb29e1a9258dce26da7ef04c028000000004847304402205c54aa165861bf5347683fb078a99188726ee2577e3554d0f77ad7c60a4b072902206f77f42f216e4c64585a60ec76a944fc83278524e5a0dfda31b58f94035d27be01ffffffff01806de7290100000017a914121e63ee09fc7e20b59d144dcce6e2700f6f1a9c8700000000"
        transaction = Transaction.deserialize(Data(hex: rawTransaction)!)

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        linker = nil
        realm = nil

        super.tearDown()
    }

    func testLinkInputs() {
        let input = TransactionInput()
        input.previousOutputTxReversedHex = Data(hex: transaction.reversedHashHex)!
        input.previousOutputIndex = transaction.outputs.first!.index
        input.sequence = 100

        let savedNextTransaction = Transaction()
        savedNextTransaction.reversedHashHex = "0000000000000000000111111111111122222222222222333333333333333000"
        savedNextTransaction.inputs.append(input)

        try! realm.write {
            realm.add(transaction, update: true)
            realm.add(savedNextTransaction, update: true)
        }

        XCTAssertEqual(savedNextTransaction.inputs.first!.previousOutput, nil)
        try! linker.linkOutpoints(transaction: savedNextTransaction)
        assertOutputEqual(out1: savedNextTransaction.inputs.first!.previousOutput!, out2: transaction.outputs.first!)
    }

    func testLinkOutputs() {
        let output = TransactionOutput()
        output.index = transaction.inputs[0].previousOutputIndex
        output.value = 100000

        let savedPreviousTransaction = Transaction()
        savedPreviousTransaction.reversedHashHex = transaction.inputs[0].previousOutputTxReversedHex.hex
        savedPreviousTransaction.outputs.append(output)

        try! realm.write {
            realm.add(transaction, update: true)
            realm.add(savedPreviousTransaction, update: true)
        }

        XCTAssertEqual(transaction.inputs.first!.previousOutput, nil)
        try! linker.linkOutpoints(transaction: savedPreviousTransaction)
        assertOutputEqual(out1: transaction.inputs.first!.previousOutput!, out2: savedPreviousTransaction.outputs.first!)
    }

    private func assertOutputEqual(out1: TransactionOutput, out2: TransactionOutput) {
        XCTAssertEqual(out1.value, out2.value)
        XCTAssertEqual(out1.lockingScript, out2.lockingScript)
        XCTAssertEqual(out1.index, out2.index)
    }

}
