import XCTest
import Cuckoo
import RealmSwift
@testable import Bank_Dev_T

class TransactionViewItemFactoryTests: XCTestCase {
    private var mockWalletManager: MockIWalletManager!
    private var mockCurrencyManager: MockICurrencyManager!
    private var mockRateManager: MockIRateManager!
    private var mockAdapter: MockIAdapter!
    private var mockRate: MockRate!

    private var factory: TransactionViewItemFactory!

    private let amount = 12.34
    private let coin = "BTC"
    private let currency = Currency(code: "USD", symbol: "$")
    private let rateValue = 1234.56
    private let lastBlockHeight = 1000
    private let confirmationsThreshold = 6

    private let mineAddress1 = TransactionAddress(address: "mine1", mine: true)
    private let mineAddress2 = TransactionAddress(address: "mine2", mine: true)
    private let mineAddress3 = TransactionAddress(address: "mine3", mine: true)
    private let otherAddress1 = TransactionAddress(address: "other1", mine: false)
    private let otherAddress2 = TransactionAddress(address: "other2", mine: false)
    private let otherAddress3 = TransactionAddress(address: "other3", mine: false)

    override func setUp() {
        super.setUp()

        mockWalletManager = MockIWalletManager()
        mockCurrencyManager = MockICurrencyManager()
        mockRateManager = MockIRateManager()
        mockAdapter = MockIAdapter()
        mockRate = MockRate()

        stub(mockWalletManager) { mock in
            when(mock.wallets.get).thenReturn([Wallet(title: "some", coinCode: coin, adapter: mockAdapter)])
        }
        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrency.get).thenReturn(currency)
        }
        stub(mockRate) { mock in
            when(mock.value.get).thenReturn(rateValue)
            when(mock.expired.get).thenReturn(false)
        }
        stub(mockRateManager) { mock in
            when(mock.rate(forCoin: coin, currencyCode: currency.code)).thenReturn(mockRate)
        }
        stub(mockAdapter) { mock in
            when(mock.lastBlockHeight.get).thenReturn(lastBlockHeight)
            when(mock.confirmationsThreshold.get).thenReturn(confirmationsThreshold)
        }

        factory = TransactionViewItemFactory(walletManager: mockWalletManager, currencyManager: mockCurrencyManager, rateManager: mockRateManager)
    }

    override func tearDown() {
        mockWalletManager = nil
        mockCurrencyManager = nil
        mockRateManager = nil
        mockAdapter = nil
        mockRate = nil

        factory = nil

        super.tearDown()
    }

    func testTransactionHash() {
        let hash = "hash"

        let record = TransactionRecord()
        record.transactionHash = hash

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.transactionHash, hash)
    }

    func testCoinValue() {
        let record = TransactionRecord()
        record.coinCode = coin
        record.amount = amount

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.coinValue, CoinValue(coinCode: coin, value: amount))
    }

    func testCurrencyValue_NoRate_OldTransaction() {
        let record = TransactionRecord()
        record.timestamp = Date().timeIntervalSince1970 - 60 * 65 // more than 1 hour earlier

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.currencyValue, nil)
    }

    func testCurrencyValue_NoRate_RecentTransaction() {
        let record = TransactionRecord()
        record.coinCode = coin
        record.amount = amount
        record.timestamp = Date().timeIntervalSince1970 - 60 * 55 // less than 1 hour earlier

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.currencyValue, CurrencyValue(currency: currency, value: amount * rateValue))
    }

    func testCurrencyValue_NoRate_RecentTransaction_ExpiredRate() {
        stub(mockRate) { mock in
            when(mock.expired.get).thenReturn(true)
        }

        let record = TransactionRecord()
        record.coinCode = coin
        record.timestamp = Date().timeIntervalSince1970 - 60 * 55 // less than 1 hour earlier

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.currencyValue, nil)
    }

    func testCurrencyValue_WithRate() {
        let rate: Double = 6500

        let record = TransactionRecord()
        record.amount = amount
        record.rate = rate

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.currencyValue, CurrencyValue(currency: currency, value: amount * rate))
    }

    func testIncoming_True() {
        let record = TransactionRecord()
        record.amount = amount

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.incoming, true)
    }

    func testIncoming_False() {
        let negativeAmount = -12.34

        let record = TransactionRecord()
        record.amount = negativeAmount

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.incoming, false)
    }

    func testDate_NoTimestamp() {
        let record = TransactionRecord()
        record.timestamp = 0

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.date, nil)
    }

    func testDate_WithTimestamp() {
        let date = Date(timeIntervalSince1970: Double(Int(Date().timeIntervalSince1970)))

        let record = TransactionRecord()
        record.coinCode = coin
        record.timestamp = date.timeIntervalSince1970

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.date, date)
    }

    func testStatus_NoBlockHeight() {
        let record = TransactionRecord()
        record.coinCode = coin

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.status, TransactionStatus.pending)
    }

    func testStatus_NoAdapter() {
        stub(mockWalletManager) { mock in
            when(mock.wallets.get).thenReturn([])
        }

        let record = TransactionRecord()
        record.coinCode = coin
        record.blockHeight = 100

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.status, TransactionStatus.pending)
    }

    func testStatus_NoLastBlockHeight() {
        stub(mockAdapter) { mock in
            when(mock.lastBlockHeight.get).thenReturn(nil)
        }

        let record = TransactionRecord()
        record.coinCode = coin
        record.blockHeight = 100

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.status, TransactionStatus.pending)
    }

    func testStatus_Processing() {
        let blockHeight = 100
        let lastBlockHeight = 102

        stub(mockAdapter) { mock in
            when(mock.lastBlockHeight.get).thenReturn(lastBlockHeight)
        }

        let record = TransactionRecord()
        record.coinCode = coin
        record.blockHeight = blockHeight

        let item = factory.item(fromRecord: record)

        let expectedProgress = 0.5
        XCTAssertEqual(item.status, TransactionStatus.processing(progress: expectedProgress))
    }

    func testStatus_Completed() {
        let blockHeight = 100
        let lastBlockHeight = 106

        stub(mockAdapter) { mock in
            when(mock.lastBlockHeight.get).thenReturn(lastBlockHeight)
        }

        let record = TransactionRecord()
        record.coinCode = coin
        record.blockHeight = blockHeight

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.status, TransactionStatus.completed)
    }

    func testFrom_Incoming() {
        let record = TransactionRecord()
        record.amount = 1
        record.from.append(otherAddress1)
        record.from.append(otherAddress2)

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.from, otherAddress1.address)
    }

    func testFrom_Outgoing() {
        let record = TransactionRecord()
        record.amount = -1
        record.from.append(otherAddress1)
        record.from.append(mineAddress1)
        record.from.append(mineAddress2)

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.from, mineAddress1.address)
    }

    func testTo_Incoming() {
        let record = TransactionRecord()
        record.amount = 1
        record.to.append(otherAddress1)
        record.to.append(mineAddress1)
        record.to.append(otherAddress2)

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.to, mineAddress1.address)
    }

    func testTo_Incoming_NoMine() {
        let record = TransactionRecord()
        record.amount = 1
        record.to.append(otherAddress1)
        record.to.append(otherAddress2)

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.to, nil)
    }

    func testTo_Outgoing() {
        let record = TransactionRecord()
        record.amount = -1
        record.to.append(mineAddress1)
        record.to.append(otherAddress1)
        record.to.append(otherAddress2)

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.to, otherAddress1.address)
    }

    func testTo_Outgoing_NoOther() {
        let record = TransactionRecord()
        record.amount = -1
        record.to.append(mineAddress1)
        record.to.append(mineAddress2)

        let item = factory.item(fromRecord: record)

        XCTAssertEqual(item.to, nil)
    }

}
