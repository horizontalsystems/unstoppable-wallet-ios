//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class ManageWalletsPresenterTests: XCTestCase {
//    private var bitcoin: Coin!
//    private var bitcoinCash: Coin!
//    private var ethereum: Coin!
//
//    private var mockRouter: MockIManageCoinsRouter!
//    private var mockInteractor: MockIManageCoinsInteractor!
//    private var mockView: MockIManageCoinsView!
//    private var mockState: MockIManageCoinsPresenterState!
//
//    private var presenter: ManageWalletsPresenter!
//
//    private var allCoins: [Coin]!
//    private var enabledCoins: [Coin]!
//    private var disabledCoins: [Coin]!
//
//    override func setUp() {
//        super.setUp()
//        bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
//        bitcoinCash = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
//        ethereum = Coin(title: "Ethereum", code: "ETH", type: .ethereum)
//        allCoins = [
//            bitcoin,
//            bitcoinCash,
//            ethereum
//        ]
//        enabledCoins = [
//            bitcoin,
//            ethereum
//        ]
//        disabledCoins = [
//            bitcoinCash,
//        ]
//
//
//        mockRouter = MockIManageCoinsRouter()
//        mockInteractor = MockIManageCoinsInteractor()
//        mockView = MockIManageCoinsView()
//        mockState = MockIManageCoinsPresenterState()
//
//        stub(mockView) { mock in
//            when(mock.updateUI()).thenDoNothing()
//            when(mock.show(error: any())).thenDoNothing()
//        }
//        stub(mockRouter) { mock in
//            when(mock.close()).thenDoNothing()
//        }
//        stub(mockInteractor) { mock in
//            when(mock.loadCoins()).thenDoNothing()
//            when(mock.save(enabledCoins: any())).thenDoNothing()
//        }
//        stub(mockState) { mock in
//            when(mock.allCoins.get).thenReturn(allCoins)
//            when(mock.allCoins.set(any())).thenDoNothing()
//            when(mock.enabledCoins.get).thenReturn(enabledCoins)
//            when(mock.enabledCoins.set(any())).thenDoNothing()
//            when(mock.disabledCoins.get).thenReturn(disabledCoins)
//            when(mock.enable(coin: any())).thenDoNothing()
//            when(mock.disable(coin: any())).thenDoNothing()
//            when(mock.move(coin: any(), to: any())).thenDoNothing()
//        }
//
//        presenter = ManageWalletsPresenter(interactor: mockInteractor, router: mockRouter, state: mockState)
//        presenter.view = mockView
//    }
//
//    override func tearDown() {
//        mockRouter = nil
//        mockInteractor = nil
//        mockView = nil
//        mockState = nil
//
//        presenter = nil
//
//        super.tearDown()
//    }
//
//    func testLoadCoins() {
//        presenter.viewDidLoad()
//        verify(mockInteractor).loadCoins()
//    }
//
//    func testDidLoadCoins() {
//        presenter.didLoad(allCoins: allCoins, enabledCoins: enabledCoins)
//        verify(mockState).allCoins.set(equal(to: allCoins))
//        verify(mockState).enabledCoins.set(equal(to: enabledCoins))
//    }
//
//    func testEnableCoin() {
//        let coinToEnable: Coin = bitcoinCash
//
//        presenter.enableCoin(atIndex: 0)
//        verify(mockState).enable(coin: equal(to: coinToEnable))
//        verify(mockView).updateUI()
//    }
//
//    func testDisableCoin() {
//        let coinToDisable: Coin = ethereum
//
//        presenter.disableWallet(atIndex: 1)
//        verify(mockState).disable(coin: equal(to: coinToDisable))
//        verify(mockView).updateUI()
//    }
//
//    func testMoveEnabledCoin() {
//        let coinToMove: Coin = ethereum
//        presenter.moveWallet(from: 1, to: 0)
//        verify(mockState).move(coin: equal(to: coinToMove), to: 0)
//        verify(mockView).updateUI()
//    }
//
//    func testSaveEnabledCoins() {
//        presenter.saveChanges()
//        verify(mockInteractor).save(enabledCoins: equal(to: enabledCoins))
//    }
//
//    func testDidSaveCoins() {
//        presenter.didSaveWallets()
//        verify(mockRouter).close()
//    }
//
//    func testDidFailToSaveCoins() {
//        presenter.didFailToSaveWallets()
//        verify(mockView).show(error: "manage_coins.fail_to_save")
//    }
//
//    func testEnabledItemForIndex() {
//        XCTAssertEqual(presenter.wallet(forIndex: 0), bitcoin)
//    }
//
//    func testDisabledItemForIndex() {
//        XCTAssertEqual(presenter.coin(forIndex: 0), bitcoinCash)
//    }
//
//    func testEnabledCoinsCount() {
//        XCTAssertEqual(presenter.walletsCount, enabledCoins.count)
//    }
//
//    func testDisabledCoinsCount() {
//        XCTAssertEqual(presenter.coinsCount, disabledCoins.count)
//    }
//
//    func testClose() {
//        presenter.onClose()
//        verify(mockRouter).close()
//    }
//
//}
