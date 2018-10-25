import XCTest
import RxSwift
import Cuckoo
@testable import BankWallet

class WalletPresenterTests: XCTestCase {
    private var mockRouter: MockIWalletRouter!
    private var mockInteractor: MockIWalletInteractor!
    private var mockView: MockIWalletView!

    private var presenter: WalletPresenter!

    private let bitcoin = "BTC"
    private let ether = "ETH"
    private let cash = "BCH"

    private var bitcoinValue: CoinValue!
    private var etherValue: CoinValue!
    private var cashValue: CoinValue!

    private let bitcoinRate = CurrencyValue(currency: DollarCurrency(), value: 5000)
    private let etherRate = CurrencyValue(currency: DollarCurrency(), value: 300)

    private let bitcoinSubject = BehaviorSubject<Double>(value: 1)
    private let cashSubject = BehaviorSubject<Double>(value: 0.5)

    private var expectedBitcoinItem: WalletViewItem!
    private var expectedEtherItem: WalletViewItem!
    private var expectedCashItem: WalletViewItem!

    override func setUp() {
        super.setUp()

        bitcoinValue = CoinValue(coin: bitcoin, value: 2)
        etherValue = CoinValue(coin: ether, value: 3)
        cashValue = CoinValue(coin: cash, value: 10)

        expectedBitcoinItem = WalletViewItem(
                coinValue: bitcoinValue,
                exchangeValue: bitcoinRate,
                currencyValue: CurrencyValue(currency: bitcoinRate.currency, value: bitcoinRate.value * bitcoinValue.value),
                progressSubject: bitcoinSubject
        )
        expectedEtherItem = WalletViewItem(
                coinValue: etherValue,
                exchangeValue: etherRate,
                currencyValue: CurrencyValue(currency: etherRate.currency, value: etherRate.value * etherValue.value),
                progressSubject: nil
        )
        expectedCashItem = WalletViewItem(
                coinValue: cashValue,
                exchangeValue: nil,
                currencyValue: nil,
                progressSubject: cashSubject
        )

        mockRouter = MockIWalletRouter()
        mockInteractor = MockIWalletInteractor()
        mockView = MockIWalletView()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.show(totalBalance: any())).thenDoNothing()
            when(mock.show(wallets: any())).thenDoNothing()
            when(mock.didRefresh()).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.openReceive(for: any())).thenDoNothing()
            when(mock.openSend(for: any())).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.coinValues.get).thenReturn([bitcoinValue, etherValue, cashValue])
            when(mock.rates.get).thenReturn([bitcoin: bitcoinRate, ether: etherRate])
            when(mock.progressSubjects.get).thenReturn([bitcoin: bitcoinSubject, cash: cashSubject])
            when(mock.refresh()).thenDoNothing()
        }

        presenter = WalletPresenter(interactor: mockInteractor, router: mockRouter)
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
        verify(mockView).set(title: "wallet.title")
    }

    func testTotalBalance_Initial() {
        let totalValue =
                bitcoinValue.value * bitcoinRate.value +
                etherValue.value * etherRate.value

        presenter.viewDidLoad()

        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: bitcoinRate.currency, value: totalValue)))
    }

    func testTotalBalance_DidUpdateCoinValue() {
        let newBitcoinValue = CoinValue(coin: bitcoin, value: 3)
        let newTotalValue =
                newBitcoinValue.value * bitcoinRate.value +
                etherValue.value * etherRate.value

        presenter.didUpdate(coinValue: newBitcoinValue)

        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: bitcoinRate.currency, value: newTotalValue)))
    }

    func testTotalBalance_DidUpdateRates() {
        let newBitcoinRate = CurrencyValue(currency: DollarCurrency(), value: 1000)
        let newTotalValue =
                bitcoinValue.value * newBitcoinRate.value +
                etherValue.value * etherRate.value

        presenter.didUpdate(rates: [
            bitcoin: newBitcoinRate,
            ether: etherRate
        ])

        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: newBitcoinRate.currency, value: newTotalValue)))
    }

    func testWalletViewItems_Initial() {
        presenter.viewDidLoad()
        verifyMockViewShows(items: [expectedBitcoinItem, expectedEtherItem, expectedCashItem])
    }

    func testWalletViewItems_DidUpdateCoinValue() {
        let newBitcoinValue = CoinValue(coin: bitcoin, value: 3)
        let newExpectedBitcoinItem = WalletViewItem(
                coinValue: newBitcoinValue,
                exchangeValue: bitcoinRate,
                currencyValue: CurrencyValue(currency: bitcoinRate.currency, value: bitcoinRate.value * newBitcoinValue.value),
                progressSubject: bitcoinSubject
        )

        presenter.didUpdate(coinValue: newBitcoinValue)

        verifyMockViewShows(items: [newExpectedBitcoinItem, expectedEtherItem, expectedCashItem])
    }

    func testWalletViewItems_DidUpdateRates() {
        let newEtherRate = CurrencyValue(currency: DollarCurrency(), value: 400)
        let newExpectedEtherItem = WalletViewItem(
                coinValue: etherValue,
                exchangeValue: newEtherRate,
                currencyValue: CurrencyValue(currency: bitcoinRate.currency, value: newEtherRate.value * etherValue.value),
                progressSubject: nil
        )

        presenter.didUpdate(rates: [
            bitcoin: bitcoinRate,
            ether: newEtherRate
        ])

        verifyMockViewShows(items: [expectedBitcoinItem, newExpectedEtherItem, expectedCashItem])
    }

    func testWalletViewItems_DidUpdateWallets_Order() {
        stub(mockInteractor) { mock in
            when(mock.coinValues.get).thenReturn([etherValue, bitcoinValue, cashValue])
        }

        presenter.didUpdateCoinValues()

        verifyMockViewShows(items: [expectedEtherItem, expectedBitcoinItem, expectedCashItem])
    }

    func testWalletViewItems_DidUpdateWallets_Remove() {
        stub(mockInteractor) { mock in
            when(mock.coinValues.get).thenReturn([bitcoinValue, cashValue])
        }

        presenter.didUpdateCoinValues()

        verifyMockViewShows(items: [expectedBitcoinItem, expectedCashItem])
    }

    func testWalletViewItems_DidUpdateWallets_Add() {
        let thor = "THOR"
        let thorValue = CoinValue(coin: thor, value: 35)
        let thorSubject = BehaviorSubject<Double>(value: 0.35)

        let expectedThorItem = WalletViewItem(
                coinValue: thorValue,
                exchangeValue: nil,
                currencyValue: nil,
                progressSubject: thorSubject
        )

        stub(mockInteractor) { mock in
            when(mock.coinValues.get).thenReturn([bitcoinValue, etherValue, thorValue, cashValue])
            when(mock.progressSubjects.get).thenReturn([bitcoin: bitcoinSubject, thor: thorSubject, cash: cashSubject])
        }

        presenter.didUpdateCoinValues()

        verifyMockViewShows(items: [expectedBitcoinItem, expectedEtherItem, expectedThorItem, expectedCashItem])
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

    private func verifyMockViewShows(items: [WalletViewItem]) {
        let argumentCaptor = ArgumentCaptor<[WalletViewItem]>()
        verify(mockView).show(wallets: argumentCaptor.capture())

        if let capturedItems = argumentCaptor.value {
            for (index, item1) in capturedItems.enumerated() {
                let item2 = items[index]

                XCTAssertEqual(item1.coinValue, item2.coinValue)
                XCTAssertEqual(item1.exchangeValue, item2.exchangeValue)
                XCTAssertEqual(item1.currencyValue, item2.currencyValue)
                XCTAssertTrue(item1.progressSubject === item2.progressSubject)
            }
        }
    }

}
