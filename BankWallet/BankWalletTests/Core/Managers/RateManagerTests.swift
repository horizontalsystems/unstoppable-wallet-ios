import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class RateManagerTests: XCTestCase {
    private var mockStorage: MockIRateStorage!
    private var mockSyncer: MockIRateSyncer!
    private var mockWalletManager: MockIWalletManager!
    private var mockCurrencyManager: MockICurrencyManager!
    private var mockReachabilityManager: MockIReachabilityManager!
    private var mockTimer: MockIPeriodicTimer!

    private var manager: RateManager!

    private let walletsSubject = PublishSubject<[Wallet]>()
    private let currencySubject = PublishSubject<Currency>()
    private let reachabilitySubject = PublishSubject<Bool>()

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private let bitcoinValue: Double = 6543.35
    private let etherValue: Double = 235.12

    private let baseCurrencyCode = "USD"
    private var baseCurrency: Currency!

    private var bitcoinRate: Rate!
    private var etherRate: Rate!

    private var bitcoinWallet: Wallet!
    private var etherWallet: Wallet!

    override func setUp() {
        super.setUp()

        baseCurrency = Currency(code: baseCurrencyCode, symbol: "")

        bitcoinRate = Rate(coin: bitcoin, currencyCode: baseCurrencyCode, value: bitcoinValue, timestamp: 0)
        etherRate = Rate(coin: ether, currencyCode: baseCurrencyCode, value: etherValue, timestamp: 0)

        bitcoinWallet = Wallet(coin: bitcoin, adapter: MockIAdapter())
        etherWallet = Wallet(coin: ether, adapter: MockIAdapter())

        mockStorage = MockIRateStorage()
        mockSyncer = MockIRateSyncer()
        mockWalletManager = MockIWalletManager()
        mockCurrencyManager = MockICurrencyManager()
        mockReachabilityManager = MockIReachabilityManager()
        mockTimer = MockIPeriodicTimer()

        stub(mockStorage) { mock in
            when(mock.rate(forCoin: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode))).thenReturn(bitcoinRate)
            when(mock.rate(forCoin: equal(to: ether), currencyCode: equal(to: baseCurrencyCode))).thenReturn(etherRate)
            when(mock.save(value: any(), coin: any(), currencyCode: any())).thenDoNothing()
        }
        stub(mockSyncer) { mock in
            when(mock.sync(coins: any(), currencyCode: any())).thenDoNothing()
        }
        stub(mockWalletManager) { mock in
            when(mock.walletsSubject.get).thenReturn(walletsSubject)
            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet])
        }
        stub(mockCurrencyManager) { mock in
            when(mock.subject.get).thenReturn(currencySubject)
            when(mock.baseCurrency.get).thenReturn(baseCurrency)
        }
        stub(mockReachabilityManager) { mock in
            when(mock.subject.get).thenReturn(reachabilitySubject)
        }
        stub(mockTimer) { mock in
            when(mock.delegate.set(any())).thenDoNothing()
        }

        manager = RateManager(storage: mockStorage, syncer: mockSyncer, walletManager: mockWalletManager, currencyManager: mockCurrencyManager, reachabilityManager: mockReachabilityManager, timer: mockTimer)
    }

    override func tearDown() {
        mockStorage = nil
        mockSyncer = nil
        mockWalletManager = nil
        mockCurrencyManager = nil
        mockReachabilityManager = nil
        mockTimer = nil

        manager = nil

        super.tearDown()
    }

    func testExchangeRates() {
        XCTAssertEqual(manager.rate(forCoin: bitcoin, currencyCode: baseCurrencyCode), bitcoinRate)
        XCTAssertEqual(manager.rate(forCoin: ether, currencyCode: baseCurrencyCode), etherRate)
    }

    func testSyncRates_OnWalletsChanged() {
        walletsSubject.onNext([])
        verify(mockSyncer).sync(coins: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testSyncRates_OnBaseCurrencyChanged() {
        currencySubject.onNext(Currency(code: "", symbol: ""))
        verify(mockSyncer).sync(coins: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testSyncRates_OnReachabilityChanged_Connected() {
        reachabilitySubject.onNext(true)
        verify(mockSyncer).sync(coins: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testSyncRates_OnReachabilityChanged_Disconnected() {
        reachabilitySubject.onNext(false)
        verify(mockSyncer, never()).sync(coins: any(), currencyCode: any())
    }

    func testSyncRates_OnTimerTick() {
        manager.onFire()
        verify(mockSyncer).sync(coins: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testDidSyncRate() {
        let value: Double = 3250

        let subjectExpectation = expectation(description: "Subject")
        _ = manager.subject.subscribe(onNext: {
            subjectExpectation.fulfill()
        })

        manager.didSync(coin: bitcoin, currencyCode: baseCurrencyCode, value: value)

        verify(mockStorage).save(value: equal(to: value), coin: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode))
        waitForExpectations(timeout: 2)
    }

}
