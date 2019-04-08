import XCTest
import Cuckoo
@testable import Bank_Dev_T

class TransactionViewItemFactoryTests: XCTestCase {
    private var factory: TransactionViewItemFactory!

    private let mineAddress1 = TransactionAddress(address: "mine1", mine: true)
    private let mineAddress2 = TransactionAddress(address: "mine2", mine: true)
    private let mineAddress3 = TransactionAddress(address: "mine3", mine: true)
    private let otherAddress1 = TransactionAddress(address: "other1", mine: false)
    private let otherAddress2 = TransactionAddress(address: "other2", mine: false)
    private let otherAddress3 = TransactionAddress(address: "other3", mine: false)

    override func setUp() {
        super.setUp()

        factory = TransactionViewItemFactory()
    }

    override func tearDown() {
        factory = nil

        super.tearDown()
    }

    func testTransactionHash() {
        let transactionHash = "hash"
        let item = transactionItem(transactionHash: transactionHash)

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertEqual(viewItem.transactionHash, transactionHash)
    }

    func testCoinValue() {
        let coinCode = "BTC"
        let coin = Coin(title: "Bitcoin", code: coinCode, type: .bitcoin)
        let amount: Decimal = 123.45
        let item = transactionItem(coin: coin, amount: amount)

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertEqual(viewItem.coinValue, CoinValue(coinCode: coinCode, value: amount))
    }

    func testCurrencyValue() {
        let currency = Currency(code: "USD", symbol: "")
        let amount: Decimal = 123.45
        let rateValue: Decimal = 9876.54
        let rate = CurrencyValue(currency: currency, value: rateValue)

        let item = transactionItem(amount: amount)

        let viewItem = factory.viewItem(fromItem: item, rate: rate)

        XCTAssertEqual(viewItem.currencyValue, CurrencyValue(currency: currency, value: rateValue * amount))
    }

    func testCurrencyValue_withoutRate() {
        let item = transactionItem()

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertNil(viewItem.currencyValue)
    }

    func testIncoming_positiveAmount() {
        let amount: Decimal = 123.45
        let item = transactionItem(amount: amount)

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertTrue(viewItem.incoming)
    }

    func testIncoming_negativeAmount() {
        let amount: Decimal = -123.45
        let item = transactionItem(amount: amount)

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertFalse(viewItem.incoming)
    }

    func testDate() {
        let date = Date()
        let item = transactionItem(date: date)

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertEqual(viewItem.date, date)
    }

    func testStatus_noBlockHeight() {
        let item = transactionItem(blockHeight: nil)

        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: 1234)

        XCTAssertEqual(viewItem.status, TransactionStatus.pending)
    }

    func testStatus_noLastBlockHeight() {
        let item = transactionItem(blockHeight: 1234)

        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: nil)

        XCTAssertEqual(viewItem.status, TransactionStatus.pending)
    }

    func testStatus_completed() {
        let threshold = 6
        let blockHeight = 1234
        let item = transactionItem(blockHeight: blockHeight)

        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: blockHeight + threshold, threshold: threshold)

        XCTAssertEqual(viewItem.status, TransactionStatus.completed)
    }

    func testStatus_processing_sameBlock() {
        let threshold = 6
        let blockHeight = 1234
        let item = transactionItem(blockHeight: blockHeight)

        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: blockHeight, threshold: threshold)

        XCTAssertEqual(viewItem.status, TransactionStatus.processing(progress: 1.0 / Double(threshold)))
    }

    func testStatus_processing_lastConfirmationBlock() {
        let threshold = 6
        let blockHeight = 1234
        let item = transactionItem(blockHeight: blockHeight)

        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: blockHeight + 4, threshold: threshold)

        XCTAssertEqual(viewItem.status, TransactionStatus.processing(progress: 5.0 / Double(threshold)))
    }

    func testFrom_incoming() {
        let item = transactionItem(amount: 1, from: [otherAddress1, otherAddress2])

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertEqual(viewItem.from, otherAddress1.address)
    }

    func testFrom_outgoing() {
        let item = transactionItem(amount: -1, from: [otherAddress1, mineAddress1, mineAddress2])

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertEqual(viewItem.from, mineAddress1.address)
    }

    func testTo_incoming() {
        let item = transactionItem(amount: 1, to: [otherAddress1, mineAddress1, otherAddress2])

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertEqual(viewItem.to, mineAddress1.address)
    }

    func testTo_incoming_noMine() {
        let item = transactionItem(amount: 1, to: [otherAddress1, otherAddress2])

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertNil(viewItem.to)
    }

    func testTo_outgoing() {
        let item = transactionItem(amount: -1, to: [mineAddress1, otherAddress1, otherAddress2])

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertEqual(viewItem.to, otherAddress1.address)
    }

    func testTo_outgoing_noOther() {
        let item = transactionItem(amount: -1, to: [mineAddress1, mineAddress2])

        let viewItem = factory.viewItem(fromItem: item)

        XCTAssertNil(viewItem.to)
    }

    private func transactionItem(
            coin: Coin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin),
            transactionHash: String = "",
            blockHeight: Int? = nil,
            amount: Decimal = 0,
            date: Date = Date(),
            from: [TransactionAddress] = [],
            to: [TransactionAddress] = []
    ) -> TransactionItem {
        return TransactionItem(
                coin: coin,
                record: TransactionRecord(
                        transactionHash: transactionHash,
                        blockHeight: blockHeight,
                        amount: amount,
                        date: date,
                        from: from,
                        to: to
                )
        )
    }

}
