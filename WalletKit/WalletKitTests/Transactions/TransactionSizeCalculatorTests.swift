import XCTest
import Cuckoo
@testable import WalletKit

class TransactionSizeCalculatorTests: XCTestCase {
    var calculator: TransactionSizeCalculator!

    override func setUp() {
        super.setUp()

        calculator = TransactionSizeCalculator()
    }

    override func tearDown() {
        calculator = nil

        super.tearDown()
    }

    func testTransactionSize() {
        XCTAssertEqual(calculator.transactionSize(), 10)
    }

    func testInputSize() {
        XCTAssertEqual(calculator.inputSize(type: .p2pkh), 149)
        XCTAssertEqual(calculator.inputSize(type: .p2sh), 136)
        XCTAssertEqual(calculator.inputSize(type: .p2pk), 115)
    }

    func testOutputSize() {
        XCTAssertEqual(calculator.outputSize(type: .p2pkh), 34)
        XCTAssertEqual(calculator.outputSize(type: .p2sh), 32)
        XCTAssertEqual(calculator.outputSize(type: .p2pk), 44)
    }

}
