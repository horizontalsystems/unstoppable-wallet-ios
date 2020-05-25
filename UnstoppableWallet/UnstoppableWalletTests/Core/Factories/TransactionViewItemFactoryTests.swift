//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class TransactionViewItemFactoryTests: XCTestCase {
//    private var mockFeeCoinProvider: MockIFeeCoinProvider!
//
//    private var factory: TransactionViewItemFactory!
//
//    private let mineAddress1 = TransactionAddress(address: "mine1", mine: true)
//    private let mineAddress2 = TransactionAddress(address: "mine2", mine: true)
//    private let mineAddress3 = TransactionAddress(address: "mine3", mine: true)
//    private let otherAddress1 = TransactionAddress(address: "other1", mine: false)
//    private let otherAddress2 = TransactionAddress(address: "other2", mine: false)
//    private let otherAddress3 = TransactionAddress(address: "other3", mine: false)
//
//    override func setUp() {
//        super.setUp()
//
//        mockFeeCoinProvider = MockIFeeCoinProvider()
//        factory = TransactionViewItemFactory(feeCoinProvider: mockFeeCoinProvider)
//    }
//
//    override func tearDown() {
//        mockFeeCoinProvider = nil
//        factory = nil
//
//        super.tearDown()
//    }
//
//    func testWallet() {
//        let wallet = Wallet.mock()
//        let item = transactionItem(wallet: wallet)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.wallet, wallet)
//    }
//
//    func testTransactionHash() {
//        let transactionHash = "hash"
//        let item = transactionItem(transactionHash: transactionHash)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.transactionHash, transactionHash)
//    }
//
//    func testCoinValue() {
//        let coin = Coin.mock()
//        let wallet = Wallet.mock(coin: coin)
//        let amount: Decimal = 123.45
//        let item = transactionItem(wallet: wallet, amount: amount)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.coinValue, CoinValue(coin: coin, value: amount))
//    }
//
//    func testFeeCoinValue_nil() {
//        let item = transactionItem(fee: nil)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertNil(viewItem.feeCoinValue)
//    }
//
//    func testFeeCoinValue_noFeeCoin() {
//        let coin = Coin.mock()
//        let wallet = Wallet.mock(coin: coin)
//
//        stub(mockFeeCoinProvider) { mock in
//            when(mock.feeCoin(coin: equal(to: coin))).thenReturn(nil)
//        }
//
//        let fee: Decimal = 0.123
//        let item = transactionItem(wallet: wallet, fee: fee)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.feeCoinValue, CoinValue(coin: coin, value: fee))
//    }
//
//    func testFeeCoinValue_withFeeCoin() {
//        let coin = Coin.mock()
//        let wallet = Wallet.mock(coin: coin)
//
//        let feeCoin = Coin.mock(title: "FeeCoin", code: "FEE", type: .ethereum)
//
//        stub(mockFeeCoinProvider) { mock in
//            when(mock.feeCoin(coin: equal(to: coin))).thenReturn(feeCoin)
//        }
//
//        let fee: Decimal = 0.123
//        let item = transactionItem(wallet: wallet, fee: fee)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.feeCoinValue, CoinValue(coin: feeCoin, value: fee))
//    }
//
//    func testCurrencyValue() {
//        let currency = Currency.mock()
//        let amount: Decimal = 123.45
//        let rateValue: Decimal = 9876.54
//        let rate = CurrencyValue(currency: currency, value: rateValue)
//
//        let item = transactionItem(amount: amount)
//
//        let viewItem = factory.viewItem(fromItem: item, rate: rate)
//
//        XCTAssertEqual(viewItem.currencyValue, CurrencyValue(currency: currency, value: rateValue * amount))
//    }
//
//    func testCurrencyValue_withoutRate() {
//        let item = transactionItem()
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertNil(viewItem.currencyValue)
//    }
//
//    func testIncoming_positiveAmount() {
//        let amount: Decimal = 123.45
//        let item = transactionItem(amount: amount)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertTrue(viewItem.incoming)
//    }
//
//    func testIncoming_negativeAmount() {
//        let amount: Decimal = -123.45
//        let item = transactionItem(amount: amount)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertFalse(viewItem.incoming)
//    }
//
//    func testDate() {
//        let date = Date()
//        let item = transactionItem(date: date)
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.date, date)
//    }
//
//    func testStatus_noBlockHeight() {
//        let item = transactionItem(blockHeight: nil)
//
//        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: 1234)
//
//        XCTAssertEqual(viewItem.status, TransactionStatus.pending)
//    }
//
//    func testStatus_noLastBlockHeight() {
//        let item = transactionItem(blockHeight: 1234)
//
//        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: nil)
//
//        XCTAssertEqual(viewItem.status, TransactionStatus.pending)
//    }
//
//    func testStatus_completed() {
//        let threshold = 6
//        let blockHeight = 1234
//        let item = transactionItem(blockHeight: blockHeight)
//
//        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: blockHeight + threshold, threshold: threshold)
//
//        XCTAssertEqual(viewItem.status, TransactionStatus.completed)
//    }
//
//    func testStatus_processing_sameBlock() {
//        let threshold = 6
//        let blockHeight = 1234
//        let item = transactionItem(blockHeight: blockHeight)
//
//        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: blockHeight, threshold: threshold)
//
//        XCTAssertEqual(viewItem.status, TransactionStatus.processing(progress: 1.0 / Double(threshold)))
//    }
//
//    func testStatus_processing_lastConfirmationBlock() {
//        let threshold = 6
//        let blockHeight = 1234
//        let item = transactionItem(blockHeight: blockHeight)
//
//        let viewItem = factory.viewItem(fromItem: item, lastBlockHeight: blockHeight + 4, threshold: threshold)
//
//        XCTAssertEqual(viewItem.status, TransactionStatus.processing(progress: 5.0 / Double(threshold)))
//    }
//
//    func testRate() {
//        let expectedRate = CurrencyValue(currency: Currency.mock(), value: 35)
//
//        let item = transactionItem()
//        let viewItem = factory.viewItem(fromItem: item, rate: expectedRate)
//
//        XCTAssertEqual(viewItem.rate, expectedRate)
//    }
//
//    func testFrom_incoming() {
//        let item = transactionItem(amount: 1, from: [otherAddress1, otherAddress2])
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.from, otherAddress1.address)
//    }
//
//    func testFrom_outgoing() {
//        let item = transactionItem(amount: -1, from: [mineAddress1, mineAddress2], to: [otherAddress1])
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertNil(viewItem.from)
//    }
//
//    func testTo_incoming() {
//        let item = transactionItem(amount: 1, from: [otherAddress1], to: [mineAddress1, otherAddress2])
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertNil(viewItem.to)
//    }
//
//    func testTo_outgoing() {
//        let item = transactionItem(amount: -1, from: [mineAddress1], to: [otherAddress1, otherAddress2])
//
//        let viewItem = factory.viewItem(fromItem: item)
//
//        XCTAssertEqual(viewItem.to, otherAddress1.address)
//    }
//
//    private func transactionItem(
//            wallet: Wallet = .mock(),
//            transactionHash: String = "",
//            blockHeight: Int? = nil,
//            amount: Decimal = 0,
//            fee: Decimal? = nil,
//            date: Date = Date(),
//            from: [TransactionAddress] = [],
//            to: [TransactionAddress] = []
//    ) -> TransactionItem {
//        return TransactionItem(
//                wallet: wallet,
//                record: TransactionRecord(
//                        transactionHash: transactionHash,
//                        transactionIndex: 0,
//                        interTransactionIndex: 0,
//                        blockHeight: blockHeight,
//                        amount: amount,
//                        fee: fee,
//                        date: date,
//                        from: from,
//                        to: to
//                )
//        )
//    }
//
//}
