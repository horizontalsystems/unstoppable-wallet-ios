import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class TransactionsPresenterTests: XCTestCase {
    private var mockRouter: MockITransactionsRouter!
    private var mockInteractor: MockITransactionsInteractor!
    private var mockView: MockITransactionsView!

    private var presenter: TransactionsPresenter!

    private let threshold = 6

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private let bitcoinLastBlockHeight = 10
    private let etherLastBlockHeight = 12

    private var bitcoinValue: CoinValue!
    private var etherValue: CoinValue!

    private var bitcoinAmount: Double = 2
    private var etherAmount: Double = -3

    private var bitcoinRate: Double = 6000
    private var etherRate: Double = 200
    private var cashRate: Double = 450

    private var bitcoinRecord: TransactionRecord!
    private var etherRecord: TransactionRecord!

    private let bitcoinStatus = TransactionStatus.completed
    private let etherStatus = TransactionStatus.completed

    private var expectedBitcoinTransactionItem: TransactionRecordViewItem!
    private var expectedEtherTransactionItem: TransactionRecordViewItem!

    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEtherAdapter: MockIAdapter!

    private let currency = Currency(code: "USD", localeId: "")

    override func setUp() {
        super.setUp()

        bitcoinValue = CoinValue(coin: bitcoin, value: bitcoinAmount)
        etherValue = CoinValue(coin: ether, value: etherAmount)

        let bitcoinTransactionTimeStamp = 15_000_000
        let etherTransactionTimeStamp = 35_000_000

        bitcoinRecord = TransactionRecord()
        bitcoinRecord.transactionHash = "bitcoin_transaction_hash"
        bitcoinRecord.blockHeight = 1
        bitcoinRecord.coin = bitcoin
        bitcoinRecord.amount = bitcoinAmount
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
        etherRecord.blockHeight = 1
        etherRecord.coin = ether
        etherRecord.amount = etherAmount
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

        expectedBitcoinTransactionItem = TransactionRecordViewItem(
                transactionHash: bitcoinRecord.transactionHash,
                coinValue: CoinValue(coin: bitcoinRecord.coin, value: bitcoinAmount),
                currencyAmount: CurrencyValue(currency: currency, value: bitcoinAmount * bitcoinRate),
                from: from.address,
                to: nil,
                incoming: true,
                date: Date(timeIntervalSince1970: Double(bitcoinTransactionTimeStamp)),
                status: bitcoinStatus
        )
        expectedEtherTransactionItem = TransactionRecordViewItem(
                transactionHash: etherRecord.transactionHash,
                coinValue: CoinValue(coin: etherRecord.coin, value: etherAmount),
                currencyAmount: CurrencyValue(currency: currency, value: etherAmount * etherRate),
                from: nil,
                to: to1.address,
                incoming: false,
                date: Date(timeIntervalSince1970: Double(etherTransactionTimeStamp)),
                status: etherStatus
        )

        mockBitcoinAdapter = MockIAdapter()
        mockEtherAdapter = MockIAdapter()
        stub(mockBitcoinAdapter) { mock in
            when(mock.balance.get).thenReturn(bitcoinValue.value)
            when(mock.lastBlockHeight.get).thenReturn(bitcoinLastBlockHeight)
            when(mock.confirmationsThreshold.get).thenReturn(6)
        }
        stub(mockEtherAdapter) { mock in
            when(mock.balance.get).thenReturn(etherValue.value)
            when(mock.lastBlockHeight.get).thenReturn(etherLastBlockHeight)
            when(mock.confirmationsThreshold.get).thenReturn(6)
        }

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
            when(mock.baseCurrency.get).thenReturn(currency)
            when(mock.recordsCount.get).thenReturn(3)
            when(mock.record(forIndex: 0)).thenReturn(bitcoinRecord)
            when(mock.record(forIndex: 1)).thenReturn(etherRecord)

            when(mock.adapter(forCoin: bitcoin)).thenReturn(mockBitcoinAdapter)
            when(mock.adapter(forCoin: ether)).thenReturn(mockEtherAdapter)
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
        let expectedBitcoinFilter = TransactionFilterItem(coin: bitcoin, name: "coin.\(bitcoin)")
        let expectedEtherFilter = TransactionFilterItem(coin: ether, name: "coin.\(ether)")
        let expectedFilters = [expectedAllFilter, expectedBitcoinFilter, expectedEtherFilter]

        presenter.didRetrieve(filters: [bitcoin, ether])
        verify(mockView).show(filters: equal(to: expectedFilters))
    }

    func testDidUpdateDataSource() {
        presenter.didUpdateDataSource()
        verify(mockView).reload()
    }

    func compare(transactionItem1: TransactionRecordViewItem, transactionItem2: TransactionRecordViewItem) {
        XCTAssertEqual(transactionItem1.transactionHash, transactionItem2.transactionHash)
        XCTAssertEqual(transactionItem1.coinValue, transactionItem2.coinValue)
        XCTAssertEqual(transactionItem1.currencyAmount, transactionItem2.currencyAmount)
        XCTAssertEqual(transactionItem1.from, transactionItem2.from)
        XCTAssertEqual(transactionItem1.to, transactionItem2.to)
        XCTAssertEqual(transactionItem1.incoming, transactionItem2.incoming)
        XCTAssertEqual(transactionItem1.date?.timeIntervalSince1970, transactionItem2.date?.timeIntervalSince1970)
        if case .processing = transactionItem1.status, case .processing = transactionItem2.status {
            XCTAssertTrue(true)
        } else if case let .verifying(progress1) = transactionItem1.status, case let .verifying(progress2) = transactionItem2.status {
            XCTAssertTrue(progress1 == progress2)
        } else if case .completed = transactionItem1.status, case .completed = transactionItem2.status {
            XCTAssertTrue(true)
        } else {
            XCTFail()
        }
    }

}
