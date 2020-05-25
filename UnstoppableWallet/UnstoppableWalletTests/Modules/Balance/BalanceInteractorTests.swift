//import XCTest
//import RxSwift
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class BalanceInteractorTests: XCTestCase {
//    private var mockDelegate: MockIBalanceInteractorDelegate!
//    private var mockWalletManager: MockIWalletManager!
//    private var mockRateManager: MockIRateManager!
//    private var mockCurrencyManager: MockICurrencyManager!
//
//    private var interactor: BalanceInteractor!
//
//    private let bitcoin = "BTC"
//    private let ether = "ETH"
//    private let cash = "BCH"
//
//    private var mockBitcoinAdapter: MockIAdapter!
//    private var mockEtherAdapter: MockIAdapter!
//    private var mockCashAdapter: MockIAdapter!
//
//    private var bitcoinWallet: Wallet!
//    private var etherWallet: Wallet!
//    private var cashWallet: Wallet!
//
//    private let bitcoinBalanceSubject = PublishSubject<Double>()
//    private let etherBalanceSubject = PublishSubject<Double>()
//    private let cashBalanceSubject = PublishSubject<Double>()
//
//    private let bitcoinStateSubject = PublishSubject<AdapterState>()
//    private let etherStateSubject = PublishSubject<AdapterState>()
//    private let cashStateSubject = PublishSubject<AdapterState>()
//
//    private let ratesSubject = PublishSubject<Void>()
//    private let currencySubject = PublishSubject<Currency>()
//
//    private var expectedWallets: [Wallet] = []
//
//    private let currency = Currency(code: "USD", symbol: "$")
//
//    override func setUp() {
//        super.setUp()
//
//        mockBitcoinAdapter = MockIAdapter()
//        mockEtherAdapter = MockIAdapter()
//        mockCashAdapter = MockIAdapter()
//
//        bitcoinWallet = Wallet(title: "some", coinCode: bitcoin, adapter: mockBitcoinAdapter)
//        etherWallet = Wallet(title: "some", coinCode: ether, adapter: mockEtherAdapter)
//        cashWallet = Wallet(title: "some", coinCode: cash, adapter: mockCashAdapter)
//
//        mockDelegate = MockIBalanceInteractorDelegate()
//        mockWalletManager = MockIWalletManager()
//        mockRateManager = MockIRateManager()
//        mockCurrencyManager = MockICurrencyManager()
//
//        expectedWallets = [bitcoinWallet, etherWallet, cashWallet]
//
//        stub(mockDelegate) { mock in
//            when(mock.didUpdate()).thenDoNothing()
//        }
//        stub(mockWalletManager) { mock in
//            when(mock.wallets.get).thenReturn(expectedWallets)
//        }
//        stub(mockRateManager) { mock in
//            when(mock.subject.get).thenReturn(ratesSubject)
//        }
//        stub(mockCurrencyManager) { mock in
//            when(mock.subject.get).thenReturn(currencySubject)
//            when(mock.baseCurrency.get).thenReturn(currency)
//        }
//        stub(mockBitcoinAdapter) { mock in
//            when(mock.balanceSubject.get).thenReturn(bitcoinBalanceSubject)
//            when(mock.stateSubject.get).thenReturn(bitcoinStateSubject)
//        }
//        stub(mockEtherAdapter) { mock in
//            when(mock.balanceSubject.get).thenReturn(etherBalanceSubject)
//            when(mock.stateSubject.get).thenReturn(etherStateSubject)
//            when(mock.refresh()).thenDoNothing()
//        }
//        stub(mockCashAdapter) { mock in
//            when(mock.balanceSubject.get).thenReturn(cashBalanceSubject)
//            when(mock.stateSubject.get).thenReturn(cashStateSubject)
//        }
//
//        interactor = BalanceInteractor(walletManager: mockWalletManager, rateManager: mockRateManager, currencyManager: mockCurrencyManager, refreshTimeout: 0)
//        interactor.delegate = mockDelegate
//    }
//
//    override func tearDown() {
//        mockDelegate = nil
//        mockWalletManager = nil
//        mockRateManager = nil
//        mockCurrencyManager = nil
//
//        mockBitcoinAdapter = nil
//        mockEtherAdapter = nil
//        mockCashAdapter = nil
//
//        bitcoinWallet = nil
//        etherWallet = nil
//        cashWallet = nil
//
//        interactor = nil
//
//        super.tearDown()
//    }
//
//    func testBaseCurrency() {
//        XCTAssertEqual(interactor.baseCurrency, currency)
//    }
//
//    func testWallets() {
//        XCTAssertTrue(interactor.wallets[0] === expectedWallets[0])
//        XCTAssertTrue(interactor.wallets[1] === expectedWallets[1])
//        XCTAssertTrue(interactor.wallets[2] === expectedWallets[2])
//    }
//
//    func testBitcoinRate() {
//        let bitcoinRate = Rate()
//        bitcoinRate.coinCode = bitcoin
//        bitcoinRate.currencyCode = currency.code
//        bitcoinRate.value = 5000
//        bitcoinRate.timestamp = 134000000
//
//        stub(mockRateManager) { mock in
//            when(mock.rate(forCoin: bitcoin, currencyCode: currency.code)).thenReturn(bitcoinRate)
//        }
//
//        XCTAssertEqual(interactor.rate(forCoin: bitcoin), bitcoinRate)
//    }
//
//    func testEtherRate() {
//        let etherRate = Rate()
//        etherRate.coinCode = ether
//        etherRate.currencyCode = currency.code
//        etherRate.value = 300
//        etherRate.timestamp = 2000000
//
//        stub(mockRateManager) { mock in
//            when(mock.rate(forCoin: ether, currencyCode: currency.code)).thenReturn(etherRate)
//        }
//
//        XCTAssertEqual(interactor.rate(forCoin: ether), etherRate)
//    }
//
//    func testRefresh() {
//        interactor.refresh(coinCode: ether)
//        verify(mockEtherAdapter).refresh()
//    }
//
//    func testWalletBalanceUpdate() {
//        let newBitcoinValue: Double = 11
//
//        bitcoinBalanceSubject.onNext(newBitcoinValue)
//
//        verify(mockDelegate).didUpdate()
//    }
//
//    func testStateUpdate() {
//        bitcoinStateSubject.onNext(AdapterState.synced)
//        verify(mockDelegate).didUpdate()
//    }
//
//    func testRatesUpdate() {
//        ratesSubject.onNext(())
//        verify(mockDelegate).didUpdate()
//    }
//
//    func testCurrencyUpdate() {
//        let newCurrency = Currency(code: "XDR", symbol: "")
//        currencySubject.onNext(newCurrency)
//
//        verify(mockDelegate).didUpdate()
//    }
//
//}
