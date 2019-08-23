import XCTest
import Cuckoo
@testable import Bank_Dev_T

class BaseCurrencySettingsPresenterTests: XCTestCase {
    private var mockRouter: MockIBaseCurrencySettingsRouter!
    private var mockInteractor: MockIBaseCurrencySettingsInteractor!
    private var mockView: MockIBaseCurrencySettingsView!

    private var presenter: BaseCurrencySettingsPresenter!

    private let dollarCode = "USD"
    private let rubleCode = "RUB"

    private let dollarSymbol = "$"
    private let rubleSymbol = "P"

    private var dollarCurrency: Currency!
    private var rubleCurrency: Currency!
    private var currencies: [Currency]!

    private var expectedItems: [CurrencyItem]!

    override func setUp() {
        super.setUp()

        dollarCurrency = Currency.mock(code: dollarCode, symbol: dollarSymbol)
        rubleCurrency = Currency.mock(code: rubleCode, symbol: rubleSymbol)
        currencies = [dollarCurrency, rubleCurrency]

        expectedItems = [
            CurrencyItem(code: dollarCode, symbol: dollarSymbol, selected: true),
            CurrencyItem(code: rubleCode, symbol: rubleSymbol, selected: false)
        ]

        mockRouter = MockIBaseCurrencySettingsRouter()
        mockInteractor = MockIBaseCurrencySettingsInteractor()
        mockView = MockIBaseCurrencySettingsView()

        stub(mockView) { mock in
            when(mock.show(items: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.dismiss()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.currencies.get).thenReturn(currencies)
            when(mock.baseCurrency.get).thenReturn(dollarCurrency)
            when(mock.setBaseCurrency(code: any())).thenDoNothing()
        }

        presenter = BaseCurrencySettingsPresenter(router: mockRouter, interactor: mockInteractor)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

        presenter = nil

        super.tearDown()
    }

    func testShowItemsOnLoad() {
        presenter.viewDidLoad()
        verify(mockView).show(items: equal(to: expectedItems))
    }

    func testSelectItem() {
        presenter.didSelect(item: CurrencyItem(code: rubleCode, symbol: rubleSymbol, selected: false))
        verify(mockInteractor).setBaseCurrency(code: equal(to: rubleCode))
        verify(mockRouter).dismiss()
    }

    func testSelectItem_AlreadySelected() {
        presenter.didSelect(item: CurrencyItem(code: rubleCode, symbol: rubleSymbol, selected: true))
        verify(mockInteractor, never()).setBaseCurrency(code: any())
        verify(mockRouter).dismiss()
    }

    func testReloadItemsOnSetBaseCurrency() {
        presenter.didSetBaseCurrency()
        verify(mockView).show(items: equal(to: expectedItems))
    }

}
