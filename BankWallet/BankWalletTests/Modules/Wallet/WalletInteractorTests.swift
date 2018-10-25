import XCTest
import RxSwift
import Cuckoo
@testable import BankWallet

class WalletInteractorTests: XCTestCase {
    private var mockDelegate: MockIWalletInteractorDelegate!
    private var mockWalletManager: MockIWalletManager!
    private var mockExchangeRateManager: MockIExchangeRateManager!

    private var interactor: WalletInteractor!

    private let bitcoin = "BTC"
    private let ether = "ETH"
    private let cash = "BCH"

    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEtherAdapter: MockIAdapter!
    private var mockCashAdapter: MockIAdapter!

    private var bitcoinWallet: Wallet!
    private var etherWallet: Wallet!
    private var cashWallet: Wallet!

    private let bitcoinBalanceSubject = PublishSubject<Double>()
    private let etherBalanceSubject = PublishSubject<Double>()
    private let cashBalanceSubject = PublishSubject<Double>()

    private let mockRatesSubject = PublishSubject<[Coin: CurrencyValue]>()

    override func setUp() {
        super.setUp()

        mockBitcoinAdapter = MockIAdapter()
        mockEtherAdapter = MockIAdapter()
        mockCashAdapter = MockIAdapter()

        bitcoinWallet = Wallet(coin: bitcoin, adapter: mockBitcoinAdapter)
        etherWallet = Wallet(coin: ether, adapter: mockEtherAdapter)
        cashWallet = Wallet(coin: cash, adapter: mockCashAdapter)

        mockDelegate = MockIWalletInteractorDelegate()
        mockWalletManager = MockIWalletManager()
        mockExchangeRateManager = MockIExchangeRateManager()

        stub(mockDelegate) { mock in
            when(mock.didUpdate(coinValue: any())).thenDoNothing()
            when(mock.didUpdate(rates: any())).thenDoNothing()
            when(mock.didRefresh()).thenDoNothing()
        }
        stub(mockWalletManager) { mock in
            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet, cashWallet])
            when(mock.refreshWallets()).thenDoNothing()
        }
        stub(mockExchangeRateManager) { mock in
            when(mock.subject.get).thenReturn(mockRatesSubject)
        }
        stub(mockBitcoinAdapter) { mock in
            when(mock.balanceSubject.get).thenReturn(bitcoinBalanceSubject)
        }
        stub(mockEtherAdapter) { mock in
            when(mock.balanceSubject.get).thenReturn(etherBalanceSubject)
        }
        stub(mockCashAdapter) { mock in
            when(mock.balanceSubject.get).thenReturn(cashBalanceSubject)
        }

        interactor = WalletInteractor(walletManager: mockWalletManager, exchangeRateManager: mockExchangeRateManager, refreshTimeout: 0)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockWalletManager = nil
        mockExchangeRateManager = nil

        mockBitcoinAdapter = nil
        mockEtherAdapter = nil
        mockCashAdapter = nil

        bitcoinWallet = nil
        etherWallet = nil
        cashWallet = nil

        interactor = nil

        super.tearDown()
    }

    func testCoinValues() {
        let bitcoinBalance: Double = 1
        let etherBalance: Double = 2
        let cashBalance: Double = 3

        let expectedCoinValues = [
            CoinValue(coin: bitcoin, value: bitcoinBalance),
            CoinValue(coin: ether, value: etherBalance),
            CoinValue(coin: cash, value: cashBalance)
        ]

        stub(mockBitcoinAdapter) { mock in
            when(mock.balance.get).thenReturn(bitcoinBalance)
        }
        stub(mockEtherAdapter) { mock in
            when(mock.balance.get).thenReturn(etherBalance)
        }
        stub(mockCashAdapter) { mock in
            when(mock.balance.get).thenReturn(cashBalance)
        }

        XCTAssertEqual(interactor.coinValues, expectedCoinValues)
    }

    func testRates() {
        let expectedRates = [
            bitcoin: CurrencyValue(currency: DollarCurrency(), value: 5000),
            ether: CurrencyValue(currency: DollarCurrency(), value: 300)
        ]

        stub(mockExchangeRateManager) { mock in
            when(mock.exchangeRates.get).thenReturn(expectedRates)
        }

        XCTAssertEqual(interactor.rates, expectedRates)
    }

    func testProgressSubjects() {
        let bitcoinSubject = BehaviorSubject<Double>(value: 1)
        let etherSubject = BehaviorSubject<Double>(value: 0.5)
        let cashSubject = BehaviorSubject<Double>(value: 0.3)

        let expectedSubjects = [
            bitcoin: bitcoinSubject,
            ether: etherSubject,
            cash: cashSubject
        ]

        stub(mockBitcoinAdapter) { mock in
            when(mock.progressSubject.get).thenReturn(bitcoinSubject)
        }
        stub(mockEtherAdapter) { mock in
            when(mock.progressSubject.get).thenReturn(etherSubject)
        }
        stub(mockCashAdapter) { mock in
            when(mock.progressSubject.get).thenReturn(cashSubject)
        }

        let subjects = interactor.progressSubjects

        XCTAssert(subjects[bitcoin] === expectedSubjects[bitcoin])
        XCTAssert(subjects[ether] === expectedSubjects[ether])
        XCTAssert(subjects[cash] === expectedSubjects[cash])
    }

    func testRefresh() {
        interactor.refresh()
        verify(mockWalletManager).refreshWallets()
    }

    func testWalletBalanceUpdate() {
        let newBitcoinValue: Double = 11

        bitcoinBalanceSubject.onNext(newBitcoinValue)

        verify(mockDelegate).didUpdate(coinValue: equal(to: CoinValue(coin: bitcoin, value: newBitcoinValue)))
    }

    func testRatesUpdate() {
        let bitcoinRate = CurrencyValue(currency: DollarCurrency(), value: 6000)
        let etherRate = CurrencyValue(currency: DollarCurrency(), value: 400)
        let rates = [bitcoin: bitcoinRate, ether: etherRate]
        mockRatesSubject.onNext(rates)

        verify(mockDelegate).didUpdate(rates: equal(to: rates))
    }

    func testDidRefresh() {
        interactor.refresh()

        waitForMainQueue()

        verify(mockDelegate).didRefresh()
    }

}
