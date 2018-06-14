import XCTest
import Cuckoo
@testable import Wallet

class WalletPresenterTests: XCTestCase {

    private var mockDelegate: MockWalletPresenterDelegate!
    private var mockRouter: MockWalletRouterProtocol!
    private var mockView: MockWalletViewProtocol!
    private var presenter: WalletPresenter!

    private var balances: [WalletBalance]!

    override func setUp() {
        super.setUp()

        mockDelegate = MockWalletPresenterDelegate()
        mockRouter = MockWalletRouterProtocol()
        mockView = MockWalletViewProtocol()
        presenter = WalletPresenter(delegate: mockDelegate, router: mockRouter)

        presenter.view = mockView

        balances = [
            WalletBalance(coinValue: CoinValue(coin: Bitcoin(), value: 0.01234567), conversionRate: 5000.25, conversionCurrency: DollarCurrency()),
            WalletBalance(coinValue: CoinValue(coin: Ethereum(), value: 0.02345678), conversionRate: 2000.5, conversionCurrency: DollarCurrency())
        ]

        stub(mockDelegate) { mock in
            when(mock.fetchWalletBalances()).thenDoNothing()
        }
        stub(mockView) { mock in
            when(mock.show(totalBalance: any())).thenDoNothing()
            when(mock.show(walletBalances: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockDelegate = nil
        mockRouter = nil
        mockView = nil
        presenter = nil

        balances = nil

        super.tearDown()
    }

    func testLoadsBalancesOnLoad() {
        presenter.viewDidLoad()

        verify(mockDelegate).fetchWalletBalances()
    }

    func testShowsTotalBalance() {
        let totalValue = balances.map { $0.coinValue.value * $0.conversionRate }.reduce(0, +)
        let expectedValue = CurrencyValue(currency: DollarCurrency(), value: totalValue)

        presenter.didFetch(walletBalances: balances)

        verify(mockView).show(totalBalance: equal(to: expectedValue))
    }

    func testShowsViewModels() {
        let viewModels = balances.map { balance in
            WalletBalanceViewModel(
                    coinValue: balance.coinValue,
                    convertedValue: CurrencyValue(currency: balance.conversionCurrency, value: balance.coinValue.value * balance.conversionRate),
                    rate: CurrencyValue(currency: balance.conversionCurrency, value: balance.conversionRate)
            )
        }

        presenter.didFetch(walletBalances: balances)

        let argumentCaptor = ArgumentCaptor<[WalletBalanceViewModel]>()
        verify(mockView).show(walletBalances: argumentCaptor.capture())

        XCTAssertEqual(viewModels.first, argumentCaptor.value?.first)
        XCTAssertEqual(viewModels.last, argumentCaptor.value?.last)
    }

}
