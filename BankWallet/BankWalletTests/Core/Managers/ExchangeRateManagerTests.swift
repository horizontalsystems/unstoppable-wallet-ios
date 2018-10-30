import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class ExchangeRateManagerTests: XCTestCase {
    private var mockStorage: MockIExchangeRateStorage!
    private var mockCurrencyManager: MockICurrencyManager!
    private var mockNetworkManager: MockIExchangeRateNetworkManager!

    private var manager: RateManager!

    let bitcoin = "BTC"
    let ether = "ETH"

    let bitcoinValue: Double = 6543.35
    let etherValue: Double = 235.12

    let baseCurrencyCode = "USD"
    var baseCurrency: Currency!

    override func setUp() {
        super.setUp()

        baseCurrency = Currency(code: baseCurrencyCode, localeId: "")

        mockStorage = MockIExchangeRateStorage()
        mockCurrencyManager = MockICurrencyManager()
        mockNetworkManager = MockIExchangeRateNetworkManager()

        stub(mockStorage) { mock in
            when(mock.rates.get).thenReturn([bitcoin: bitcoinValue, ether: etherValue])
            when(mock.save(value: any(), coin: any())).thenDoNothing()
            when(mock.clear()).thenDoNothing()
        }
        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrency.get).thenReturn(baseCurrency)
        }

        manager = RateManager(storage: mockStorage, currencyManager: mockCurrencyManager, networkManager: mockNetworkManager)
    }

    override func tearDown() {
        mockStorage = nil
        mockCurrencyManager = nil

        manager = nil

        super.tearDown()
    }

    func testExchangeRates() {
        let rates = manager.rates

        XCTAssertEqual(rates.count, 2)
        XCTAssertEqual(rates[bitcoin], CurrencyValue(currency: baseCurrency, value: bitcoinValue))
        XCTAssertEqual(rates[ether], CurrencyValue(currency: baseCurrency, value: etherValue))
    }

    func testUpdateRates() {
        let newBitcoinValue: Double = 7000
        let newEtherValue: Double = 500

        stub(mockNetworkManager) { mock in
            when(mock.getLatestRate(coin: equal(to: bitcoin), fiat: equal(to: baseCurrencyCode))).thenReturn(Observable.just(newBitcoinValue))
            when(mock.getLatestRate(coin: equal(to: ether), fiat: equal(to: baseCurrencyCode))).thenReturn(Observable.just(newEtherValue))
        }

        manager.updateRates()

        verify(mockStorage).save(value: equal(to: newBitcoinValue), coin: equal(to: bitcoin))
        verify(mockStorage).save(value: equal(to: newEtherValue), coin: equal(to: ether))
    }

}
