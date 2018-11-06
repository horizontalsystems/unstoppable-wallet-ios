import XCTest
import Cuckoo
@testable import Bank_Dev_T

class CurrencyManagerTests: XCTestCase {
    private var mockLocalStorage: MockILocalStorage!
    private var mockAppConfigProvider: MockIAppConfigProvider!

    private var manager: ICurrencyManager!

    private let storedCurrencyCode = "RUB"

    private let dollarCode = "USD"
    private let rubleCode = "RUB"

    private let dollarSymbol = "$"
    private let rubleSymbol = "P"

    private var dollarCurrency: Currency!
    private var rubleCurrency: Currency!
    private var currencies: [Currency]!

    override func setUp() {
        super.setUp()

        dollarCurrency = Currency(code: dollarCode, symbol: dollarSymbol)
        rubleCurrency = Currency(code: rubleCode, symbol: rubleSymbol)
        currencies = [dollarCurrency, rubleCurrency]

        mockLocalStorage = MockILocalStorage()
        mockAppConfigProvider = MockIAppConfigProvider()

        stub(mockLocalStorage) { mock in
            when(mock.baseCurrencyCode.get).thenReturn(storedCurrencyCode)
            when(mock.baseCurrencyCode.set(any())).thenDoNothing()
        }
        stub(mockAppConfigProvider) { mock in
            when(mock.currencies.get).thenReturn(currencies)
        }

        manager = CurrencyManager(localStorage: mockLocalStorage, appConfigProvider: mockAppConfigProvider)
    }

    override func tearDown() {
        mockLocalStorage = nil

        manager = nil

        super.tearDown()
    }

    func testGetCurrencies() {
        XCTAssertEqual(manager.currencies, currencies)
    }

    func testBaseCurrency_Default() {
        stub(mockLocalStorage) { mock in
            when(mock.baseCurrencyCode.get).thenReturn(nil)
        }

        XCTAssertEqual(manager.baseCurrency, dollarCurrency)
    }

    func testBaseCurrency_FromLocalStorage() {
        XCTAssertEqual(manager.baseCurrency, rubleCurrency)
    }

    func testSetBaseCurrency() {
        let e = expectation(description: "Subject On Next")

        _ = manager.subject.subscribe(onNext: { currency in
            XCTAssertEqual(currency, self.rubleCurrency)
            e.fulfill()
        })

        manager.setBaseCurrency(code: rubleCode)

        verify(mockLocalStorage).baseCurrencyCode.set(equal(to: rubleCode))
        waitForExpectations(timeout: 2)
    }

}
