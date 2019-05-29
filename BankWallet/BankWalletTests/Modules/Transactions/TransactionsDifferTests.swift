import XCTest
import Cuckoo
@testable import Bank_Dev_T

class TransactionsDifferTests: XCTestCase {
    private var mockViewItemDelegate: MockITransactionViewItemDataSourceDelegate!
    private var state: TransactionsDifferState!

    private var differ: TransactionsDiffer!

    override func setUp() {
        super.setUp()

        mockViewItemDelegate = MockITransactionViewItemDataSourceDelegate()
        state = TransactionsDifferState()
        differ = TransactionsDiffer(state: state)
        differ.viewItemDelegate = mockViewItemDelegate
    }

    override func tearDown() {
        mockViewItemDelegate = nil
        differ = nil

        super.tearDown()
    }

}
