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

        bitcoinRate = Rate(coinCode: bitcoin, currencyCode: baseCurrencyCode, value: bitcoinValue, timestamp: 0)
        etherRate = Rate(coinCode: ether, currencyCode: baseCurrencyCode, value: etherValue, timestamp: 0)

        bitcoinWallet = Wallet(title: "some", coinCode: bitcoin, adapter: MockIAdapter())
        etherWallet = Wallet(title: "some", coinCode: ether, adapter: MockIAdapter())

        mockStorage = MockIRateStorage()
        mockSyncer = MockIRateSyncer()
        mockWalletManager = MockIWalletManager()
        mockCurrencyManager = MockICurrencyManager()
        mockReachabilityManager = MockIReachabilityManager()
        mockTimer = MockIPeriodicTimer()

        stub(mockStorage) { mock in
            when(mock.rate(forCoin: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode))).thenReturn(bitcoinRate)
            when(mock.rate(forCoin: equal(to: ether), currencyCode: equal(to: baseCurrencyCode))).thenReturn(etherRate)
            when(mock.save(latestRate: any(), coinCode: any(), currencyCode: any())).thenDoNothing()
        }
        stub(mockSyncer) { mock in
            when(mock.sync(coinCodes: any(), currencyCode: any())).thenDoNothing()
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
        verify(mockSyncer).sync(coinCodes: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testSyncRates_OnBaseCurrencyChanged() {
        currencySubject.onNext(Currency(code: "", symbol: ""))
        verify(mockSyncer).sync(coinCodes: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testSyncRates_OnReachabilityChanged_Connected() {
        reachabilitySubject.onNext(true)
        verify(mockSyncer).sync(coinCodes: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testSyncRates_OnReachabilityChanged_Disconnected() {
        reachabilitySubject.onNext(false)
        verify(mockSyncer, never()).sync(coinCodes: any(), currencyCode: any())
    }

    func testSyncRates_OnTimerTick() {
        manager.onFire()
        verify(mockSyncer).sync(coinCodes: equal(to: [bitcoin, ether]), currencyCode: equal(to: baseCurrencyCode))
    }

    func testDidSyncRate() {
        let latestRate = LatestRate(value: 3250, timestamp: Date().timeIntervalSince1970)

        manager.didSync(coinCode: bitcoin, currencyCode: baseCurrencyCode, latestRate: latestRate)

        verify(mockStorage).save(latestRate: equal(to: latestRate), coinCode: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode))
    }

}
