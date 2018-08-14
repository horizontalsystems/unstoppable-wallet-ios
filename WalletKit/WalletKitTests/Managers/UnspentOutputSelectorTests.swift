import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class UnspentOutputSelectorTests: XCTestCase {

    private var unspentOutputSelector: UnspentOutputSelector!
    private var outputs: [TransactionOutput]!

    override func setUp() {
        super.setUp()

        unspentOutputSelector = UnspentOutputSelector()
        outputs = [TransactionOutput(withValue: 1, index: 0, lockingScript: Data(), type: .unknown, keyHash: Data()),
                   TransactionOutput(withValue: 2, index: 0, lockingScript: Data(), type: .unknown, keyHash: Data()),
                   TransactionOutput(withValue: 4, index: 0, lockingScript: Data(), type: .unknown, keyHash: Data()),
                   TransactionOutput(withValue: 8, index: 0, lockingScript: Data(), type: .unknown, keyHash: Data()),
                   TransactionOutput(withValue: 16, index: 0, lockingScript: Data(), type: .unknown, keyHash: Data())
        ]
    }

    override func tearDown() {
        unspentOutputSelector = nil
        outputs = nil

        super.tearDown()
    }

    func testExactlyValue() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 4, outputs: outputs)
            XCTAssertEqual(selectedOutputs, [outputs[2]])
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testSummaryValue() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 11, outputs: outputs)
            XCTAssertEqual(selectedOutputs, [outputs[0], outputs[1], outputs[2], outputs[3]])
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testNotEnoughError() {
        do {
            _ = try unspentOutputSelector.select(value: 35, outputs: outputs)
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputSelector.SelectorError {
            XCTAssertEqual(error, UnspentOutputSelector.SelectorError.notEnough)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

    func testEmptyOutputsError() {
        do {
            _ = try unspentOutputSelector.select(value: 35, outputs: [])
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputSelector.SelectorError {
            XCTAssertEqual(error, UnspentOutputSelector.SelectorError.emptyOutputs)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

}
