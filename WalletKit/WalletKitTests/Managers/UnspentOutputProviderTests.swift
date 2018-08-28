import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class UnspentOutputProviderTests: XCTestCase {

    private var realm: Realm!

    private var outputs: [TransactionOutput]!
    private var unspentOutputProvider: UnspentOutputProvider!
    private var pubKey: PublicKey!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        realm = mockWalletKit.realm

        pubKey = TestData.pubKey()

        unspentOutputProvider = UnspentOutputProvider(realmFactory: mockWalletKit.mockRealmFactory)
        outputs = [TransactionOutput(withValue: 1, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data(hex: "000010000")!),
                   TransactionOutput(withValue: 2, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data(hex: "000010001")!),
                   TransactionOutput(withValue: 4, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data(hex: "000010002")!),
                   TransactionOutput(withValue: 8, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data(hex: "000010003")!),
                   TransactionOutput(withValue: 16, index: 0, lockingScript: Data(), type: .p2sh, keyHash: Data(hex: "000010004")!)
        ]
    }

    override func tearDown() {
        realm = nil

        unspentOutputProvider = nil
        outputs = nil
        pubKey = nil

        super.tearDown()
    }

    func testValidOutputs() {
        outputs.forEach { $0.publicKey = pubKey }

        let transaction = Transaction(version: 0, inputs: [], outputs: outputs)
        try? realm.write {
            realm.add(transaction, update: true)
        }
        let inputTransaction = Transaction(version: 0, inputs: inputsWithPreviousOutputs(range: 0..<1), outputs: [])
        try? realm.write {
            realm.add(inputTransaction, update: true)
        }
        let unspentOutputs = unspentOutputProvider.allUnspentOutputs()
        XCTAssertEqual(unspentOutputs[0].keyHash, outputs[2].keyHash)
        XCTAssertEqual(unspentOutputs[1].keyHash, outputs[3].keyHash)
    }

    func testEmptyMineOutputs() {
        let transaction = Transaction(version: 0, inputs: [], outputs: outputs)
        try? realm.write {
            realm.add(transaction, update: true)
        }
        let inputTransaction = Transaction(version: 0, inputs: inputsWithPreviousOutputs(range: 3..<4), outputs: [])
        try? realm.write {
            realm.add(inputTransaction, update: true)
        }
        let unspentOutputs = unspentOutputProvider.allUnspentOutputs()
        XCTAssertEqual(unspentOutputs.count, 0)
    }

    func testEmptyValidScriptOutputs() {
        outputs.forEach {
            $0.publicKey = pubKey
            $0.scriptType = .p2sh
        }
        let transaction = Transaction(version: 0, inputs: [], outputs: outputs)
        try? realm.write {
            realm.add(transaction, update: true)
        }
        let inputTransaction = Transaction(version: 0, inputs: inputsWithPreviousOutputs(range: 0..<1), outputs: [])
        try? realm.write {
            realm.add(inputTransaction, update: true)
        }
        let unspentOutputs = unspentOutputProvider.allUnspentOutputs()
        XCTAssertEqual(unspentOutputs.count, 0)
    }

    func testEmptyValidInputOutputs() {
        outputs.forEach {
            $0.publicKey = pubKey
        }
        let transaction = Transaction(version: 0, inputs: [], outputs: outputs)
        try? realm.write {
            realm.add(transaction, update: true)
        }
        let inputTransaction = Transaction(version: 0, inputs: inputsWithPreviousOutputs(range: 0..<4), outputs: [])
        try? realm.write {
            realm.add(inputTransaction, update: true)
        }
        let unspentOutputs = unspentOutputProvider.allUnspentOutputs()
        XCTAssertEqual(unspentOutputs.count, 0)
    }

    private func inputsWithPreviousOutputs(range: Range<Int>) -> [TransactionInput] {
        let transaction = outputs[0].transaction!
        var inputs = [TransactionInput]()
        for i in range.lowerBound..<range.upperBound {
            let input = TestData.transactionInput(previousTransaction: transaction, previousOutput: outputs[i], script: Data(), sequence: 2)
            inputs.append(input)
        }
        return inputs
    }

}
