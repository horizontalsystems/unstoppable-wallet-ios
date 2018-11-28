import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class BalancePresenterTests: XCTestCase {
    private var mockRouter: MockIBalanceRouter!
    private var mockInteractor: MockIBalanceInteractor!
    private var mockView: MockIBalanceView!

    private var presenter: BalancePresenter!

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private var bitcoinValue: CoinValue!
    private var etherValue: CoinValue!

    private let currency = Currency(code: "USD", symbol: "$")

    private var bitcoinRate: Rate!
    private var etherRate: Rate!

    private var bitcoinAdapterState: AdapterState!
    private var etherAdapterState: AdapterState!

    private var expectedBitcoinItem: BalanceViewItem!
    private var expectedEtherItem: BalanceViewItem!

    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEtherAdapter: MockIAdapter!

    private var bitcoinWallet: Wallet!
    private var etherWallet: Wallet!

    override func setUp() {
        super.setUp()

        bitcoinValue = CoinValue(coin: bitcoin, value: 2)
        etherValue = CoinValue(coin: ether, value: 3)

        bitcoinRate = Rate()
        bitcoinRate.coin = bitcoin
        bitcoinRate.currencyCode = currency.code
        bitcoinRate.value = 5000
        bitcoinRate.timestamp = 50000
        etherRate = Rate()
        etherRate.coin = ether
        etherRate.currencyCode = currency.code
        etherRate.value = 300
        etherRate.timestamp = Date().timeIntervalSince1970

        bitcoinAdapterState = AdapterState.synced
        etherAdapterState = AdapterState.synced

        expectedBitcoinItem = BalanceViewItem(
                coinValue: bitcoinValue,
                exchangeValue: CurrencyValue(currency: currency, value: bitcoinRate.value),
                currencyValue: CurrencyValue(currency: currency, value: bitcoinRate.value * bitcoinValue.value),
                state: bitcoinAdapterState,
                rateExpired: true
        )
        expectedEtherItem = BalanceViewItem(
                coinValue: etherValue,
                exchangeValue: CurrencyValue(currency: currency, value: etherRate.value),
                currencyValue: CurrencyValue(currency: currency, value: etherRate.value * etherValue.value),
                state: etherAdapterState,
                rateExpired: false
        )
        mockBitcoinAdapter = MockIAdapter()
        mockEtherAdapter = MockIAdapter()

        bitcoinWallet = Wallet(coin: bitcoin, adapter: mockBitcoinAdapter)
        etherWallet = Wallet(coin: ether, adapter: mockEtherAdapter)

        mockRouter = MockIBalanceRouter()
        mockInteractor = MockIBalanceInteractor()
        mockView = MockIBalanceView()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.show(totalBalance: any(), upToDate: any())).thenDoNothing()
            when(mock.show(items: any())).thenDoNothing()
            when(mock.didRefresh()).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.openReceive(for: any())).thenDoNothing()
            when(mock.openSend(for: any())).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.baseCurrency.get).thenReturn(currency)
            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet])
            when(mock.rate(forCoin: equal(to: bitcoin))).thenReturn(bitcoinRate)
            when(mock.rate(forCoin: equal(to: ether))).thenReturn(etherRate)

            when(mock.refresh()).thenDoNothing()
        }

        stub(mockBitcoinAdapter) { mock in
            when(mock.balance.get).thenReturn(bitcoinValue.value)
            when(mock.state.get).thenReturn(bitcoinAdapterState)
        }
        stub(mockEtherAdapter) { mock in
            when(mock.balance.get).thenReturn(etherValue.value)
            when(mock.state.get).thenReturn(etherAdapterState)
        }
        presenter = BalancePresenter(interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

        presenter = nil

        super.tearDown()
    }

    func testShowTitle() {
        presenter.viewDidLoad()
        verify(mockView).set(title: "balance.title")
    }

    func testTotalBalance_Initial() {
        var totalValue: Double = bitcoinValue.value * bitcoinRate.value
        totalValue += etherValue.value * etherRate.value

        presenter.viewDidLoad()

        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: currency, value: totalValue)), upToDate: equal(to: false))
    }

    func testTotalBalance_NewCoinValue() {
        let newBitcoinValue = 3.0
        var newTotalValue: Double = newBitcoinValue * bitcoinRate.value
        newTotalValue += etherValue.value * etherRate.value


        stub(mockBitcoinAdapter) { mock in
            when(mock.balance.get).thenReturn(newBitcoinValue)
        }

        presenter.didUpdate()

        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: currency, value: newTotalValue)), upToDate: equal(to: false))
    }

    func testTotalBalance_DidUpdateRates() {
        let newBitcoinRate = Rate()
        newBitcoinRate.coin = bitcoin
        newBitcoinRate.currencyCode = currency.code
        newBitcoinRate.value = 1000
        newBitcoinRate.timestamp = Date().timeIntervalSince1970
        var newTotalValue = bitcoinValue.value * newBitcoinRate.value
        newTotalValue += etherValue.value * etherRate.value

        stub(mockInteractor) { mock in
            when(mock.rate(forCoin: equal(to: bitcoin))).thenReturn(newBitcoinRate)
        }

        presenter.didUpdate()

        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: currency, value: newTotalValue)), upToDate: equal(to: true))
    }

    func testWalletViewItems_Initial() {
        presenter.viewDidLoad()
        verifyMockViewShows(items: [expectedBitcoinItem, expectedEtherItem])
    }

    func testWalletViewItems_DidUpdateCoinValue() {
        let newBitcoinValue = CoinValue(coin: bitcoin, value: 3)
        let newExpectedBitcoinItem = BalanceViewItem(
                coinValue: newBitcoinValue,
                exchangeValue: CurrencyValue(currency: currency, value: bitcoinRate.value),
                currencyValue: CurrencyValue(currency: currency, value: bitcoinRate.value * newBitcoinValue.value),
                state: bitcoinAdapterState,
                rateExpired: true
        )

        stub(mockBitcoinAdapter) { mock in
            when(mock.balance.get).thenReturn(newBitcoinValue.value)
        }
        presenter.didUpdate()

        verifyMockViewShows(items: [newExpectedBitcoinItem, expectedEtherItem])
    }

    func testWalletViewItems_DidUpdateRates() {
        let newEtherRate = Rate()
        etherRate.coin = ether
        etherRate.currencyCode = currency.code
        etherRate.value = 300
        etherRate.timestamp = 860000
        let newExpectedEtherItem = BalanceViewItem(
                coinValue: etherValue,
                exchangeValue: CurrencyValue(currency: currency, value: newEtherRate.value),
                currencyValue: CurrencyValue(currency: currency, value: newEtherRate.value * etherValue.value),
                state: etherAdapterState,
                rateExpired: true
        )

        stub(mockInteractor) { mock in
            when(mock.rate(forCoin: equal(to: ether))).thenReturn(newEtherRate)
        }
        presenter.didUpdate()

        verifyMockViewShows(items: [expectedBitcoinItem, newExpectedEtherItem])
    }

    func testWalletViewItems_DidUpdateWallets_Order() {
        stub(mockInteractor) { mock in
            when(mock.wallets.get).thenReturn([etherWallet, bitcoinWallet])
        }

        presenter.didUpdate()

        verifyMockViewShows(items: [expectedEtherItem, expectedBitcoinItem])
    }

    func testWalletViewItems_DidUpdateWallets_Remove() {
        stub(mockInteractor) { mock in
            when(mock.wallets.get).thenReturn([bitcoinWallet])
        }

        presenter.didUpdate()

        verifyMockViewShows(items: [expectedBitcoinItem])
    }

    func testWalletViewItems_DidUpdateWallets_Add() {
        let thor = "THOR"
        let thorValue = CoinValue(coin: thor, value: 35)
        let thorRate = Rate()
        thorRate.coin = thor
        thorRate.currencyCode = currency.code
        thorRate.value = 666
        thorRate.timestamp = 777777
        let thorAdapterState = AdapterState.synced
        let thorAdapter = MockIAdapter()
        let thorWallet = Wallet(coin: thor, adapter: thorAdapter)

        let expectedThorItem = BalanceViewItem(
                coinValue: thorValue,
                exchangeValue: CurrencyValue(currency: currency, value: thorRate.value),
                currencyValue: CurrencyValue(currency: currency, value: thorRate.value * thorValue.value),
                state: thorAdapterState,
                rateExpired: true
        )

        stub(thorAdapter) { mock in
            when(mock.balance.get).thenReturn(thorValue.value)
            when(mock.state.get).thenReturn(thorAdapterState)
        }
        stub(mockInteractor) { mock in
            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet, thorWallet])
            when(mock.rate(forCoin: equal(to: thor))).thenReturn(thorRate)
        }

        presenter.didUpdate()

        verifyMockViewShows(items: [expectedBitcoinItem, expectedEtherItem, expectedThorItem])
    }

    func testRefreshFromView() {
        presenter.refresh()
        verify(mockInteractor).refresh()
    }

    func testOpenReceive() {
        presenter.onReceive(for: bitcoin)
        verify(mockRouter).openReceive(for: bitcoin)
    }

    func testOpenSend() {
        presenter.onPay(for: bitcoin)
        verify(mockRouter).openSend(for: bitcoin)
    }

    func testDidRefresh() {
        presenter.didRefresh()
        verify(mockView).didRefresh()
    }

    private func verifyMockViewShows(items: [BalanceViewItem]) {
        let argumentCaptor = ArgumentCaptor<[BalanceViewItem]>()
        verify(mockView).show(items: argumentCaptor.capture())

        if let capturedItems = argumentCaptor.value {
            for (index, item1) in capturedItems.enumerated() {
                let item2 = items[index]

                XCTAssertEqual(item1.coinValue, item2.coinValue)
                XCTAssertEqual(item1.exchangeValue, item2.exchangeValue)
                XCTAssertEqual(item1.currencyValue, item2.currencyValue)
                if case .synced = item1.state, case .synced = item2.state {
                    XCTAssertTrue(true)
                } else if case let .syncing(progressSubject1) = item1.state, case let .syncing(progressSubject2) = item2.state {
                    XCTAssertTrue(progressSubject1 === progressSubject2)
                } else {
                    XCTAssertTrue(false)
                }
                XCTAssertEqual(item1.rateExpired, item2.rateExpired)
            }
        }
    }

}
