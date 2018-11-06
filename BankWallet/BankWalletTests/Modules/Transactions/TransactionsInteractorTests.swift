import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class TransactionsInteractorTests: XCTestCase {
    private var mockDataSource: MockITransactionRecordDataSource!
    private var mockDelegate: MockITransactionsInteractorDelegate!
    private var mockWalletManager: MockIWalletManager!
    private var mockRateManager: MockIRateManager!
    private var mockCurrencyManager: MockICurrencyManager!

    private var interactor: TransactionsInteractor!

    private let bitcoin = "BTC"
    private let ether = "ETH"
    private let cash = "BCH"

    private let currency = Currency(code: "USD", symbol: "")

    private let bitcoinLastBlockHeightSubject = PublishSubject<Int>()

    override func setUp() {
        super.setUp()


        mockDataSource = MockITransactionRecordDataSource()
        mockDelegate = MockITransactionsInteractorDelegate()
        mockWalletManager = MockIWalletManager()
        mockRateManager = MockIRateManager()
        mockCurrencyManager = MockICurrencyManager()

        stub(mockDelegate) { mock in
            when(mock.didUpdateDataSource()).thenDoNothing()
            when(mock.didRetrieve(filters: any())).thenDoNothing()
            when(mock.didRefresh()).thenDoNothing()
        }
        stub(mockRateManager) { mock in
        }
        let mockBitcoinAdapter = MockIAdapter()
        stub(mockBitcoinAdapter) { mock in
            when(mock.lastBlockHeightSubject.get).thenReturn(bitcoinLastBlockHeightSubject)
        }
        stub(mockWalletManager) { mock in
            when(mock.wallets.get).thenReturn([Wallet(coin: bitcoin, adapter: mockBitcoinAdapter)])
        }
        stub(mockDataSource) { mock in
            when(mock.set(coin: equal(to: bitcoin))).thenDoNothing()
            when(mock.count.get).thenReturn(0)
        }
        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrency.get).thenReturn(currency)
        }

        interactor = TransactionsInteractor(walletManager: mockWalletManager, exchangeRateManager: mockRateManager, currencyManager: mockCurrencyManager, dataSource: mockDataSource, refreshTimeout: 0)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDataSource = nil
        mockDelegate = nil
        mockWalletManager = nil
        mockRateManager = nil

        interactor = nil

        super.tearDown()
    }

    func testLastBlockHeightUpdate() {
        bitcoinLastBlockHeightSubject.onNext(2)
        verify(mockDelegate).didUpdateDataSource()
    }

    func testOnUpdateResults() {
        interactor.onUpdateResults()
        verify(mockDelegate).didUpdateDataSource()
    }

    func testSetCoin() {
        interactor.set(coin: bitcoin)
        verify(mockDataSource).set(coin: equal(to: bitcoin))
    }

    func testBaseCurrency() {
        XCTAssertEqual(interactor.baseCurrency, currency)
    }

    func testCount() {
        XCTAssertEqual(interactor.recordsCount, 0)
    }

    func testNonZeroCount() {
        stub(mockDataSource) { mock in
            when(mock.count.get).thenReturn(10)
        }
        XCTAssertEqual(interactor.recordsCount, 10)
    }

    func testGetRecordByIndex() {
        let expectedRecord = TransactionRecord()
        stub(mockDataSource) { mock in
            when(mock.record(forIndex: equal(to: 0))).thenReturn(expectedRecord)
        }

        XCTAssertTrue(expectedRecord === interactor.record(forIndex: 0))
    }

    func testFiltersGet() {
        let mockBitcoinAdapter = MockIAdapter()
        let mockEtherAdapter = MockIAdapter()
        let mockCashAdapter = MockIAdapter()
        let bitcoinWallet = Wallet(coin: bitcoin, adapter: mockBitcoinAdapter)
        let etherWallet = Wallet(coin: ether, adapter: mockEtherAdapter)
        let cashWallet = Wallet(coin: cash, adapter: mockCashAdapter)
        stub(mockWalletManager) { mock in
            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet, cashWallet])
        }

        interactor.retrieveFilters()
        verify(mockDelegate).didRetrieve(filters: equal(to: [bitcoin, ether, cash]))
    }

    func testRefresh() {
        interactor.refresh()
        waitForMainQueue()
        verify(mockDelegate).didRefresh()
    }

}
