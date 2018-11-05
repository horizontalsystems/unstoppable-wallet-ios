import XCTest
import Cuckoo
@testable import Bank_Dev_T

class BaseCurrencySettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockIBaseCurrencySettingsInteractorDelegate!
    private var mockCurrencyManager: MockICurrencyManager!

    private var interactor: BaseCurrencySettingsInteractor!

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

        mockDelegate = MockIBaseCurrencySettingsInteractorDelegate()
        mockCurrencyManager = MockICurrencyManager()

        stub(mockDelegate) { mock in
            when(mock.didSetBaseCurrency()).thenDoNothing()
        }
        stub(mockCurrencyManager) { mock in
            when(mock.currencies.get).thenReturn(currencies)
            when(mock.baseCurrency.get).thenReturn(dollarCurrency)
            when(mock.setBaseCurrency(code: any())).thenDoNothing()
        }

        interactor = BaseCurrencySettingsInteractor(currencyManager: mockCurrencyManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockCurrencyManager = nil

        interactor = nil

        super.tearDown()
    }

    func testGetCurrencies() {
        XCTAssertEqual(interactor.currencies, currencies)
    }

    func testGetBaseCurrency() {
        XCTAssertEqual(interactor.baseCurrency, dollarCurrency)
    }

    func testSetBaseCurrency() {
        interactor.setBaseCurrency(code: rubleCode)

        verify(mockCurrencyManager).setBaseCurrency(code: equal(to: rubleCode))
        verify(mockDelegate).didSetBaseCurrency()
    }

}
