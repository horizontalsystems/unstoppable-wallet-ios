import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class RateManagerTests: XCTestCase {
    private var mockRateStorage: MockIRateStorage!
    private var mockTransactionStorage: MockITransactionRecordStorage!
    private var mockCurrencyManager: MockICurrencyManager!
    private var mockNetworkManager: MockIRateNetworkManager!
    private var mockWalletManager: MockIWalletManager!

    private var manager: RateManager!

    private let currencySubject = PublishSubject<Currency>()

    let bitcoin = "BTC"
    let ether = "ETH"

    let bitcoinValue: Double = 6543.35
    let etherValue: Double = 235.12

    let baseCurrencyCode = "USD"
    var baseCurrency: Currency!

    private var bitcoinRate: Rate!
    private var etherRate: Rate!

    private var bitcoinWallet: Wallet!
    private var etherWallet: Wallet!

    override func setUp() {
        super.setUp()
        baseCurrency = Currency(code: baseCurrencyCode, symbol: "")

        bitcoinRate = Rate()
        bitcoinRate.coin = bitcoin
        bitcoinRate.currencyCode = baseCurrencyCode
        bitcoinRate.value = bitcoinValue
        bitcoinRate.timestamp = 50000
        etherRate = Rate()
        etherRate.coin = bitcoin
        etherRate.currencyCode = baseCurrencyCode
        etherRate.value = bitcoinValue
        etherRate.timestamp = 50000

        let mockBitcoinAdapter = MockIAdapter()
        bitcoinWallet = Wallet(coin: bitcoin, adapter: mockBitcoinAdapter)
        let mockEtherAdapter = MockIAdapter()
        etherWallet = Wallet(coin: ether, adapter: mockEtherAdapter)

        mockRateStorage = MockIRateStorage()
        mockTransactionStorage = MockITransactionRecordStorage()
        mockCurrencyManager = MockICurrencyManager()
        mockNetworkManager = MockIRateNetworkManager()
        mockWalletManager = MockIWalletManager()

        stub(mockRateStorage) { mock in
            when(mock.rate(forCoin: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode))).thenReturn(bitcoinRate)
            when(mock.rate(forCoin: equal(to: ether), currencyCode: equal(to: baseCurrencyCode))).thenReturn(etherRate)
            when(mock.save(value: any(), coin: any(), currencyCode: any())).thenDoNothing()
            when(mock.clear()).thenDoNothing()
        }
        stub(mockCurrencyManager) { mock in
            when(mock.subject.get).thenReturn(currencySubject)
            when(mock.baseCurrency.get).thenReturn(baseCurrency)
        }
        stub(mockWalletManager) { mock in
            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet])
        }

        manager = RateManager(rateStorage: mockRateStorage, transactionRecordStorage: mockTransactionStorage, currencyManager: mockCurrencyManager, networkManager: mockNetworkManager, walletManager: mockWalletManager, scheduler: MainScheduler.instance)
    }

    override func tearDown() {
        mockNetworkManager = nil
        mockWalletManager = nil
        mockTransactionStorage = nil
        mockRateStorage = nil
        mockCurrencyManager = nil

        manager = nil

        super.tearDown()
    }

    func testExchangeRates() {
        let rate = manager.rate(forCoin: bitcoin, currencyCode: baseCurrencyCode)
        XCTAssertEqual(rate, bitcoinRate)
        XCTAssertEqual(manager.rate(forCoin: ether, currencyCode: baseCurrencyCode), etherRate)
    }

    func testUpdateRates() {
        let newBitcoinValue: Double = 7000
        let newEtherValue: Double = 500

        stub(mockNetworkManager) { mock in
            when(mock.getLatestRate(coin: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode))).thenReturn(Observable.just(newBitcoinValue))
            when(mock.getLatestRate(coin: equal(to: ether), currencyCode: equal(to: baseCurrencyCode))).thenReturn(Observable.just(newEtherValue))
        }

        manager.updateRates()


        waitForMainQueue()
        verify(mockRateStorage).save(value: equal(to: newBitcoinValue), coin: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode))
        waitForMainQueue()
        verify(mockRateStorage).save(value: equal(to: newEtherValue), coin: equal(to: ether), currencyCode: equal(to: baseCurrencyCode))
    }

    func testFillTransactionRates() {
        let rateValue = 2345.0
        let timestamp = 500000.0

        let transaction = TransactionRecord()
        transaction.transactionHash = "transaction_hash"
        transaction.coin = bitcoin
        transaction.timestamp = Int(timestamp)
        stub(mockTransactionStorage) { mock in
            when(mock.nonFilledRecords.get).thenReturn([transaction])
            when(mock.set(rate: any(), transactionHash: any())).thenDoNothing()
        }
        stub(mockNetworkManager) { mock in
            when(mock.getRate(coin: equal(to: bitcoin), currencyCode: equal(to: baseCurrencyCode), date: equal(to: Date(timeIntervalSince1970: timestamp)))).thenReturn(Observable.just(rateValue))
        }

        manager.fillTransactionRates()

        waitForMainQueue()
        verify(mockTransactionStorage).set(rate: equal(to: rateValue), transactionHash: equal(to: transaction.transactionHash))
    }

}
