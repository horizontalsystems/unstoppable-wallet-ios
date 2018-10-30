import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class TransactionsPresenterTests: XCTestCase {
    private var mockRouter: MockITransactionsRouter!
    private var mockInteractor: MockITransactionsInteractor!
    private var mockView: MockITransactionsView!

    private var presenter: TransactionsPresenter!

    private let bitcoin = "BTC"
    private let ether = "ETH"
    private let cash = "BCH"

    private var bitcoinValue: CoinValue!
    private var etherValue: CoinValue!
    private var cashValue: CoinValue!

    private var bitcoinAmount: Double = 2
    private var etherAmount: Double = -3
    private var cashAmount: Double = 10

    private var bitcoinRate: Double = 6000
    private var etherRate: Double = 200
    private var cashRate: Double = 450

    private var bitcoinRecord: TransactionRecord!
    private var etherRecord: TransactionRecord!
    private var cashRecord: TransactionRecord!

    private var expectedBitcoinTransactionItem: TransactionRecordViewItem!
    private var expectedEtherTransactionItem: TransactionRecordViewItem!
    private var expectedCashTransactionItem: TransactionRecordViewItem!

    override func setUp() {
        super.setUp()

        bitcoinValue = CoinValue(coin: bitcoin, value: bitcoinAmount)
        etherValue = CoinValue(coin: ether, value: etherAmount)
        cashValue = CoinValue(coin: cash, value: cashAmount)

        let bitcoinTransactionTimeStamp = 15_000_000
        let etherTransactionTimeStamp = 35_000_000
        let cashTransactionTimeStamp = 55_000_000

        bitcoinRecord = TransactionRecord()
        bitcoinRecord.transactionHash = "bitcoin_transaction_hash"
        bitcoinRecord.coin = bitcoin
        bitcoinRecord.amount = bitcoinAmount
        bitcoinRecord.status = .processing
        bitcoinRecord.verifyProgress = 0.2
        bitcoinRecord.timestamp = bitcoinTransactionTimeStamp
        bitcoinRecord.rate = bitcoinRate
        let from = TransactionAddress()
        from.address = "bitcoin_from_address"
        from.mine = false
        let to = TransactionAddress()
        to.address = "bitcoin_to_address"
        to.mine = true
        bitcoinRecord.from.append(from)
        bitcoinRecord.to.append(to)

        etherRecord = TransactionRecord()
        etherRecord.transactionHash = "ether_transaction_hash"
        etherRecord.coin = ether
        etherRecord.amount = etherAmount
        etherRecord.status = .verifying
        etherRecord.verifyProgress = 0.2
        etherRecord.timestamp = etherTransactionTimeStamp
        etherRecord.rate = etherRate
        let from1 = TransactionAddress()
        from1.address = "ether_from_address"
        from1.mine = true
        let to1 = TransactionAddress()
        to1.address = "ether_to_address"
        to1.mine = false
        etherRecord.from.append(from1)
        etherRecord.to.append(to1)

        cashRecord = TransactionRecord()
        cashRecord.transactionHash = "cash_transaction_hash"
        cashRecord.coin = cash
        cashRecord.amount = cashAmount
        cashRecord.status = .completed
        cashRecord.verifyProgress = 0.2
        cashRecord.timestamp = cashTransactionTimeStamp
        cashRecord.rate = cashRate
        let from2 = TransactionAddress()
        from2.address = "cash_from_address"
        from2.mine = false
        let to2 = TransactionAddress()
        to2.address = "cash_to_address"
        to2.mine = true
        cashRecord.from.append(from2)
        cashRecord.to.append(to2)

        expectedBitcoinTransactionItem = TransactionRecordViewItem(
                transactionHash: bitcoinRecord.transactionHash,
                amount: CoinValue(coin: bitcoinRecord.coin, value: bitcoinAmount),
                currencyAmount: CurrencyValue(currency: DollarCurrency(), value: bitcoinAmount * bitcoinRate),
                from: from.address,
                to: nil,
                incoming: true,
                date: Date(timeIntervalSince1970: Double(bitcoinTransactionTimeStamp)),
                status: bitcoinRecord.status,
                verifyProgress: bitcoinRecord.verifyProgress
        )
        expectedEtherTransactionItem = TransactionRecordViewItem(
                transactionHash: etherRecord.transactionHash,
                amount: CoinValue(coin: etherRecord.coin, value: etherAmount),
                currencyAmount: CurrencyValue(currency: DollarCurrency(), value: etherAmount * etherRate),
                from: nil,
                to: to1.address,
                incoming: false,
                date: Date(timeIntervalSince1970: Double(etherTransactionTimeStamp)),
                status: etherRecord.status,
                verifyProgress: etherRecord.verifyProgress
        )
        expectedCashTransactionItem = TransactionRecordViewItem(
                transactionHash: cashRecord.transactionHash,
                amount: CoinValue(coin: cashRecord.coin, value: cashRecord.amount),
                currencyAmount: CurrencyValue(currency: DollarCurrency(), value: cashAmount * cashRate),
                from: from2.address,
                to: nil,
                incoming: true,
                date: Date(timeIntervalSince1970: Double(cashTransactionTimeStamp)),
                status: cashRecord.status,
                verifyProgress: cashRecord.verifyProgress
        )

        mockRouter = MockITransactionsRouter()
        mockInteractor = MockITransactionsInteractor()
        mockView = MockITransactionsView()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.reload()).thenDoNothing()
            when(mock.show(filters: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.openTransactionInfo(transaction: any())).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.retrieveFilters()).thenDoNothing()
            when(mock.refresh()).thenDoNothing()
            when(mock.set(coin: equal(to: bitcoin))).thenDoNothing()
            when(mock.recordsCount.get).thenReturn(3)
            when(mock.record(forIndex: 0)).thenReturn(bitcoinRecord)
            when(mock.record(forIndex: 1)).thenReturn(etherRecord)
            when(mock.record(forIndex: 2)).thenReturn(cashRecord)
        }

        presenter = TransactionsPresenter(interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

        presenter = nil

        super.tearDown()
    }

    func testShowTitle() {
        presenter.viewDidLoad()
        verify(mockView).set(title: "transactions.title")
    }

    func testInitialFiltersRequest() {
        presenter.viewDidLoad()
        verify(mockInteractor).retrieveFilters()
    }

    func testInitialItems() {
        compare(transactionItem1: expectedBitcoinTransactionItem, transactionItem2: presenter.item(forIndex: 0))
        compare(transactionItem1: expectedEtherTransactionItem, transactionItem2: presenter.item(forIndex: 1))
        compare(transactionItem1: expectedCashTransactionItem, transactionItem2: presenter.item(forIndex: 2))
    }

    func testRefresh() {
        presenter.refresh()
        verify(mockInteractor).refresh()
    }

    func testUpdateFilterCoin() {
        presenter.onFilterSelect(coin: bitcoin)
        verify(mockInteractor).set(coin: equal(to: bitcoin))
    }

    func testItemsCount_OnFilterSelect() {
        stub(mockInteractor) { mock in
            when(mock.recordsCount.get).thenReturn(1)
        }

        presenter.onFilterSelect(coin: bitcoin)
        XCTAssertEqual(presenter.itemsCount, 1)
    }

    func testItemIsRight_OnFilterSelect() {
        stub(mockInteractor) { mock in
            when(mock.record(forIndex: 0)).thenReturn(bitcoinRecord)
        }

        presenter.onFilterSelect(coin: bitcoin)
        compare(transactionItem1: presenter.item(forIndex: 0), transactionItem2: expectedBitcoinTransactionItem)
    }

    func testOpenTransactionInfo() {
        presenter.onTransactionItemClick(transaction: expectedBitcoinTransactionItem)

        let argumentCaptor = ArgumentCaptor<TransactionRecordViewItem>()
        verify(mockRouter).openTransactionInfo(transaction: argumentCaptor.capture())

        if let capturedTransaction = argumentCaptor.value {
            compare(transactionItem1: expectedBitcoinTransactionItem, transactionItem2: capturedTransaction)
        }

    }

    func testDidRetrieveFilters() {
        let expectedAllFilter = TransactionFilterItem(coin: nil, name: "transactions.filter_all")
        let expectedBitcoinFilter = TransactionFilterItem(coin: bitcoin, name: bitcoin)
        let expectedEtherFilter = TransactionFilterItem(coin: ether, name: ether)
        let expectedCashFilter = TransactionFilterItem(coin: cash, name: cash)
        let expectedFilters = [expectedAllFilter, expectedBitcoinFilter, expectedEtherFilter, expectedCashFilter]

        presenter.didRetrieve(filters: [bitcoin, ether, cash])
        verify(mockView).show(filters: equal(to: expectedFilters))
    }

    func testDidUpdateDataSource() {
        presenter.didUpdateDataSource()
        verify(mockView).reload()
    }

    func compare(transactionItem1: TransactionRecordViewItem, transactionItem2: TransactionRecordViewItem) {
        XCTAssertEqual(transactionItem1.transactionHash, transactionItem2.transactionHash)
        XCTAssertEqual(transactionItem1.amount, transactionItem2.amount)
        XCTAssertEqual(transactionItem1.currencyAmount, transactionItem2.currencyAmount)
        XCTAssertEqual(transactionItem1.from, transactionItem2.from)
        XCTAssertEqual(transactionItem1.to, transactionItem2.to)
        XCTAssertEqual(transactionItem1.incoming, transactionItem2.incoming)
        XCTAssertEqual(transactionItem1.date?.timeIntervalSince1970, transactionItem2.date?.timeIntervalSince1970)
        XCTAssertEqual(transactionItem1.status, transactionItem2.status)
        XCTAssertEqual(transactionItem1.verifyProgress, transactionItem2.verifyProgress)
    }

}
