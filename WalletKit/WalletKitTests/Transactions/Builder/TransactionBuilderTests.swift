import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionBuilderTests: XCTestCase{

    private var realm: Realm!
    private var mockRealmFactory: MockRealmFactory!
    private var mockUnspentOutputsManager: MockUnspentOutputsManager!
    private var mockInputSigner: MockInputSigner!
    private var mockTxFactory: MockTransactionFactory!
    private var mockTxInputFactory: MockTransactionInputFactory!
    private var mockTxOutputFactory: MockTransactionOutputFactory!

    private var transactionBuilder: TransactionBuilder!

    private var unspentOutputs: [TransactionOutput]!
    private var transaction: Transaction!
    private var toOutput: TransactionOutput!
    private var changeOutput: TransactionOutput!
    private var input: TransactionInput!
    private var totalInputValue: Int!
    private var value: Int!
    private var feeRate: Int!
    private var fee: Int!
    private var changeAddress: Address!
    private var toAddress: Address!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write {
            realm.deleteAll()
        }
        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        mockUnspentOutputsManager = MockUnspentOutputsManager()
        mockInputSigner = MockInputSigner()
        mockTxFactory = MockTransactionFactory()
        mockTxInputFactory = MockTransactionInputFactory()
        mockTxOutputFactory = MockTransactionOutputFactory()

        transactionBuilder = TransactionBuilder(
                realmFactory: mockRealmFactory, unspentOutputSelector: mockUnspentOutputsManager, inputSigner: mockInputSigner,
                txFactory: mockTxFactory, txInputFactory: mockTxInputFactory, txOutputFactory: mockTxOutputFactory
        )

        changeAddress = TestData.address()
        toAddress = TestData.address(pubKeyHash: Data(hex: "64d8fbe748c577bb5da29718dae0402b0b5dd523")!)

        let previousTransaction = TestData.p2pkhTransaction
        try! realm.write {
            realm.add(previousTransaction, update: true)
        }

        unspentOutputs = [previousTransaction.outputs[0]]
        totalInputValue = unspentOutputs[0].value
        value = 10782000
        feeRate = 6
        fee = 1158

        transaction = TransactionFactory.shared.transaction(version: 1, inputs: [], outputs: [])
        input = TransactionInputFactory.shared.transactionInput(withPreviousOutput: unspentOutputs[0], script: Data(), sequence: 0)
        toOutput = try? TransactionOutputFactory.shared.transactionOutput(withValue: value - fee, withIndex: 0, forAddress: toAddress, type: .p2pkh)
        changeOutput = try? TransactionOutputFactory.shared.transactionOutput(withValue: totalInputValue - value, withIndex: 0, forAddress: changeAddress, type: .p2pkh)

        stub(mockUnspentOutputsManager) { mock in
            when(mock.select(value: any(), outputs: any())).thenReturn(unspentOutputs)
        }

        stub(mockInputSigner) { mock in
            when(mock.signature(input: any(), transaction: any(), index: any())).thenReturn(Data())
        }

        stub(mockTxFactory) { mock in
            when(mock.transaction(version: any(), inputs: any(), outputs: any(), lockTime: any())).thenReturn(transaction)
        }

        stub(mockTxInputFactory) { mock in
            when(mock.transactionInput(withPreviousOutput: any(), script: any(), sequence: any())).thenReturn(input)
        }

        stub(mockTxOutputFactory) { mock in
            when(mock.transactionOutput(withValue: any(), withIndex: any(), forAddress: equal(to: toAddress), type: equal(to: ScriptType.p2pkh))).thenReturn(toOutput)
            when(mock.transactionOutput(withValue: any(), withIndex: any(), forAddress: equal(to: changeAddress), type: equal(to: ScriptType.p2pkh))).thenReturn(changeOutput)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        realm = nil
        unspentOutputs = nil
        mockUnspentOutputsManager = nil
        mockInputSigner = nil
        mockTxFactory = nil
        mockTxInputFactory = nil
        mockTxOutputFactory = nil
        transactionBuilder = nil
        changeAddress = nil
        toAddress = nil
        value = nil
        feeRate = nil
        fee = nil

        super.tearDown()
    }

    func testBuildTransaction() {
        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 2)
        XCTAssertEqual(resultTx.outputs[0].keyHash, toAddress.publicKeyHash)
        XCTAssertEqual(resultTx.outputs[0].value, 10780842)  // value - fee
        XCTAssertEqual(resultTx.outputs[1].keyHash, changeAddress.publicKeyHash)
        XCTAssertEqual(resultTx.outputs[1].value, unspentOutputs[0].value - value)
    }

    func testWithoutChangeOutput() {
        value = value + 10000

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 1)
        XCTAssertEqual(resultTx.outputs[0].keyHash, toAddress.publicKeyHash)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)
    }


}
