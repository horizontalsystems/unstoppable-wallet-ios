import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionBuilderTests: XCTestCase{

    private var realm: Realm!
    private var mockRealmFactory: MockRealmFactory!
    private var mockUnspentOutputSelector: MockUnspentOutputSelector!
    private var mockUnspentOutputProvider: MockUnspentOutputProvider!
    private var mockAddressConverter: MockAddressConverter!
    private var mockInputSigner: MockInputSigner!
    private var mockScriptBuilder:  MockScriptBuilder!
    private var mockFactory: MockFactory!

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
    private var changePubKey: PublicKey!
    private var toAddress: String!

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

        mockUnspentOutputSelector = MockUnspentOutputSelector()
        mockUnspentOutputProvider = MockUnspentOutputProvider(realmFactory: mockRealmFactory)
        mockAddressConverter = MockAddressConverter(network: TestNet())
        mockInputSigner = MockInputSigner(hdWallet: HDWalletStub(seed: Data(), network: TestNet()))
        mockScriptBuilder = MockScriptBuilder()
        mockFactory = MockFactory()

        transactionBuilder = TransactionBuilder(unspentOutputSelector: mockUnspentOutputSelector, unspentOutputProvider: mockUnspentOutputProvider, addressConverter: mockAddressConverter, inputSigner: mockInputSigner, scriptBuilder: mockScriptBuilder, factory: mockFactory)

        changePubKey = TestData.pubKey()
        toAddress = "2QVLmkcuXLpmuRz9C8BiccAMujm4"

        let previousTransaction = TestData.p2pkhTransaction
        try! realm.write {
            realm.add(previousTransaction, update: true)
        }

        unspentOutputs = [previousTransaction.outputs[0]]
        totalInputValue = unspentOutputs[0].value
        value = 10782000
        feeRate = 6
        fee = 1008

        transaction = Transaction(version: 1, inputs: [], outputs: [])
        input = TransactionInput(withPreviousOutputTxReversedHex: previousTransaction.reversedHashHex, previousOutputIndex: unspentOutputs[0].index, script: Data(), sequence: 0)
        toOutput = TransactionOutput(withValue: value - fee, index: 0, lockingScript: Data(), type: .p2pkh, address: toAddress, keyHash: nil)
        changeOutput = TransactionOutput(withValue: totalInputValue - value, index: 1, lockingScript: Data(), type: .p2pkh, keyHash: changePubKey.keyHash)

        stub(mockUnspentOutputSelector) { mock in
            when(mock.select(value: any(), outputs: any())).thenReturn(unspentOutputs)
        }

        stub(mockUnspentOutputProvider) { mock in
            when(mock.allUnspentOutputs()).thenReturn(unspentOutputs)
        }

        stub(mockInputSigner) { mock in
            when(mock.sigScriptData(transaction: any(), index: any())).thenReturn([Data()])
        }

        stub(mockAddressConverter) { mock in
            when(mock.convert(address: any())).thenReturn(Data())
        }

        stub(mockScriptBuilder) { mock in
            when(mock.lockingScript(type: any(), params: any())).thenReturn(Data())
            when(mock.unlockingScript(params: any())).thenReturn(Data())
        }

        stub(mockFactory) { mock in
            when(mock.transaction(version: any(), inputs: any(), outputs: any(), lockTime: any())).thenReturn(transaction)
        }

        stub(mockFactory) { mock in
            when(mock.transactionInput(withPreviousOutputTxReversedHex: any(), previousOutputIndex: any(), script: any(), sequence: any())).thenReturn(input)
        }

        stub(mockFactory) { mock in
            when(mock.transactionOutput(withValue: any(), index: any(), lockingScript: any(), type: equal(to: ScriptType.p2pkh), address: equal(to: toAddress), keyHash: any(), publicKey: any())).thenReturn(toOutput)
            when(mock.transactionOutput(withValue: any(), index: any(), lockingScript: any(), type: equal(to: ScriptType.p2pkh), address: equal(to: changePubKey.address), keyHash: any(), publicKey: any())).thenReturn(changeOutput)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        realm = nil
        unspentOutputs = nil
        mockUnspentOutputSelector = nil
        mockUnspentOutputProvider = nil
        mockAddressConverter = nil
        mockInputSigner = nil
        mockFactory = nil
        transactionBuilder = nil
        changePubKey = nil
        toAddress = nil
        value = nil
        feeRate = nil
        fee = nil

        super.tearDown()
    }

    func testBuildTransaction() {
        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertNotEqual(resultTx.reversedHashHex, "")
        XCTAssertEqual(resultTx.status, .new)
        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 2)
        XCTAssertEqual(resultTx.outputs[0].address, toAddress)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)  // value - fee
        XCTAssertEqual(resultTx.outputs[1].keyHash, changePubKey.keyHash)
        XCTAssertEqual(resultTx.outputs[1].value, unspentOutputs[0].value - value)
    }

    func testWithoutChangeOutput() {
        value = totalInputValue

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 1)
        XCTAssertEqual(resultTx.outputs[0].address, toAddress)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)
    }

    func testChangeNotAddedForDust() {
        value = totalInputValue - TransactionBuilder.outputSize * feeRate

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 1)
        XCTAssertEqual(resultTx.outputs[0].address, toAddress)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)
    }

    func testInputsSigned() {
        let sigData = [Data(hex: "000001")!, Data(hex: "000002")!]
        let sigScript = Data(hex: "000001000002")!

        stub(mockInputSigner) { mock in
            when(mock.sigScriptData(transaction: any(), index: any())).thenReturn(sigData)
        }

        stub(mockScriptBuilder) { mock in
            when(mock.unlockingScript(params: any())).thenReturn(sigScript)
        }

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs[0].signatureScript, sigScript)
    }

}
