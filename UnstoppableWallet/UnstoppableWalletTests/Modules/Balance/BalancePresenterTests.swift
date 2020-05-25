//import XCTest
//import RxSwift
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class BalancePresenterTests: XCTestCase {
//    private var mockRouter: MockIBalanceRouter!
//    private var mockInteractor: MockIBalanceInteractor!
//    private var mockDataSource: MockIBalanceItemDataSource!
//    private var mockFactory: MockIBalanceViewItemFactory!
//    private var mockView: MockIBalanceView!
//    private var mockDiffer: MockIDiffer!
//
//    private var presenter: BalancePresenter!
//
//    private let bitcoin = Coin(title: "Bitcoin", code: "BTC", decimal: 8, type: .bitcoin)
//    private let ether = Coin(title: "Ethereum", code: "ETH", decimal: 18, type: .ethereum)
//
//    private var bitcoinValue: CoinValue!
//    private var etherValue: CoinValue!
//
//    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)
//
//    private var bitcoinRate: Rate!
//    private var etherRate: Rate!
//
//    private var bitcoinAdapterState: AdapterState!
//    private var etherAdapterState: AdapterState!
//
//    private var expectedBitcoinItem: BalanceItem!
//    private var expectedEtherItem: BalanceItem!
//
//    private var expectedBitcoinViewItem: BalanceViewItem!
//    private var expectedEtherViewItem: BalanceViewItem!
//    private var expectedHeaderViewItem: BalanceHeaderViewItem!
//
//    private var mockBitcoinAdapter: MockIAdapter!
//    private var mockEtherAdapter: MockIAdapter!
//
//    private let sortingOnThreshold = 5
////    private var bitcoinWallet: Wallet!
////    private var etherWallet: Wallet!
//
//    override func setUp() {
//        super.setUp()
//
//        bitcoinValue = CoinValue(coin: bitcoin, value: 2)
//        etherValue = CoinValue(coin: ether, value: 3)
//
//        bitcoinRate = Rate(coinCode: bitcoin.code, currencyCode: currency.code, value: 5000, date: Date(), isLatest: true)
//        etherRate = Rate(coinCode: ether.code, currencyCode: currency.code, value: 300, date: Date(), isLatest: true)
//
//        bitcoinAdapterState = AdapterState.synced
//        etherAdapterState = AdapterState.synced
//
//        expectedBitcoinItem = BalanceItem(coin: bitcoin)
//        expectedEtherItem = BalanceItem(coin: ether)
//        expectedBitcoinViewItem = BalanceViewItem(
//                coin: bitcoin,
//                coinValue: CoinValue(coinCode: bitcoin.code, value: 10),
//                exchangeValue: CurrencyValue(currency: currency, value: 3),
//                currencyValue: CurrencyValue(currency: currency, value: 30),
//                state: .synced,
//                rateExpired: false)
//        expectedHeaderViewItem = BalanceHeaderViewItem(currencyValue: CurrencyValue(currency: currency, value: 130), upToDate: true)
////        expectedEtherItem = BalanceViewItem(
////                coinValue: etherValue,
////                exchangeValue: CurrencyValue(currency: currency, value: etherRate.value),
////                currencyValue: CurrencyValue(currency: currency, value: etherRate.value * etherValue.value),
////                state: etherAdapterState,
////                rateExpired: false,
////                refreshVisible: true
////        )
//        mockBitcoinAdapter = MockIAdapter()
//        mockEtherAdapter = MockIAdapter()
//
////        bitcoinWallet = Wallet(title: "some", coinCode: bitcoin, adapter: mockBitcoinAdapter)
////        etherWallet = Wallet(title: "some", coinCode: ether, adapter: mockEtherAdapter)
//
//        mockRouter = MockIBalanceRouter()
//        mockInteractor = MockIBalanceInteractor()
//        mockDataSource = MockIBalanceItemDataSource()
//        mockFactory = MockIBalanceViewItemFactory()
//        mockView = MockIBalanceView()
//        mockDiffer = MockIDiffer()
//
//        stub(mockView) { mock in
////            when(mock.set(title: any())).thenDoNothing()
////            when(mock.show(totalBalance: any(), upToDate: any())).thenDoNothing()
////            when(mock.show(items: any())).thenDoNothing()
//        }
//        stub(mockRouter) { mock in
//            when(mock.openReceive(for: any())).thenDoNothing()
//            when(mock.openSend(for: any())).thenDoNothing()
//            when(mock.openManageWallets()).thenDoNothing()
//        }
//        stub(mockInteractor) { mock in
////            when(mock.baseCurrency.get).thenReturn(currency)
////            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet])
////            when(mock.rate(forCoin: equal(to: bitcoin))).thenReturn(bitcoinRate)
////            when(mock.rate(forCoin: equal(to: ether))).thenReturn(etherRate)
//
////            when(mock.refresh(coinCode: any())).thenDoNothing()
//        }
//
//        stub(mockBitcoinAdapter) { mock in
//            when(mock.balance.get).thenReturn(bitcoinValue.value)
//            when(mock.state.get).thenReturn(bitcoinAdapterState)
//        }
//        stub(mockEtherAdapter) { mock in
//            when(mock.balance.get).thenReturn(etherValue.value)
//            when(mock.state.get).thenReturn(etherAdapterState)
//        }
//
//
//        presenter = BalancePresenter(interactor: mockInteractor, router: mockRouter, dataSource: mockDataSource, factory: mockFactory, differ: mockDiffer, sortingOnThreshold: sortingOnThreshold)
//        presenter.view = mockView
//    }
//
//    override func tearDown() {
//        mockRouter = nil
//        mockInteractor = nil
//        mockDataSource = nil
//        mockFactory = nil
//        mockView = nil
//        mockDiffer = nil
//
//        presenter = nil
//
//        super.tearDown()
//    }
//
//    func testDidLoad() {
//        stub(mockInteractor) { mock in
//            when(mock.initAdapters()).thenDoNothing()
//            when(mock.sortType.get).thenReturn(BalanceSortType.name)
//        }
//        stub(mockView) { mock in
//            when(mock.setSort(isOn: equal(to: false))).thenDoNothing()
//        }
//        stub(mockDataSource) { mock in
//            when(mock.sortType.set(any())).thenDoNothing()
//        }
//
//        presenter.viewDidLoad()
//
//        verify(mockView).setSort(isOn: equal(to: false))
//        verify(mockDataSource).sortType.set(equal(to: BalanceSortType.name))
//        verify(mockInteractor).initAdapters()
//    }
//
//    func testItemsCount() {
//        stub(mockDataSource) { mock in
//            when(mock.items.get).thenReturn([expectedBitcoinItem, expectedEtherItem])
//        }
//
//        XCTAssertEqual(2, presenter.itemsCount)
//    }
//
//    func testViewItem() {
//        stub(mockDataSource) { mock in
//            when(mock.item(at: equal(to: 0))).thenReturn(expectedBitcoinItem)
//            when(mock.currency.get).thenReturn(currency)
//        }
//        stub(mockFactory) { mock in
//            when(mock.viewItem(from: equal(to: expectedBitcoinItem), currency: equal(to: currency))).thenReturn(expectedBitcoinViewItem)
//        }
//
//        XCTAssertEqual(expectedBitcoinViewItem, presenter.viewItem(at: 0))
//    }
//
//    func testGetHeaderViewItem() {
//        stub(mockDataSource) { mock in
//            when(mock.items.get).thenReturn([expectedBitcoinItem])
//            when(mock.currency.get).thenReturn(currency)
//        }
//        stub(mockFactory) { mock in
//            when(mock.headerViewItem(from: equal(to: [expectedBitcoinItem]), currency: equal(to: currency))).thenReturn(expectedHeaderViewItem)
//        }
//
//        XCTAssertEqual(expectedHeaderViewItem, presenter.headerViewItem())
//    }
//
//    func testDidUpdateAdapters() {
//        let adapters = [mockBitcoinAdapter!]
//        let expectedItem = BalanceItem(coin: bitcoin)
//
//        stub(mockBitcoinAdapter) { mock in
//            when(mock.wallet.get).thenReturn(Wallet.mock(coin: bitcoin))
//        }
//        stub(mockDataSource) { mock in
//            when(mock.currency.get).thenReturn(currency)
//            when(mock.coinCodes.get).thenReturn([bitcoin.code])
//            when(mock.items.get).thenReturn([expectedItem])
//            when(mock.set(items: any())).thenDoNothing()
//        }
//        stub(mockInteractor) { mock in
//            when(mock.fetchRates(currencyCode: any(), coinCodes: any())).thenDoNothing()
//        }
//        stub(mockView) { mock in
//            when(mock.setSort(isOn: any())).thenDoNothing()
//            when(mock.reload()).thenDoNothing()
//        }
//
//
//        presenter.didUpdate(wallets: adapters)
//
//        verify(mockDataSource).set(items: equal(to: [expectedItem]))
//    }
//
//
//
//
//
//
//
//
//
//
//
//    /////////////////////////////////////////////////////////====================////////////////////////////////////////////////
////    func testTotalBalance_Initial() {
//////        var totalValue: Double = bitcoinValue.value * bitcoinRate.value
//////        totalValue += etherValue.value * etherRate.value
////
//////        presenter.viewDidLoad()
////
//////        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: currency, value: totalValue)), upToDate: equal(to: false))
////    }
////
////    func testTotalBalance_NewCoinValue() {
////        let newBitcoinValue = 3.0
//////        var newTotalValue: Double = newBitcoinValue * bitcoinRate.value
//////        newTotalValue += etherValue.value * etherRate.value
////
////
////        stub(mockBitcoinAdapter) { mock in
//////            when(mock.balance.get).thenReturn(newBitcoinValue)
////        }
////
//////        presenter.didUpdate()
////
//////        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: currency, value: newTotalValue)), upToDate: equal(to: false))
////    }
////
////    func testTotalBalance_DidUpdateRates() {
////        let newBitcoinRate = Rate(coinCode: bitcoin.code, currencyCode: currency.code, value: 1000, date: Date(), isLatest: true)
////        var newTotalValue = bitcoinValue.value * newBitcoinRate.value
////        newTotalValue += etherValue.value * etherRate.value
////
////        stub(mockInteractor) { mock in
//////            when(mock.rate(forCoin: equal(to: bitcoin))).thenReturn(newBitcoinRate)
////        }
////
//////        presenter.didUpdate()
////
//////        verify(mockView).show(totalBalance: equal(to: CurrencyValue(currency: currency, value: newTotalValue)), upToDate: equal(to: true))
////    }
////
////    func testWalletViewItems_Initial() {
////        presenter.viewDidLoad()
////        verifyMockViewShows(items: [expectedBitcoinViewItem, expectedEtherViewItem])
////    }
////
////    func testWalletViewItems_DidUpdateCoinValue() {
////        let newBitcoinValue = CoinValue(coinCode: bitcoin.code, value: 3)
//////        let newExpectedBitcoinItem = BalanceViewItem(
//////                coinValue: newBitcoinValue,
//////                exchangeValue: CurrencyValue(currency: currency, value: bitcoinRate.value),
//////                currencyValue: CurrencyValue(currency: currency, value: bitcoinRate.value * newBitcoinValue.value),
//////                state: bitcoinAdapterState,
//////                rateExpired: true,
//////                refreshVisible: false
//////        )
////
////        stub(mockBitcoinAdapter) { mock in
////            when(mock.balance.get).thenReturn(newBitcoinValue.value)
////        }
//////        presenter.didUpdate()
////
//////        verifyMockViewShows(items: [newExpectedBitcoinItem, expectedEtherItem])
////    }
////
////    func testWalletViewItems_DidUpdateRates() {
////        let newEtherRate = Rate(coinCode: ether.code, currencyCode: currency.code, value: 300, date: Date(), isLatest: true)
//////        let newExpectedEtherItem = BalanceViewItem(
//////                coinValue: etherValue,
//////                exchangeValue: CurrencyValue(currency: currency, value: newEtherRate.value),
//////                currencyValue: CurrencyValue(currency: currency, value: newEtherRate.value * etherValue.value),
//////                state: etherAdapterState,
//////                rateExpired: true,
//////                refreshVisible: true
//////        )
////
////        stub(mockInteractor) { mock in
//////            when(mock.rate(forCoin: equal(to: ether))).thenReturn(newEtherRate)
////        }
//////        presenter.didUpdate()
////
//////        verifyMockViewShows(items: [expectedBitcoinItem, newExpectedEtherItem])
////    }
////
////    func testWalletViewItems_DidUpdateRefreshVisible() {
//////        let newState = AdapterState.syncing(progressSubject: nil)
////
//////        let newExpectedEtherItem = BalanceViewItem(
//////                coinValue: etherValue,
//////                exchangeValue: CurrencyValue(currency: currency, value: etherRate.value),
//////                currencyValue: CurrencyValue(currency: currency, value: etherRate.value * etherValue.value),
//////                state: newState,
//////                rateExpired: false,
//////                refreshVisible: false
//////        )
////
////        stub(mockEtherAdapter) { mock in
//////            when(mock.state.get).thenReturn(newState)
////        }
////
//////        presenter.didUpdate()
////
//////        verifyMockViewShows(items: [expectedBitcoinItem, newExpectedEtherItem])
////    }
////
////    func testWalletViewItems_DidUpdateWallets_Order() {
////        stub(mockInteractor) { mock in
//////            when(mock.wallets.get).thenReturn([etherWallet, bitcoinWallet])
////        }
////
//////        presenter.didUpdate()
////
//////        verifyMockViewShows(items: [expectedEtherItem, expectedBitcoinItem])
////    }
////
////    func testWalletViewItems_DidUpdateWallets_Remove() {
////        stub(mockInteractor) { mock in
//////            when(mock.wallets.get).thenReturn([bitcoinWallet])
////        }
////
//////        presenter.didUpdate()
////
//////        verifyMockViewShows(items: [expectedBitcoinItem])
////    }
////
////    func testWalletViewItems_DidUpdateWallets_Add() {
////        let thor = "THOR"
////        let thorValue = CoinValue(coinCode: thor, value: 35)
////        let thorRate = Rate(coinCode: thor, currencyCode: currency.code, value: 666, date: Date(), isLatest: true)
////        let thorAdapterState = AdapterState.synced
////        let thorAdapter = MockIAdapter()
//////        let thorWallet = Wallet(title: "some", coinCode: thor, adapter: thorAdapter)
////
//////        let expectedThorItem = BalanceViewItem(
//////                coinValue: thorValue,
//////                exchangeValue: CurrencyValue(currency: currency, value: thorRate.value),
//////                currencyValue: CurrencyValue(currency: currency, value: thorRate.value * thorValue.value),
//////                state: thorAdapterState,
//////                rateExpired: true,
//////                refreshVisible: false
//////        )
////
////        stub(thorAdapter) { mock in
////            when(mock.balance.get).thenReturn(thorValue.value)
////            when(mock.state.get).thenReturn(thorAdapterState)
////            when(mock.refreshable.get).thenReturn(false)
////        }
////        stub(mockInteractor) { mock in
//////            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet, thorWallet])
//////            when(mock.rate(forCoin: equal(to: thor))).thenReturn(thorRate)
//////            when(mock.refresh(coinCode: any())).thenDoNothing()
////        }
////
//////        presenter.didUpdate()
////
//////        verifyMockViewShows(items: [expectedBitcoinItem, expectedEtherItem, expectedThorItem])
////    }
////
////    func testRefreshFromView() {
//////        presenter.onRefresh(for: ether)
//////        verify(mockInteractor).refresh(coinCode: equal(to: ether))
////    }
////
////    func testOpenReceive() {
//////        presenter.onReceive(for: bitcoin)
//////        verify(mockRouter).openReceive(for: bitcoin)
////    }
////
////    func testOpenSend() {
//////        presenter.onPay(for: bitcoin)
//////        verify(mockRouter).openSend(for: bitcoin)
////    }
////
////    private func verifyMockViewShows(items: [BalanceViewItem]) {
////        let argumentCaptor = ArgumentCaptor<[BalanceViewItem]>()
//////        verify(mockView).show(items: argumentCaptor.capture())
////
////        if let capturedItems = argumentCaptor.value {
////            for (index, item1) in capturedItems.enumerated() {
////                let item2 = items[index]
////
////                XCTAssertEqual(item1.coinValue, item2.coinValue)
////                XCTAssertEqual(item1.exchangeValue, item2.exchangeValue)
////                XCTAssertEqual(item1.currencyValue, item2.currencyValue)
////                if case .synced = item1.state, case .synced = item2.state {
////                    XCTAssertTrue(true)
////                } else if case let .syncing(progressSubject1) = item1.state, case let .syncing(progressSubject2) = item2.state {
//////                    XCTAssertTrue(progressSubject1 === progressSubject2)
////                } else {
////                    XCTAssertTrue(false)
////                }
////                XCTAssertEqual(item1.rateExpired, item2.rateExpired)
////            }
////        }
////    }
////
////    func testOpenManageCoins() {
////        presenter.onOpenManageCoins()
////        verify(mockRouter).openManageCoins()
////    }
//
//}
